import 'package:livelyness_detection/index.dart';

/// Tunables for Phase 1 passive anti-spoofing (PAD).
///
/// PAD watches the involuntary micro-movements every real face has (tiny head
/// drift, eye-open jitter, bounding-box wobble) across a sliding window of
/// frames. A flat printed photo held in front of the camera shows near-zero
/// variance and is flagged as a spoof.
///
/// Every default reproduces sensible behaviour, so passing a bare
/// `PadConfig()` enables PAD with balanced thresholds.
///
/// ## Security model — read before relying on this
///
/// PAD **fails open by default**: an `inconclusive` verdict (window never
/// filled) passes capture unless [blockOnInconclusive] is set to `true`.
///
/// Phase 1 only catches **flat, still** printed photos. A hand-held printed
/// photo introduces enough jitter to pass this heuristic — the hand-motion
/// bypass is a known limitation. PAD is therefore **not a standalone security
/// gate**.
///
/// A spoofer who suppresses ML Kit head-angle or eye data (e.g. by partially
/// occluding the face) forces an `inconclusive` verdict, which with the
/// default [blockOnInconclusive] = `false` passes capture silently. For
/// high-assurance use cases, set `blockOnInconclusive: true`.
///
/// The resulting [PadResult] is produced **client-side and is unauthenticated**.
/// It must not be treated as server-side proof of liveness; the server /
/// downstream must independently re-verify the capture.
class PadConfig extends Equatable {
  /// Enable passive anti-spoofing analysis. Default: `true`.
  final bool enabled;

  /// Number of frames to collect before computing a verdict. Default: `45`.
  /// At 30fps this is ~1.5 seconds of data.
  final int windowSize;

  /// Minimum standard deviation of head euler Y angle across the window.
  /// Below this threshold the signal is considered too flat. Default: `0.3`.
  final double minHeadYVariance;

  /// Minimum standard deviation of head euler X angle. Default: `0.2`.
  final double minHeadXVariance;

  /// Minimum standard deviation of eye-open probability. Default: `0.02`.
  final double minEyeVariance;

  /// Minimum standard deviation magnitude of the bounding-box center, in
  /// pixels. Default: `1.5`.
  final double minBboxJitter;

  /// How many of the 4 signals must pass for a `live` verdict. Default: `3`.
  final int minPassingSignals;

  /// Block capture on a `spoof` verdict. Default: `true`.
  /// When `false`, capture proceeds and the [PadResult] is attached to the
  /// [CapturedImage] for the caller to inspect.
  final bool blockOnSpoof;

  /// Block capture on an `inconclusive` verdict (the window never filled, so no
  /// decision could be made). Default: `false`.
  ///
  /// The default is deliberately fail-open: inconclusive captures pass so slow
  /// devices / short sessions are not rejected. Set `true` for a fail-closed
  /// posture where a face that never produced enough frames is blocked.
  final bool blockOnInconclusive;

  /// Called with the PAD result as soon as a verdict is reached.
  ///
  /// The [PadResult] contains raw variance signals (behavioral biometrics).
  /// Do not log, persist, or transmit the result unencrypted. Use
  /// [PadResult.toMap] (verdict-only) for safe serialization, or
  /// [PadResult.toDetailedMap] when you accept the privacy implications.
  ///
  /// Not serialized (excluded from [toMap]/[fromMap]) and excluded from
  /// equality, matching how the detection callbacks are handled elsewhere.
  final void Function(PadResult result)? onPadResult;

  // Not const: the body validates in release too (asserts are stripped, and a
  // degenerate PAD config silently fails open — a security risk). Sibling leaf
  // configs stay const; PadConfig is the one whose bad values cause real harm.
  PadConfig({
    this.enabled = true,
    this.windowSize = 45,
    this.minHeadYVariance = 0.3,
    this.minHeadXVariance = 0.2,
    this.minEyeVariance = 0.02,
    this.minBboxJitter = 1.5,
    this.minPassingSignals = 3,
    this.blockOnSpoof = true,
    this.blockOnInconclusive = false,
    this.onPadResult,
  }) {
    if (windowSize <= 1) {
      throw ArgumentError.value(windowSize, 'windowSize', 'must be > 1');
    }
    if (minPassingSignals < 1 || minPassingSignals > 4) {
      throw ArgumentError.value(
          minPassingSignals, 'minPassingSignals', 'must be in 1..4');
    }
    if (minHeadYVariance < 0 ||
        minHeadXVariance < 0 ||
        minEyeVariance < 0 ||
        minBboxJitter < 0) {
      throw ArgumentError(
          'min*Variance / minBboxJitter thresholds must be >= 0');
    }
  }

