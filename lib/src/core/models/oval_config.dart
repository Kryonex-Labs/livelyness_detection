import 'package:livelyness_detection/index.dart';

/// Geometry and styling of the oval face guide, its frosted surroundings and
/// the animated progress ring.
///
/// Every default reproduces the current v2.0 behaviour, so passing a bare
/// `const OvalConfig()` changes nothing.
class OvalConfig {
  /// Oval width as a fraction of the canvas width.
  final double widthFraction;

  /// Oval height relative to its width (`height = width * aspectRatio`).
  final double aspectRatio;

  /// Vertical offset as a fraction of canvas height (negative = upward).
  final double verticalOffsetFraction;

  /// Gaussian blur sigma for the frosted area outside the oval.
  final double blurSigma;

  /// Stroke width of the progress ring.
  final double ringStrokeWidth;

  /// Color of the unfilled ring track.
  final Color ringTrackColor;

  /// Padding between the oval edge and the ring.
  final double ringPadding;

  const OvalConfig({
    this.widthFraction = 0.72,
    this.aspectRatio = 1.32,
    this.verticalOffsetFraction = -0.06,
    this.blurSigma = 8.0,
    this.ringStrokeWidth = 5.0,
    this.ringTrackColor = const Color(0x33FFFFFF),
    this.ringPadding = 6.0,
  });
}
