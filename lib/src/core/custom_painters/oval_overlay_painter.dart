import 'dart:math' as math;

import 'package:livelyness_detection/index.dart';

/// Computes the centered oval face-guide rect for a given canvas [size].
///
/// Both the scrim painter and the frosted-backdrop clipper use this so the
/// cutout and the blur stay perfectly aligned.
Rect livelynessOvalRect(Size size) {
  final double width = size.width * 0.72;
  final double height = width * 1.32;
  final double left = (size.width - width) / 2;
  // Sit the oval slightly above the vertical center to leave room for the
  // instruction card at the bottom.
  final double top = (size.height - height) / 2 - size.height * 0.06;
  return Rect.fromLTWH(left, top, width, height);
}

/// Clips to everything *outside* the oval guide, so a [BackdropFilter] wrapped
/// in a [ClipPath] frosts the surroundings while leaving the face crisp.
class InvertedOvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(livelynessOvalRect(size)),
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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

  /// Color of the unfilled ring track.
  final Color trackColor;

  OvalOverlayPainter({
    required this.progress,
    required this.overlayColor,
    required this.progressColor,
    this.trackColor = const Color(0x33FFFFFF),
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double value = progress.value;
    final Rect oval = livelynessOvalRect(size);

    // Dark scrim everywhere except the oval (even-odd punches the hole).
    final Path scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(scrim, Paint()..color = overlayColor);

    // Ring is drawn just outside the oval edge.
    final Rect ringRect = oval.inflate(6);
    final double stroke = 5.0;

    canvas.drawOval(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = trackColor,
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
        oldDelegate.trackColor != trackColor;
  }
}
