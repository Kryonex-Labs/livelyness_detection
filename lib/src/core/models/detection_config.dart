import 'package:livelyness_detection/index.dart';

/// Optional styling for the glassmorphic step-instruction card shown at the
/// bottom of the detection screen.
class StepCardStyle {
  /// Fill color of the frosted card. Defaults to a translucent white.
  final Color backgroundColor;

  /// Color of the subtle 1px border around the card.
  final Color borderColor;

  /// Corner radius of the card.
  final double borderRadius;

  /// Text style for the instruction label.
  final TextStyle textStyle;

  /// Tint color of the leading step icon.
  final Color iconColor;

  const StepCardStyle({
    this.backgroundColor = const Color(0x33FFFFFF),
    this.borderColor = const Color(0x4DFFFFFF),
    this.borderRadius = 20,
    this.textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    this.iconColor = Colors.white,
  });
}

/// Holds every configuration value used by [LivelynessDetection.detect].
///
/// In v2.0 this fully replaces the old `configure()` singleton call: all
/// detection thresholds, contour styling and UI colors now live here.
class DetectionConfig {
  /// Ordered list of liveness checks the user must pass.
  final List<LivelynessStepItem> steps;

  /// Threshold values used while verifying each step (blink / head-turn /
  /// smile). When a step has no matching threshold, a sensible default is used.
  final List<DetectionThreshold> thresholds;

  /// Whether the flow should open with an informational screen.
  /// Default is `false`.
  final bool startWithInfoScreen;

  /// Maximum time (in seconds) allowed to complete detection.
  /// Default is `15`.
  final int maxSecToDetect;

  /// Whether to let the user capture manually once [maxSecToDetect] elapses.
  final bool allowAfterMaxSec;

  /// Whether to draw the ML Kit facial contour vertices during detection.
  final bool showFacialVertices;

  /// Icon color of the manual capture-button shown after [maxSecToDetect].
  final Color? captureButtonColor;

  /// Color of the contour lines drawn over the detected face.
  final Color contourLineColor;

  /// Color of the contour dots drawn over the detected face.
  final Color contourDotColor;

  /// Radius of each contour dot.
  final double contourDotRadius;

  /// Stroke width of the contour lines.
  final double contourLineWidth;

  /// Whether to draw contour lines.
  final bool displayLines;

  /// Whether to draw contour dots.
  final bool displayDots;

  /// Optional `[dashLength, dashGap]` pair. When provided contour lines are
  /// drawn dashed instead of solid.
  final List<double>? dashValues;

  /// Scrim color painted outside the oval face guide.
  /// Defaults to a dark translucent black.
  final Color overlayColor;

  /// Color of the animated progress ring around the oval guide.
  final Color progressColor;

  /// Optional styling for the bottom instruction card.
  final StepCardStyle stepCardStyle;

  /// Customisation for the introductory info screen.
  final InfoScreenConfig infoScreenConfig;

  /// Geometry/styling of the oval face guide, frosted surroundings and ring.
  final OvalConfig ovalConfig;

  /// Camera resolution, lens and detection-rate tunables.
  final CameraConfig cameraConfig;

  /// Called after a step is marked complete, with the completed step, the
  /// number of steps completed so far and the total step count.
  final void Function(LivelynessStep step, int completedCount, int totalSteps)?
      onStepCompleted;

  /// Called on every frame a face is detected. Fires at frame rate — keep the
  /// callback lightweight.
  ///
  /// Privacy: the [Face] is biometric data (GDPR Art. 9 special-category data /
  /// a HIPAA biometric identifier). Do not log, persist, or transmit it (or any
  /// value derived from it) without the user's explicit consent, and do not
  /// retain a reference to it past the callback invocation.
  final void Function(Face face)? onFaceDetected;

  /// Called when detection times out (before capture-button / pop logic).
  final void Function()? onTimeout;

  /// Called with the final result just before the route is popped.
  ///
  /// Privacy: a non-null [CapturedImage] points to a biometric face image on
  /// disk. The consumer owns its lifecycle and must delete it when done; do not
  /// upload or log the image (or its path) without the user's explicit consent.
  final void Function(CapturedImage? result)? onComplete;

  /// Builds the route used to push the detection screen. `null` uses a
  /// [MaterialPageRoute].
  final Route<CapturedImage?> Function(Widget screen)? routeBuilder;

  DetectionConfig({
    required this.steps,
    this.thresholds = const [],
    this.startWithInfoScreen = false,
    this.maxSecToDetect = 15,
    this.allowAfterMaxSec = false,
    this.showFacialVertices = false,
    this.captureButtonColor,
    this.contourLineColor = const Color(0xFFEAEAEA),
    this.contourDotColor = const Color(0xFFEAEAEA),
    this.contourDotRadius = 2.0,
    this.contourLineWidth = 1.6,
    this.displayLines = true,
    this.displayDots = true,
    this.dashValues,
    this.overlayColor = const Color(0xCC000000),
    this.progressColor = const Color(0xFF4CD964),
    this.stepCardStyle = const StepCardStyle(),
    this.infoScreenConfig = const InfoScreenConfig(),
    this.ovalConfig = const OvalConfig(),
    this.cameraConfig = const CameraConfig(),
    this.onStepCompleted,
    this.onFaceDetected,
    this.onTimeout,
    this.onComplete,
    this.routeBuilder,
  }) {
    // Runtime guards (asserts are stripped in release builds).
    if (steps.isEmpty) {
      throw ArgumentError.value(
        steps,
        'steps',
        'Cannot pass an empty array of [LivelynessStepItem].',
      );
    }
    if (maxSecToDetect <= 0) {
      throw ArgumentError.value(
        maxSecToDetect,
        'maxSecToDetect',
        'must be greater than 0',
      );
    }
    assert(
      dashValues == null || dashValues!.length == 2,
      'Dash values must be of length 2',
    );
  }

  /// Whether contour lines should be rendered dashed.
  bool get displayDash => dashValues != null && dashValues!.length == 2;

  /// Dash segment length (defaults to `5`).
  double get dashLength => dashValues?[0] ?? 5;

  /// Gap between dash segments (defaults to `5`).
  double get dashGap => dashValues?[1] ?? 5;
}
