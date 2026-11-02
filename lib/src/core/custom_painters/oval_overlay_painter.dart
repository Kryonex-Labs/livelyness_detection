import 'dart:math' as math;

import 'package:livelyness_detection/index.dart';

/// Computes the centered oval face-guide rect for a given canvas [size].
///
/// Both the scrim painter and the frosted-backdrop clipper use this so the
/// cutout and the blur stay perfectly aligned. Geometry is driven by [config].
Rect livelynessOvalRect(Size size, OvalConfig config) {
  final double width = size.width * config.widthFraction;
  final double height = width * config.aspectRatio;
  final double left = (size.width - width) / 2;
  // Sit the oval slightly above the vertical center to leave room for the
  // instruction card at the bottom.
  final double top =
      (size.height - height) / 2 + size.height * config.verticalOffsetFraction;
  return Rect.fromLTWH(left, top, width, height);
}

/// Clips to everything *outside* the oval guide, so a [BackdropFilter] wrapped
/// in a [ClipPath] frosts the surroundings while leaving the face crisp.
class InvertedOvalClipper extends CustomClipper<Path> {
  final OvalConfig config;

  const InvertedOvalClipper({this.config = const OvalConfig()});

  @override
  Path getClip(Size size) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(livelynessOvalRect(size, config)),
    );
  }

  @override
  bool shouldReclip(covariant InvertedOvalClipper oldClipper) =>
      oldClipper.config != config;
}

/// Paints the dark scrim with an oval cutout plus the animated progress ring
/// that fills as liveness steps are completed.
class OvalOverlayPainter extends CustomPainter {
  /// Completion fraction of the ring, `0.0`..`1.0`. Driven directly off the
  /// animation (also the [repaint] listenable) so the painter repaints without
  /// rebuilding the surrounding widget tree.
  final Animation<double> progress;

  /// Scrim color painted outside the oval.
  final Color overlayColor;

  /// Color of the filled portion of the ring.
  final Color progressColor;

  /// Oval geometry plus ring stroke/padding/track styling.
  final OvalConfig config;

  OvalOverlayPainter({
    required this.progress,
    required this.overlayColor,
    required this.progressColor,
    this.config = const OvalConfig(),
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double value = progress.value;
    final Rect oval = livelynessOvalRect(size, config);

    // Dark scrim everywhere except the oval (even-odd punches the hole).
    final Path scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(scrim, Paint()..color = overlayColor);

    // Ring is drawn just outside the oval edge.
    final Rect ringRect = oval.inflate(config.ringPadding);
    final double stroke = config.ringStrokeWidth;

    canvas.drawOval(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = config.ringTrackColor,
    );

    if (value > 0) {
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        2 * math.pi * value.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke
          ..color = progressColor,
      );
    }
  }

  @override
  bool shouldRepaint(OvalOverlayPainter oldDelegate) {
    // Progress animation changes are handled by the [repaint] listenable;
    // compare the animation identity too in case the listenable is swapped.
    return oldDelegate.progress != progress ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.config != config;
  }
}
