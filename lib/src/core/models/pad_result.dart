import 'package:livelyness_detection/index.dart';

/// Overall verdict reached by the passive anti-spoofing analyzer.
enum PadVerdict {
  /// Enough micro-movement signals passed — treated as a real, live face.
  live,

  /// Too little variance across the window — treated as a flat/printed spoof.
  spoof,

  /// Not enough frames were collected to decide (window never filled).
  inconclusive,
}

/// Result of a passive anti-spoofing (PAD) analysis pass.
///
/// Carries the overall [verdict] plus the individual signal values that led to
/// it, so callers can log or tune thresholds. All variance fields are standard
/// deviations measured across the collected frame window.
class PadResult extends Equatable {
  /// Overall verdict.
  final PadVerdict verdict;

  /// Standard deviation of the head euler Y angle across the window (degrees).
  final double headYVariance;

  /// Standard deviation of the head euler X angle across the window (degrees).
  final double headXVariance;

  /// Standard deviation of eye-open probability across the window.
  final double eyeVariance;

  /// Standard deviation magnitude of the bounding-box center (pixels).
  final double bboxJitter;

  /// How many of the signals passed their threshold.
  final int passingSignals;

  /// Number of frames analyzed to produce this result.
  final int framesAnalyzed;

  const PadResult({
    required this.verdict,
    required this.headYVariance,
    required this.headXVariance,
    required this.eyeVariance,
    required this.bboxJitter,
    required this.passingSignals,
    required this.framesAnalyzed,
  });

  /// A result for when the window never filled: no decision could be made.
  factory PadResult.inconclusive({int framesAnalyzed = 0}) {
    return PadResult(
      verdict: PadVerdict.inconclusive,
      headYVariance: 0.0,
      headXVariance: 0.0,
      eyeVariance: 0.0,
      bboxJitter: 0.0,
      passingSignals: 0,
      framesAnalyzed: framesAnalyzed,
    );
  }

  /// Verdict-only serialization: omits raw variance signals (behavioral
  /// biometrics) so they do not leak when the caller persists or uploads
  /// CapturedImage.toMap(). Use [toDetailedMap] when you need the full
  /// telemetry and accept the privacy implications.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'verdict': verdict.index,
      'passingSignals': passingSignals,
      'framesAnalyzed': framesAnalyzed,
    };
  }

  /// Full serialization including raw variance signals. These are behavioral
  /// biometric telemetry: do not persist or transmit unencrypted.
  Map<String, dynamic> toDetailedMap() {
    return <String, dynamic>{
      'verdict': verdict.index,
      'headYVariance': headYVariance,
      'headXVariance': headXVariance,
      'eyeVariance': eyeVariance,
      'bboxJitter': bboxJitter,
      'passingSignals': passingSignals,
      'framesAnalyzed': framesAnalyzed,
    };
  }

  factory PadResult.fromMap(Map<String, dynamic> map) {
    final verdictIndex = map['verdict'];
    final verdict = (verdictIndex is int &&
            verdictIndex >= 0 &&
            verdictIndex < PadVerdict.values.length)
        ? PadVerdict.values[verdictIndex]
        : PadVerdict.inconclusive;
    double d(Object? v) => v is num ? v.toDouble() : 0.0;
    int i(Object? v) => v is num ? v.toInt() : 0;
    return PadResult(
      verdict: verdict,
      headYVariance: d(map['headYVariance']),
      headXVariance: d(map['headXVariance']),
      eyeVariance: d(map['eyeVariance']),
      bboxJitter: d(map['bboxJitter']),
      passingSignals: i(map['passingSignals']),
      framesAnalyzed: i(map['framesAnalyzed']),
    );
  }

  String toJson() => json.encode(toMap());

  factory PadResult.fromJson(String source) =>
      PadResult.fromMap(json.decode(source));

  @override
  List<Object?> get props => [
        verdict,
        headYVariance,
        headXVariance,
        eyeVariance,
        bboxJitter,
        passingSignals,
        framesAnalyzed,
      ];

  // Verdict-only: the raw variance signals are behavioral biometrics and must
  // not leak into logs. Read the fields directly when you need the detail.
  @override
  String toString() => 'PadResult(verdict: $verdict)';
}
