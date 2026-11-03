import 'package:flutter_test/flutter_test.dart';
import 'package:livelyness_detection/index.dart';

/// Builds a minimal [Face] carrying only the scalar signals PAD reads.
/// Pass `null` for a signal to simulate a device/mode that omits it.
Face _face({
  double? headY = 0.0,
  double? headX = 0.0,
  double? leftEye = 1.0,
  double? rightEye = 1.0,
  double centerX = 100.0,
  double centerY = 100.0,
}) {
  return Face(
    boundingBox: Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 50,
      height: 50,
    ),
    landmarks: const <FaceLandmarkType, FaceLandmark?>{},
    contours: const <FaceContourType, FaceContour?>{},
    headEulerAngleY: headY,
    headEulerAngleX: headX,
    leftEyeOpenProbability: leftEye,
    rightEyeOpenProbability: rightEye,
  );
}

void main() {
  final config = PadConfig(windowSize: 10);

  group('PassiveSpoofAnalyzer', () {
    test('constant values across the window => spoof', () {
      final analyzer = PassiveSpoofAnalyzer(config);
      for (var i = 0; i < config.windowSize; i++) {
        analyzer.addSample(_face()); // identical every frame
      }
      expect(analyzer.isReady, isTrue);

      final result = analyzer.computeVerdict();
      expect(result.verdict, PadVerdict.spoof);
      expect(result.passingSignals, 0);
      expect(result.framesAnalyzed, config.windowSize);
      expect(result.headYVariance, 0.0);
      expect(result.bboxJitter, 0.0);
    });

    test('noisy/varied values across the window => live', () {
      final analyzer = PassiveSpoofAnalyzer(config);
      for (var i = 0; i < config.windowSize; i++) {
        analyzer.addSample(_face(
          headY: i.toDouble(), // large spread
          headX: i * 0.5,
          leftEye: i.isEven ? 0.3 : 0.9, // eye jitter
          rightEye: i.isEven ? 0.4 : 0.8,
          centerX: 100.0 + i * 5, // bbox drift
          centerY: 100.0 + i * 3,
        ));
      }
      final result = analyzer.computeVerdict();
      expect(result.verdict, PadVerdict.live);
      expect(result.passingSignals, 4);
    });

    test('partial window => not ready', () {
      final analyzer = PassiveSpoofAnalyzer(config);
      for (var i = 0; i < config.windowSize - 1; i++) {
        analyzer.addSample(_face(headY: i.toDouble()));
      }
      expect(analyzer.isReady, isFalse);
    });

    test('reset clears the buffer and the cached verdict', () {
      final analyzer = PassiveSpoofAnalyzer(config);
      // Fill with constant data => spoof, and cache it.
      for (var i = 0; i < config.windowSize; i++) {
        analyzer.addSample(_face());
      }
      expect(analyzer.computeVerdict().verdict, PadVerdict.spoof);

      analyzer.reset();
      expect(analyzer.isReady, isFalse);

      // A fresh window of varied data must yield a NEW verdict, proving the
      // cached spoof result and the old samples were cleared.
      for (var i = 0; i < config.windowSize; i++) {
        analyzer.addSample(_face(
          headY: i.toDouble(),
          headX: i * 0.5,
          leftEye: i.isEven ? 0.3 : 0.9,
          rightEye: i.isEven ? 0.4 : 0.8,
          centerX: 100.0 + i * 5,
          centerY: 100.0 + i * 3,
        ));
      }
      expect(analyzer.computeVerdict().verdict, PadVerdict.live);
    });

    test('ring buffer wraps: verdict reflects recent samples, not initial ones',
        () {
      final analyzer = PassiveSpoofAnalyzer(config);
      // Fill the window with varied data => live.
      void feedVaried() {
        for (var i = 0; i < config.windowSize; i++) {
          analyzer.addSample(_face(
            headY: i.toDouble(),
            headX: i * 0.5,
            leftEye: i.isEven ? 0.3 : 0.9,
            rightEye: i.isEven ? 0.4 : 0.8,
            centerX: 100.0 + i * 5,
            centerY: 100.0 + i * 3,
          ));
        }
      }

      feedVaried();
      expect(analyzer.computeVerdict().verdict, PadVerdict.live);

      // Now overwrite the whole window with constant frames. Because the buffer
      // slides (wraps), the stale varied samples are gone and the verdict must
      // recompute to spoof — proving no fill-once freeze and no cached verdict.
      for (var i = 0; i < config.windowSize; i++) {
        analyzer.addSample(_face()); // constant
      }
      expect(analyzer.computeVerdict().verdict, PadVerdict.spoof);
    });

    test('computeVerdict before ready is inconclusive and is not cached', () {
      final analyzer = PassiveSpoofAnalyzer(config);
      for (var i = 0; i < config.windowSize - 1; i++) {
        analyzer.addSample(_face(headY: i.toDouble()));
      }
      // Window not full yet.
      expect(analyzer.isReady, isFalse);
      expect(analyzer.computeVerdict().verdict, PadVerdict.inconclusive);

      // One more frame fills it; the earlier inconclusive must NOT be cached —
      // a real verdict is produced over the (varied) window.
      analyzer.addSample(_face(
        headY: 99,
        headX: 50,
        leftEye: 0.2,
        rightEye: 0.9,
        centerX: 999,
        centerY: 999,
      ));
      expect(analyzer.isReady, isTrue);
      expect(analyzer.computeVerdict().verdict, isNot(PadVerdict.inconclusive));
    });

    test('null signals are excluded, not counted as failing (no false reject)',
        () {
      final analyzer = PassiveSpoofAnalyzer(config);
      // Device returns null head angles and null eye probabilities every frame,
      // but the bbox center jitters like a real face. Only 1 signal (bbox) is
      // evaluable, which is < minPassingSignals (3), so the verdict must be
      // inconclusive — NOT spoof (the old 0.0/1.0 fallback false-rejected here).
      for (var i = 0; i < config.windowSize; i++) {
        analyzer.addSample(_face(
          headY: null,
          headX: null,
          leftEye: null,
          rightEye: null,
          centerX: 100.0 + i * 5,
          centerY: 100.0 + i * 3,
        ));
      }
      final result = analyzer.computeVerdict();
      expect(result.verdict, PadVerdict.inconclusive);
      expect(result.verdict, isNot(PadVerdict.spoof));
    });

    test('PadResult.inconclusive factory', () {
      final r = PadResult.inconclusive(framesAnalyzed: 5);
      expect(r.verdict, PadVerdict.inconclusive);
      expect(r.framesAnalyzed, 5);
      expect(r.passingSignals, 0);
    });
  });

  group('PadConfig', () {
    test('blockOnInconclusive defaults to false (fail open)', () {
      expect(PadConfig().blockOnInconclusive, isFalse);
    });

    test('blockOnInconclusive survives copyWith / round-trips through a map',
        () {
      final cfg = PadConfig().copyWith(blockOnInconclusive: true);
      expect(cfg.blockOnInconclusive, isTrue);
      expect(PadConfig.fromMap(cfg.toMap()).blockOnInconclusive, isTrue);
    });

    test('constructor validates in release (throws on degenerate values)', () {
      expect(() => PadConfig(windowSize: 1), throwsArgumentError);
      expect(() => PadConfig(minPassingSignals: 0), throwsArgumentError);
      expect(() => PadConfig(minPassingSignals: 5), throwsArgumentError);
      expect(() => PadConfig(minBboxJitter: -1), throwsArgumentError);
    });

    test('fromMap sanitizes malformed dynamic values without TypeError', () {
      final cfg = PadConfig.fromMap(<String, dynamic>{
        'enabled': 'yes', // wrong type -> default true
        'windowSize': '30', // wrong type -> default 45
        'blockOnInconclusive': 1, // wrong type -> default false
      });
      expect(cfg.enabled, isTrue);
      expect(cfg.windowSize, 45);
      expect(cfg.blockOnInconclusive, isFalse);
    });
  });
}
