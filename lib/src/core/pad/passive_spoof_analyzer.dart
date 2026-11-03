import 'package:livelyness_detection/index.dart';

/// Phase 1 heuristic passive anti-spoofing analyzer.
///
/// Instantiated once per detection session. Each frame, [addSample] extracts a
/// handful of scalar signals from the detected [Face] and pushes them into
/// fixed-size ring buffers. Once [windowSize] frames are collected ([isReady]),
/// [computeVerdict] measures how much each signal varied over the CURRENT
/// window: a real face always has involuntary micro-movement, a flat printed
/// photo does not.
///
/// The buffers are a TRUE sliding ring: once full, each new sample overwrites
/// the oldest, so the verdict always reflects the most recent ~[windowSize]
/// frames (≈1.5s at 30fps). The verdict is recomputed on every
/// [computeVerdict] call (never cached), which closes the "pass the window then
/// swap in a photo" gap — the swap shifts into the window and is caught.
///
/// Privacy: only extracted doubles are retained. The [Face] object (biometric,
/// GDPR Art. 9 / HIPAA) is never stored past the [addSample] call.
class PassiveSpoofAnalyzer {
  final PadConfig config;

  final List<double> _headYBuffer;
  final List<double> _headXBuffer;
  final List<double> _leftEyeBuffer;
  final List<double> _rightEyeBuffer;
  final List<double> _bboxCenterXBuffer;
  final List<double> _bboxCenterYBuffer;

  // Per-slot validity for the nullable ML Kit signals: `true` only where the
  // frame actually supplied a real value. The bbox center is always present so
  // it needs no validity buffer. Variance is measured over real values only,
  // and a signal without enough real samples is excluded from the verdict
  // entirely (see [computeVerdict]) rather than counted as a failing 0-variance
  // signal — which would false-reject real users on devices/modes that return
  // nulls.
  final List<bool> _headYValid;
  final List<bool> _headXValid;
  final List<bool> _leftEyeValid;
  final List<bool> _rightEyeValid;

  int _writeIndex = 0;
  int _sampleCount = 0;

  PassiveSpoofAnalyzer(this.config)
      : _headYBuffer = List<double>.filled(config.windowSize, 0.0),
        _headXBuffer = List<double>.filled(config.windowSize, 0.0),
        _leftEyeBuffer = List<double>.filled(config.windowSize, 0.0),
        _rightEyeBuffer = List<double>.filled(config.windowSize, 0.0),
        _bboxCenterXBuffer = List<double>.filled(config.windowSize, 0.0),
        _bboxCenterYBuffer = List<double>.filled(config.windowSize, 0.0),
        _headYValid = List<bool>.filled(config.windowSize, false),
        _headXValid = List<bool>.filled(config.windowSize, false),
        _leftEyeValid = List<bool>.filled(config.windowSize, false),
        _rightEyeValid = List<bool>.filled(config.windowSize, false);

  /// `true` once a full window of frames has been collected.
  bool get isReady => _sampleCount >= config.windowSize;

  /// Extracts scalar signals from [face] and stores them in the ring buffers.
  /// The [Face] itself is never retained. Once the window is full the write
  /// index wraps, overwriting the oldest sample so the window keeps sliding.
  void addSample(Face face) {
    final i = _writeIndex;
    final headY = face.headEulerAngleY;
    final headX = face.headEulerAngleX;
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    final center = face.boundingBox.center;

    // Store the real value (or a neutral placeholder) plus a validity flag.
    // Missing values are EXCLUDED from analysis, never treated as 0-variance.
    _headYBuffer[i] = headY ?? 0.0;
    _headYValid[i] = headY != null;
    _headXBuffer[i] = headX ?? 0.0;
    _headXValid[i] = headX != null;
    _leftEyeBuffer[i] = leftEye ?? 0.0;
    _leftEyeValid[i] = leftEye != null;
    _rightEyeBuffer[i] = rightEye ?? 0.0;
    _rightEyeValid[i] = rightEye != null;
    _bboxCenterXBuffer[i] = center.dx;
    _bboxCenterYBuffer[i] = center.dy;

    _writeIndex = (i + 1) % config.windowSize;
    if (_sampleCount < config.windowSize) _sampleCount++;
  }

