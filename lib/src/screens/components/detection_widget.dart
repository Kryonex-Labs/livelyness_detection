import 'package:livelyness_detection/index.dart';

/// Draws the ML Kit facial contour vertices over the live camera preview.
///
/// Camera-only (the old camerawesome preview-decorator has been removed in
/// v2.0). Feed it the latest detected [face] plus the analysed image metadata.
class FaceVerticesOverlay extends StatelessWidget {
  final Face face;
  final Size imageSize;
  final InputImageRotation rotation;
  final DetectionConfig config;

  const FaceVerticesOverlay({
    super.key,
    required this.face,
    required this.imageSize,
    required this.rotation,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: FaceDetectorPainter(
          face,
          imageSize,
          rotation,
          lineColor: config.contourLineColor,
          dotColor: config.contourDotColor,
          lineWidth: config.contourLineWidth,
          dotRadius: config.contourDotRadius,
          displayLines: config.displayLines,
          displayDots: config.displayDots,
        ),
      ),
    );
  }
}
