import 'package:livelyness_detection/index.dart';

/// Result returned by [LivelynessDetection.detect] when a selfie is captured.
class CapturedImage {
  /// Absolute file path of the captured selfie on disk.
  final String imgPath;

  /// `true` when the picture was captured automatically after every step was
  /// verified, `false` when the user tapped the manual capture-button fallback.
  final bool didCaptureAutomatically;

  /// The liveness steps that were successfully verified before capture.
  final List<LivelynessStep> completedSteps;

  CapturedImage({
    required this.imgPath,
    required this.didCaptureAutomatically,
    this.completedSteps = const [],
  });

  /// Deletes the captured selfie file from disk.
  ///
  /// The captured image is biometric data written as an unencrypted JPEG to the
  /// app's temporary directory; the package never deletes it for you. Call this
  /// as soon as the file is no longer needed (e.g. after uploading it for
  /// server-side verification) so it does not linger on the device.
  ///
  /// Safe to call when the file is already gone. Returns `true` if a file was
  /// deleted, `false` if nothing was there.
  Future<bool> delete() async {
    if (imgPath.isEmpty) return false;
    // No exists()-then-delete() TOCTOU: delete directly and treat a missing
    // file as a no-op success rather than letting it throw.
    try {
      await File(imgPath).delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  CapturedImage copyWith({
    String? imgPath,
    bool? didCaptureAutomatically,
    List<LivelynessStep>? completedSteps,
  }) {
    return CapturedImage(
      imgPath: imgPath ?? this.imgPath,
      didCaptureAutomatically:
          didCaptureAutomatically ?? this.didCaptureAutomatically,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'imgPath': imgPath,
      'didCaptureAutomatically': didCaptureAutomatically,
      'completedSteps': completedSteps.map((e) => e.index).toList(),
    };
  }

  factory CapturedImage.fromMap(Map<String, dynamic> map) {
    return CapturedImage(
      imgPath: map['imgPath'] ?? '',
      didCaptureAutomatically: map['didCaptureAutomatically'] ?? false,
      completedSteps: ((map['completedSteps'] as List?) ?? [])
          .map((e) => (e is int && e >= 0 && e < LivelynessStep.values.length)
              ? LivelynessStep.values[e]
              : null)
          .whereType<LivelynessStep>()
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CapturedImage.fromJson(String source) =>
      CapturedImage.fromMap(json.decode(source));

  // Path is deliberately redacted: it points at an unencrypted biometric JPEG
  // and must not leak into logs. Use [imgPath] directly when you need it.
  @override
  String toString() =>
      'CapturedImage(imgPath: <redacted>, didCaptureAutomatically: $didCaptureAutomatically, completedSteps: $completedSteps)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CapturedImage &&
        other.imgPath == imgPath &&
        other.didCaptureAutomatically == didCaptureAutomatically;
  }

  @override
  int get hashCode => imgPath.hashCode ^ didCaptureAutomatically.hashCode;
}