  PadConfig copyWith({
    bool? enabled,
    int? windowSize,
    double? minHeadYVariance,
    double? minHeadXVariance,
    double? minEyeVariance,
    double? minBboxJitter,
    int? minPassingSignals,
    bool? blockOnSpoof,
    bool? blockOnInconclusive,
    void Function(PadResult result)? onPadResult,
  }) {
    return PadConfig(
      enabled: enabled ?? this.enabled,
      windowSize: windowSize ?? this.windowSize,
      minHeadYVariance: minHeadYVariance ?? this.minHeadYVariance,
      minHeadXVariance: minHeadXVariance ?? this.minHeadXVariance,
      minEyeVariance: minEyeVariance ?? this.minEyeVariance,
      minBboxJitter: minBboxJitter ?? this.minBboxJitter,
      minPassingSignals: minPassingSignals ?? this.minPassingSignals,
      blockOnSpoof: blockOnSpoof ?? this.blockOnSpoof,
      blockOnInconclusive: blockOnInconclusive ?? this.blockOnInconclusive,
      onPadResult: onPadResult ?? this.onPadResult,
    );
  }

  /// The callback is intentionally omitted — it is not serializable.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'windowSize': windowSize,
      'minHeadYVariance': minHeadYVariance,
      'minHeadXVariance': minHeadXVariance,
      'minEyeVariance': minEyeVariance,
      'minBboxJitter': minBboxJitter,
      'minPassingSignals': minPassingSignals,
      'blockOnSpoof': blockOnSpoof,
      'blockOnInconclusive': blockOnInconclusive,
    };
  }

  /// Missing keys fall back to the constructor defaults (the callback can never
  /// be restored from a map, so it stays `null`). Every value is type-checked
  /// with `is` before use so a malformed dynamic map cannot throw a TypeError;
  /// well-typed but out-of-range values are still rejected by the constructor.
  factory PadConfig.fromMap(Map<String, dynamic> map) {
    double d(Object? v, double fallback) => v is num ? v.toDouble() : fallback;
    int i(Object? v, int fallback) => v is num ? v.toInt() : fallback;
    bool b(Object? v, bool fallback) => v is bool ? v : fallback;
    return PadConfig(
      enabled: b(map['enabled'], true),
      windowSize: i(map['windowSize'], 45),
      minHeadYVariance: d(map['minHeadYVariance'], 0.3),
      minHeadXVariance: d(map['minHeadXVariance'], 0.2),
      minEyeVariance: d(map['minEyeVariance'], 0.02),
      minBboxJitter: d(map['minBboxJitter'], 1.5),
      minPassingSignals: i(map['minPassingSignals'], 3),
      blockOnSpoof: b(map['blockOnSpoof'], true),
      blockOnInconclusive: b(map['blockOnInconclusive'], false),
    );
  }

  String toJson() => json.encode(toMap());

  factory PadConfig.fromJson(String source) =>
      PadConfig.fromMap(json.decode(source));

  /// The callback is excluded: closures are not reliably comparable.
  @override
  List<Object?> get props => [
        enabled,
        windowSize,
        minHeadYVariance,
        minHeadXVariance,
        minEyeVariance,
        minBboxJitter,
        minPassingSignals,
        blockOnSpoof,
        blockOnInconclusive,
      ];

  @override
  String toString() => 'PadConfig(enabled: $enabled, windowSize: $windowSize, '
      'minHeadYVariance: $minHeadYVariance, minHeadXVariance: $minHeadXVariance, '
      'minEyeVariance: $minEyeVariance, minBboxJitter: $minBboxJitter, '
      'minPassingSignals: $minPassingSignals, blockOnSpoof: $blockOnSpoof, '
      'blockOnInconclusive: $blockOnInconclusive)';
}
