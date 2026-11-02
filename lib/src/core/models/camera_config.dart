import 'package:livelyness_detection/index.dart';

/// Camera-related tunables for the detection flow.
///
/// Every default reproduces the current v2.0 behaviour, so passing a bare
/// `const CameraConfig()` changes nothing.
class CameraConfig {
  /// Capture/preview resolution preset.
  final ResolutionPreset resolution;

  /// Preferred lens direction when selecting a camera.
  final CameraLensDirection preferredLens;

  /// Maximum number of frames per second fed to the face detector. Lowering
  /// this (e.g. `15`) reduces CPU/battery at the cost of responsiveness.
  ///
  /// A value `<= 0` disables throttling, and the default (`>= 30`) is treated
  /// as effectively unthrottled so every delivered frame is processed.
  final int maxDetectionFps;

  const CameraConfig({
    this.resolution = ResolutionPreset.high,
    this.preferredLens = CameraLensDirection.front,
    this.maxDetectionFps = 30,
  });
}