  /// Computes the verdict from the CURRENT window contents. Not cached —
  /// recomputed every call so it reflects the latest frames.
  ///
  /// Before the window is full ([isReady] is `false`) this returns
  /// [PadResult.inconclusive] and caches nothing.
  ///
  /// Null-signal rule: a signal (head-Y, head-X, eye, bbox jitter) is only
  /// *evaluable* if it has at least 2 real (non-null) samples in the window.
  /// Non-evaluable signals are excluded from BOTH the passing-signal numerator
  /// and the required-signal denominator. If fewer than
  /// [PadConfig.minPassingSignals] signals are evaluable, the verdict is
  /// `inconclusive` (we cannot responsibly decide). Otherwise the verdict is
  /// `live` when `passing >= minPassingSignals`, else `spoof`. The eye signal is
  /// evaluable if either eye has ≥2 real samples; its variance is the max of
  /// whichever eye(s) had data. The bbox center is always present.
  PadResult computeVerdict() {
    if (!isReady) {
      return PadResult.inconclusive(framesAnalyzed: _sampleCount);
    }

    final n = config.windowSize;
    final headY = _stddevValid(_headYBuffer, _headYValid, n);
    final headX = _stddevValid(_headXBuffer, _headXValid, n);
    final leftEye = _stddevValid(_leftEyeBuffer, _leftEyeValid, n);
    final rightEye = _stddevValid(_rightEyeBuffer, _rightEyeValid, n);
    final bboxX = _stddev(_bboxCenterXBuffer, n);
    final bboxY = _stddev(_bboxCenterYBuffer, n);
    final bboxJitter = sqrt(bboxX * bboxX + bboxY * bboxY);

    int passing = 0;
    int evaluable = 0;

    if (headY.count >= 2) {
      evaluable++;
      if (headY.stddev >= config.minHeadYVariance) passing++;
    }
    if (headX.count >= 2) {
      evaluable++;
      if (headX.stddev >= config.minHeadXVariance) passing++;
    }
    // Eye signal: evaluable if either eye produced ≥2 real samples; use the max
    // stddev of whichever eye(s) had data.
    final eyeEvaluable = leftEye.count >= 2 || rightEye.count >= 2;
    final eyeVar = _max(
      leftEye.count >= 2 ? leftEye.stddev : 0.0,
      rightEye.count >= 2 ? rightEye.stddev : 0.0,
    );
    if (eyeEvaluable) {
      evaluable++;
      if (eyeVar >= config.minEyeVariance) passing++;
    }
    // bbox center is always present (window is full and windowSize > 1).
    evaluable++;
    if (bboxJitter >= config.minBboxJitter) passing++;

    final PadVerdict verdict;
    if (evaluable < config.minPassingSignals) {
      verdict = PadVerdict.inconclusive;
    } else {
      verdict = passing >= config.minPassingSignals
          ? PadVerdict.live
          : PadVerdict.spoof;
    }

    return PadResult(
      verdict: verdict,
      headYVariance: headY.stddev,
      headXVariance: headX.stddev,
      eyeVariance: eyeVar,
      bboxJitter: bboxJitter,
      passingSignals: passing,
      framesAnalyzed: n,
    );
  }

  /// Clears all buffers, the sample count and the write index. Called when the
  /// face is lost so the next detection session starts from a clean window.
  void reset() {
    _writeIndex = 0;
    _sampleCount = 0;
    final n = config.windowSize;
    _headYBuffer.fillRange(0, n, 0.0);
    _headXBuffer.fillRange(0, n, 0.0);
    _leftEyeBuffer.fillRange(0, n, 0.0);
    _rightEyeBuffer.fillRange(0, n, 0.0);
    _bboxCenterXBuffer.fillRange(0, n, 0.0);
    _bboxCenterYBuffer.fillRange(0, n, 0.0);
    _headYValid.fillRange(0, n, false);
    _headXValid.fillRange(0, n, false);
    _leftEyeValid.fillRange(0, n, false);
    _rightEyeValid.fillRange(0, n, false);
  }

  /// Population standard deviation over the first [n] entries of [buffer].
  /// `sqrt(sum((x - mean)^2) / n)`. Returns 0 for n < 2.
  double _stddev(List<double> buffer, int n) {
    if (n < 2) return 0.0;
    double sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += buffer[i];
    }
    final mean = sum / n;
    double sqDiff = 0.0;
    for (var i = 0; i < n; i++) {
      final d = buffer[i] - mean;
      sqDiff += d * d;
    }
    return sqrt(sqDiff / n);
  }

  /// Population standard deviation over the *valid* entries only, with the count
  /// of valid samples. `stddev` is 0 when fewer than 2 valid samples exist.
  ({double stddev, int count}) _stddevValid(
      List<double> buffer, List<bool> valid, int n) {
    double sum = 0.0;
    var count = 0;
    for (var i = 0; i < n; i++) {
      if (valid[i]) {
        sum += buffer[i];
        count++;
      }
    }
    if (count < 2) return (stddev: 0.0, count: count);
    final mean = sum / count;
    double sqDiff = 0.0;
    for (var i = 0; i < n; i++) {
      if (valid[i]) {
        final d = buffer[i] - mean;
        sqDiff += d * d;
      }
    }
    return (stddev: sqrt(sqDiff / count), count: count);
  }

  double _max(double a, double b) => a > b ? a : b;
}
