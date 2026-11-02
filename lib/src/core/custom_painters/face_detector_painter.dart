//sky_engine/lib/ui/painting.dart
import 'package:livelyness_detection/index.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(
    this.face,
    this.absoluteImageSize,
    this.rotation, {
    this.lineColor = const Color(0xFFEAEAEA),
    this.dotColor = const Color(0xFFEAEAEA),
    this.lineWidth = 1.6,
    this.dotRadius = 2.0,
    this.displayLines = true,
    this.displayDots = true,
  });

  final Face face;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final Color lineColor;
  final Color dotColor;
  final double lineWidth;
  final double dotRadius;
  final bool displayLines;
  final bool displayDots;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..color = lineColor;

    final Paint dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = dotColor;

    void paintContour(FaceContourType type) {
      final faceContour = face.contours[type];
      if (faceContour != null) {
        final points = faceContour.points;
        for (var i = 0; displayLines && i < points.length; i++) {
          final Point<int> p1 = points[i];
          if (i + 1 < points.length) {
            final Point<int> p2 = points[i + 1];
            canvas.drawLine(
              Offset(
                MathHelper.instance.translateX(
                  p1.x.toDouble(),
                  rotation,
                  size,
                  absoluteImageSize,
                ),
                MathHelper.instance.translateY(
                  p1.y.toDouble(),
                  rotation,
                  size,
                  absoluteImageSize,
                ),
              ),
              Offset(
                MathHelper.instance.translateX(
                  p2.x.toDouble(),
                  rotation,
                  size,
                  absoluteImageSize,
                ),
                MathHelper.instance.translateY(
                  p2.y.toDouble(),
                  rotation,
                  size,
                  absoluteImageSize,
                ),
              ),
              linePaint,
            );
          }
        }
        for (final Point point in displayDots ? points : const <Point<int>>[]) {
          canvas.drawCircle(
            Offset(
              MathHelper.instance.translateX(
                point.x.toDouble(),
                rotation,
                size,
                absoluteImageSize,
              ),
              MathHelper.instance.translateY(
                point.y.toDouble(),
                rotation,
                size,
                absoluteImageSize,
              ),
            ),
            dotRadius,
            dotPaint,
          );
        }
      }
    }

    paintContour(FaceContourType.face);
    paintContour(FaceContourType.leftEyebrowTop);
    paintContour(FaceContourType.leftEyebrowBottom);
    paintContour(FaceContourType.rightEyebrowTop);
    paintContour(FaceContourType.rightEyebrowBottom);
    paintContour(FaceContourType.leftEye);
    paintContour(FaceContourType.rightEye);
    paintContour(FaceContourType.upperLipTop);
    paintContour(FaceContourType.upperLipBottom);
    paintContour(FaceContourType.lowerLipTop);
    paintContour(FaceContourType.lowerLipBottom);
    paintContour(FaceContourType.noseBridge);
    paintContour(FaceContourType.noseBottom);
    paintContour(FaceContourType.leftCheek);
    paintContour(FaceContourType.rightCheek);
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.face != face;
  }
}
