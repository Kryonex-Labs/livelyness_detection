import 'package:livelyness_detection/index.dart';

export './src/index.dart';

/// Entry point of the `livelyness_detection` package.
///
/// v2.0 drops the old `configure()` + singleton pattern: everything is passed
/// through a single [DetectionConfig], and detection is launched with one
/// static call.
///
/// ```dart
/// final CapturedImage? result = await LivelynessDetection.detect(
///   context: context,
///   config: DetectionConfig(
///     steps: [
///       LivelynessStepItem(
///         step: LivelynessStep.blink,
///         title: 'Blink your eyes',
///         isCompleted: false,
///       ),
///     ],
///     thresholds: [BlinkDetectionThreshold()],
///     startWithInfoScreen: true,
///   ),
/// );
/// ```
abstract final class LivelynessDetection {
  const LivelynessDetection._();

  /// Guards against launching a second flow while one is already on screen.
  static bool _isActive = false;

  /// Launches the liveness detection flow and returns the captured selfie.
  ///
  /// Pushes a full-screen route onto the navigator of [context] and resolves
  /// to a [CapturedImage] once a selfie is captured, or `null` if the user
  /// cancels or the detection times out without a capture.
  ///
  /// All behaviour — the ordered [DetectionConfig.steps], detection
  /// [DetectionConfig.thresholds], contour styling and UI colors — is supplied
  /// via [config]. The same screen is used on both iOS and Android.
  static Future<CapturedImage?> detect({
    required BuildContext context,
    required DetectionConfig config,
  }) async {
    // Ignore a concurrent/double launch (e.g. a double-tapped button).
    if (_isActive) return null;
    _isActive = true;
    try {
      final Route<CapturedImage?> route = config.routeBuilder
              ?.call(LivelynessDetectionScreen(config: config)) ??
          MaterialPageRoute(
            builder: (_) => LivelynessDetectionScreen(config: config),
          );
      return await Navigator.of(context).push<CapturedImage?>(route);
    } finally {
      _isActive = false;
    }
  }
}
