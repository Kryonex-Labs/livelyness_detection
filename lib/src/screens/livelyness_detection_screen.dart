import 'dart:async';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:livelyness_detection/index.dart';

/// Latest detected face plus the metadata needed to draw its vertices overlay.
typedef _FaceOverlay = (Face face, Size size, InputImageRotation rotation);

/// Full-screen liveness detection flow: a full-bleed camera preview, a frosted
/// oval face guide with an animated progress ring, and glassmorphic step cards.
///
/// Pushed internally by [LivelynessDetection.detect]; it pops a
/// [CapturedImage] (or `null` if the user cancels / times out).
class LivelynessDetectionScreen extends StatefulWidget {
  final DetectionConfig config;

  const LivelynessDetectionScreen({
    required this.config,
    super.key,
  });

  @override
  State<LivelynessDetectionScreen> createState() =>
      _LivelynessDetectionScreenState();
}

class _LivelynessDetectionScreenState extends State<LivelynessDetectionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  //* MARK: - State
  //? =========================================================
  late final List<LivelynessStepItem> _steps;
  late bool _isInfoStepCompleted;

  // Cameras discovered on this screen (private: not part of the public API).
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _cameraIndex = 0;

  // Per-screen detector; closed in dispose() to avoid a native leak.
  late final FaceDetector _faceDetector;

  bool _isBusy = false;
  bool _didCloseEyes = false;
  bool _isTakingPicture = false;
  bool _isCompleted = false;
  bool _disposed = false;

  // True while a step transition (ring animation + checkmark) is in flight.
  // Detection and reset both no-op during this window to avoid racing a stale
  // advance against a face-lost reset.
  bool _transitioning = false;

  int _currentIndex = 0;
  bool _showCheck = false;

  int _captureRetries = 0;
  static const int _maxCaptureRetries = 2;

  // Re-entrancy guard for _startLiveFeed. _starting blocks a second concurrent
  // call outright; _gen is a generation token bumped on each start so an
  // in-flight start whose token is stale (superseded or disposed mid-await)
  // tears down the controller it created instead of clobbering the live one.
  bool _starting = false;
  int _gen = 0;

  Timer? _timerToDetectFace;
  bool _isCaptureButtonVisible = false;

  // Latest detected face for the optional vertices overlay. Only updated when
  // showFacialVertices is true, so there is no per-frame setState otherwise.
  final ValueNotifier<_FaceOverlay?> _faceNotifier = ValueNotifier(null);

  late final AnimationController _ringController;

  static const _orientations = <DeviceOrientation, int>{
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  //* MARK: - Life Cycle
  //? =========================================================
  @override
  void initState() {
    super.initState();
    // Deep-copy the caller's steps (reset to incomplete) so a const /
    // unmodifiable list is never mutated and a second detect() with the same
    // config does not start pre-completed.
    _steps =
        widget.config.steps.map((s) => s.copyWith(isCompleted: false)).toList();
    _isInfoStepCompleted = !widget.config.startWithInfoScreen;
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        // Contours/landmarks are only needed to draw the vertices overlay.
        enableContours: widget.config.showFacialVertices,
        enableLandmarks: widget.config.showFacialVertices,
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallBack());
  }

  @override
  void dispose() {
    _disposed = true;
    _isCompleted = true;
    WidgetsBinding.instance.removeObserver(this);
    _timerToDetectFace?.cancel();
    _timerToDetectFace = null;
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) unawaited(_disposeController(controller));
    _ringController.dispose();
    _faceNotifier.dispose();
    unawaited(_faceDetector.close());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Camera is going away; the detect timeout must not keep ticking.
      _timerToDetectFace?.cancel();
      _timerToDetectFace = null;
      if (controller == null || !controller.value.isInitialized) return;
      _cameraController = null;
      unawaited(_disposeController(controller));
    } else if (state == AppLifecycleState.resumed) {
      // A fresh feed re-runs the blink sequence from scratch.
      _didCloseEyes = false;
      if (_isCompleted || !_isInfoStepCompleted) return;
      // Already live or a start is already in flight — don't race a second feed.
      if (_cameraController != null || _starting) return;
      _startLiveFeed();
    }
  }

  /// Stops the image stream (if running) and disposes the controller.
  Future<void> _disposeController(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
    await controller.dispose();
  }

  //* MARK: - Camera setup
  //? =========================================================
  void _postFrameCallBack() async {
    try {
      _cameras = await availableCameras();
    } on CameraException catch (_) {
      _failAndPop();
      return;
    }
    if (!mounted || _disposed) return;
    final frontUpright = _cameras.firstWhereOrNull(
      (e) =>
          e.lensDirection == CameraLensDirection.front &&
          e.sensorOrientation == 90,
    );
    final front = frontUpright ??
        _cameras.firstWhereOrNull(
          (e) => e.lensDirection == CameraLensDirection.front,
        );
    if (front == null) {
      _failAndPop();
      return;
    }
    _cameraIndex = _cameras.indexOf(front);
    if (!widget.config.startWithInfoScreen) {
      _startLiveFeed();
    }
  }

  Future<void> _startLiveFeed() async {
    if (_cameras.isEmpty || _disposed || _starting) return;
    _starting = true;
    // Token for THIS start. Any await below that returns to find token != _gen
    // was superseded (another start) or torn down and must not touch state.
    final int token = ++_gen;
    try {
      // Dispose any previous controller first to avoid a native camera-session
      // leak on every retry.
      final old = _cameraController;
      _cameraController = null;
      if (old != null) await _disposeController(old);
      if (token != _gen || !mounted || _disposed) return;

      // Built locally and only promoted to _cameraController once it is fully
      // initialized AND still the current generation, so a racing start/dispose
      // never sees a half-initialized controller or clobbers the live one.
      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      try {
        await controller.initialize();
      } on CameraException catch (_) {
        // Permission denial (CameraAccessDenied) etc. is unrecoverable, but
        // only fail the flow if this start is still the current one.
        unawaited(_disposeController(controller));
        if (token == _gen) _failAndPop();
        return;
      } catch (_) {
        // A dispose/pop racing initialize() can throw a non-CameraException;
        // swallow it, just clean up the controller we created.
        unawaited(_disposeController(controller));
        return;
      }
      if (token != _gen || !mounted || _disposed) {
        unawaited(_disposeController(controller));
        return;
      }
      _cameraController = controller;
      _timerToDetectFace?.cancel();
      _startTimer();
      try {
        await controller.startImageStream(_processCameraImage);
      } catch (_) {
        // dispose/pop racing the stream start — drop the controller we own.
        if (identical(controller, _cameraController)) _cameraController = null;
        unawaited(_disposeController(controller));
        return;
      }
      if (token != _gen || !mounted || _disposed) {
        if (identical(controller, _cameraController)) _cameraController = null;
        unawaited(_disposeController(controller));
        return;
      }
      if (mounted) setState(() {});
    } finally {
      _starting = false;
    }
  }

  void _startTimer() {
    _timerToDetectFace = Timer(
      Duration(seconds: widget.config.maxSecToDetect),
      () {
        _timerToDetectFace?.cancel();
        _timerToDetectFace = null;
        if (widget.config.allowAfterMaxSec) {
          if (mounted) setState(() => _isCaptureButtonVisible = true);
          return;
        }
        _onDetectionCompleted(imgToReturn: null);
      },
    );
  }

  /// Pops the route with `null` on any unrecoverable camera failure so an
  /// awaiting `detect()` never hangs.
  void _failAndPop() {
    _onDetectionCompleted(imgToReturn: null, didCaptureAutomatically: null);
  }

  //* MARK: - Image processing (ML Kit)
  //? =========================================================
  Future<void> _processCameraImage(CameraImage cameraImage) async {
    final inputImage = _inputImageFromCamera(cameraImage);
    if (inputImage == null) return;
    await _processImage(inputImage);
  }

  /// Builds an ML Kit [InputImage] from a [CameraImage] for both platforms.
  /// Android requires NV21, iOS requires BGRA8888 (single plane either way).
  InputImage? _inputImageFromCamera(CameraImage image) {
    if (_cameras.isEmpty) return null;
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      final deviceOrientation = _cameraController?.value.deviceOrientation;
      final rotationCompensation = _orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      final int compensated;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensated = (sensorOrientation + rotationCompensation) % 360;
      } else {
        compensated = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensated);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android &&
            format != InputImageFormat.nv21) ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isBusy || _isCompleted || _disposed) return;
    _isBusy = true;
    try {
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted || _disposed) return;
      final metadata = inputImage.metadata;

      if (metadata != null && faces.isNotEmpty) {
        final Face firstFace = faces.first;
        if (widget.config.showFacialVertices) {
          _faceNotifier.value = (firstFace, metadata.size, metadata.rotation);
        }
        final LivelynessStep currentStep = _steps[_currentIndex].step;
        _detect(face: firstFace, step: currentStep);
      } else {
        if (widget.config.showFacialVertices) _faceNotifier.value = null;
        _resetSteps();
      }
    } catch (_) {
      // processImage can throw if the detector's close() races an in-flight
      // frame during dispose. Swallow it — an unhandled async error in a stream
      // callback would otherwise crash the zone.
    } finally {
      _isBusy = false;
    }
  }

  void _detect({required Face face, required LivelynessStep step}) async {
    if (_transitioning || _isCompleted || _isTakingPicture) return;
    switch (step) {
      case LivelynessStep.blink:
        final BlinkDetectionThreshold? threshold =
            widget.config.thresholds.firstWhereOrNull(
          (p0) => p0 is BlinkDetectionThreshold,
        ) as BlinkDetectionThreshold?;
        final double leftThresh = threshold?.leftEyeProbability ?? 0.25;
        final double rightThresh = threshold?.rightEyeProbability ?? 0.25;
        final double leftOpen = face.leftEyeOpenProbability ?? 1.0;
        final double rightOpen = face.rightEyeOpenProbability ?? 1.0;
        // A blink = eyes close (below threshold) THEN reopen (above threshold).
        if (!_didCloseEyes) {
          if (leftOpen < leftThresh && rightOpen < rightThresh) {
            _didCloseEyes = true;
          }
        } else if (leftOpen > leftThresh && rightOpen > rightThresh) {
          await _completeStep(step);
        }
        break;
      case LivelynessStep.turnLeft:
        final HeadTurnDetectionThreshold? threshold =
            widget.config.thresholds.firstWhereOrNull(
          (p0) => p0 is HeadTurnDetectionThreshold,
        ) as HeadTurnDetectionThreshold?;
        final double a = (threshold?.rotationAngle ?? 45).abs();
        if ((face.headEulerAngleY ?? 0) > a) {
          await _completeStep(step);
        }
        break;
      case LivelynessStep.turnRight:
        final HeadTurnDetectionThreshold? threshold =
            widget.config.thresholds.firstWhereOrNull(
          (p0) => p0 is HeadTurnDetectionThreshold,
        ) as HeadTurnDetectionThreshold?;
        final double a = (threshold?.rotationAngle ?? 45).abs();
        if ((face.headEulerAngleY ?? 0) < -a) {
          await _completeStep(step);
        }
        break;
      case LivelynessStep.smile:
        final SmileDetectionThreshold? threshold =
            widget.config.thresholds.firstWhereOrNull(
          (p0) => p0 is SmileDetectionThreshold,
        ) as SmileDetectionThreshold?;
        if ((face.smilingProbability ?? 0) > (threshold?.probability ?? 0.75)) {
          await _completeStep(step);
        }
        break;
    }
  }

  //* MARK: - Step progression
  //? =========================================================
  Future<void> _completeStep(LivelynessStep step) async {
    final int idx = _steps.indexWhere((p0) => p0.step == step);
    if (idx < 0 || _steps[idx].isCompleted) return;
    _steps[idx] = _steps[idx].copyWith(isCompleted: true);
    _didCloseEyes = false;
    if (mounted) setState(() {});
    await _advance();
  }

  Future<void> _advance() async {
    // Block detection/reset for the whole transition so a face lost mid-advance
    // cannot reset steps underneath a stale increment / capture.
    _transitioning = true;
    final int completed = _steps.where((s) => s.isCompleted).length;
    if (mounted) setState(() => _showCheck = true);
    await _ringController.animateTo(completed / _steps.length);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || _disposed) {
      _transitioning = false;
      return;
    }
    setState(() => _showCheck = false);

    if (_currentIndex + 1 <= _steps.length - 1) {
      setState(() => _currentIndex++);
      _transitioning = false;
    } else {
      _transitioning = false;
      _takePicture(didCaptureAutomatically: true);
    }
  }

  void _resetSteps() {
    if (_transitioning || _isCompleted || _isTakingPicture) return;
    bool changed = false;
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].isCompleted) {
        _steps[i] = _steps[i].copyWith(isCompleted: false);
        changed = true;
      }
    }
    _didCloseEyes = false;
    if (_currentIndex != 0) {
      _currentIndex = 0;
      changed = true;
    }
    if (changed) {
      _ringController.value = 0;
      if (mounted) setState(() {});
    }
  }

  //* MARK: - Capture
  //? =========================================================
  void _takePicture({required bool didCaptureAutomatically}) async {
    final controller = _cameraController;
    if (controller == null || _isTakingPicture || _isCompleted) return;
    // Re-validate the real completed set at capture time (race guard): an
    // auto-capture must only fire once every step is actually completed.
    if (didCaptureAutomatically && !_steps.every((s) => s.isCompleted)) return;
    // Snapshot the completed set NOW, before any await — a face-lost reset
    // racing the capture must not shrink what we report back.
    final List<LivelynessStep> completedSnapshot =
        _steps.where((s) => s.isCompleted).map((s) => s.step).toList();
    setState(() => _isTakingPicture = true);
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final XFile clickedImage = await controller.takePicture();
      if (!mounted || _disposed) {
        // Nothing will consume the file — delete the biometric JPEG.
        unawaited(CapturedImage(
          imgPath: clickedImage.path,
          didCaptureAutomatically: didCaptureAutomatically,
        ).delete());
        return;
      }
      _onDetectionCompleted(
        imgToReturn: clickedImage,
        didCaptureAutomatically: didCaptureAutomatically,
        completedSteps: completedSnapshot,
      );
    } on CameraException catch (_) {
      _captureRetries++;
      if (_captureRetries > _maxCaptureRetries) {
        _failAndPop();
        return;
      }
      if (!mounted || _disposed) return;
      // Restart the feed, then actually re-attempt the capture. All steps are
      // still complete, so relying on _completeStep would never re-fire.
      await _startLiveFeed();
      if (!mounted || _disposed || _cameraController == null) return;
      // Defer so this call's finally clears _isTakingPicture before the retry's
      // guard runs.
      Future.microtask(() {
        if (mounted && !_disposed) {
          _takePicture(didCaptureAutomatically: didCaptureAutomatically);
        }
      });
    } finally {
      _isTakingPicture = false;
    }
  }

  void _onDetectionCompleted({
    XFile? imgToReturn,
    bool? didCaptureAutomatically,
    List<LivelynessStep>? completedSteps,
  }) {
    if (_isCompleted) {
      // Flow already finished (close button / timeout) while a takePicture was
      // in flight. The file will never be consumed — delete the biometric JPEG.
      final String path = imgToReturn?.path ?? "";
      if (path.isNotEmpty) {
        unawaited(
          CapturedImage(imgPath: path, didCaptureAutomatically: false).delete(),
        );
      }
      return;
    }
    if (!mounted) return;
    _isCompleted = true;
    final String imgPath = imgToReturn?.path ?? "";
    if (imgPath.isEmpty || didCaptureAutomatically == null) {
      Navigator.of(context).pop(null);
      return;
    }
    Navigator.of(context).pop(
      CapturedImage(
        imgPath: imgPath,
        didCaptureAutomatically: didCaptureAutomatically,
        completedSteps: completedSteps ??
            _steps.where((s) => s.isCompleted).map((s) => s.step).toList(),
      ),
    );
  }

  //* MARK: - UI
  //? =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isInfoStepCompleted
              ? _buildDetectionBody()
              : LivelynessInfoWidget(
                  onStartTap: () {
                    setState(() => _isInfoStepCompleted = true);
                    _startLiveFeed();
                  },
                ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: _GlassCircleButton(
              icon: Icons.close_rounded,
              semanticLabel: 'Close liveness check',
              onTap: () => _onDetectionCompleted(
                imgToReturn: null,
                didCaptureAutomatically: null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionBody() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildFullBleedPreview(controller),
        if (widget.config.showFacialVertices)
          ValueListenableBuilder<_FaceOverlay?>(
            valueListenable: _faceNotifier,
            builder: (_, data, __) {
              if (data == null) return const SizedBox.shrink();
              return FaceVerticesOverlay(
                face: data.$1,
                imageSize: data.$2,
                rotation: data.$3,
                config: widget.config,
              );
            },
          ),
        // Frosted surroundings outside the oval.
        ClipPath(
          clipper: InvertedOvalClipper(),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox.expand(),
          ),
        ),
        // Scrim + animated progress ring (repaints itself off the controller).
        CustomPaint(
          size: Size.infinite,
          painter: OvalOverlayPainter(
            progress: _ringController,
            overlayColor: widget.config.overlayColor,
            progressColor: widget.config.progressColor,
          ),
        ),
        if (_showCheck) _buildCheck(),
        _buildStepCard(),
        if (_isCaptureButtonVisible) _buildCaptureButton(),
      ],
    );
  }

  Widget _buildFullBleedPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // previewSize is in landscape coordinates; swap for portrait.
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildCheck() {
    return Center(
      child: ZoomIn(
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.config.progressColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  Widget _buildStepCard() {
    final style = widget.config.stepCardStyle;
    final step = _steps[_currentIndex];
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 32,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: ClipRRect(
            key: ValueKey(step.step),
            borderRadius: BorderRadius.circular(style.borderRadius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  borderRadius: BorderRadius.circular(style.borderRadius),
                  border: Border.all(color: style.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForStep(step.step),
                        color: style.iconColor, size: 26),
                    const SizedBox(width: 14),
                    Flexible(
                      // Announce step changes to screen readers.
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: style.textStyle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 120,
        ),
        child: Semantics(
          button: true,
          label: 'Capture photo',
          child: MaterialButton(
            onPressed: () => _takePicture(didCaptureAutomatically: false),
            color: widget.config.captureButtonColor ??
                Theme.of(context).primaryColor,
            textColor: Colors.white,
            padding: const EdgeInsets.all(18),
            shape: const CircleBorder(),
            child: const Icon(Icons.camera_alt, size: 26),
          ),
        ),
      ),
    );
  }

  IconData _iconForStep(LivelynessStep step) {
    switch (step) {
      case LivelynessStep.blink:
        return Icons.remove_red_eye_outlined;
      case LivelynessStep.turnLeft:
        return Icons.turn_left_rounded;
      case LivelynessStep.turnRight:
        return Icons.turn_right_rounded;
      case LivelynessStep.smile:
        return Icons.sentiment_satisfied_alt_rounded;
    }
  }
}

/// Small frosted-glass circular icon button used for the close action.
class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _GlassCircleButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel,
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: const Color(0x33FFFFFF),
              shape: const CircleBorder(
                side: BorderSide(color: Color(0x4DFFFFFF)),
              ),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                // Minimum 48dp tap target for accessibility.
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
