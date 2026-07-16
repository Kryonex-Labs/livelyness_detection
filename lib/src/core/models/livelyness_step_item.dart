import 'package:livelyness_detection/index.dart';

class LivelynessStepItem {
  //enum
  final LivelynessStep step;
  final String title;
  final double? thresholdToCheck;
  final bool isCompleted;
  final Color? detectionColor;

  LivelynessStepItem({
    required this.step,
    required this.title,
    required this.isCompleted,
    this.thresholdToCheck,
    this.detectionColor,
  });

  LivelynessStepItem copyWith({
    LivelynessStep? step,
    String? title,
    double? thresholdToCheck,
    bool? isCompleted,
    Color? detectionColor,
  }) {
    return LivelynessStepItem(
      step: step ?? this.step,
      title: title ?? this.title,
      thresholdToCheck: thresholdToCheck ?? this.thresholdToCheck,
      isCompleted: isCompleted ?? this.isCompleted,
      detectionColor: detectionColor ?? this.detectionColor,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'step': step.index});
    result.addAll({'title': title});
    if (thresholdToCheck != null) {
      result.addAll({'thresholdToCheck': thresholdToCheck});
    }
    result.addAll({'isCompleted': isCompleted});
    if (detectionColor != null) {
      result.addAll({'detectionColor': detectionColor!.toARGB32()});
    }

    return result;
  }

  factory LivelynessStepItem.fromMap(Map<String, dynamic> map) {
    return LivelynessStepItem(
      step: LivelynessStep.values[map['step'] ?? 0],
      title: map['title'] ?? '',
      thresholdToCheck: map['thresholdToCheck']?.toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      detectionColor:
          map['detectionColor'] != null ? Color(map['detectionColor']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LivelynessStepItem.fromJson(String source) =>
      LivelynessStepItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LivelynessStepItem(step: $step, title: $title, thresholdToCheck: $thresholdToCheck, isCompleted: $isCompleted, detectionColor: $detectionColor)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LivelynessStepItem &&
        other.step == step &&
        other.title == title &&
        other.thresholdToCheck == thresholdToCheck &&
        other.isCompleted == isCompleted &&
        other.detectionColor == detectionColor;
  }

  @override
  int get hashCode {
    return step.hashCode ^
        title.hashCode ^
        thresholdToCheck.hashCode ^
        isCompleted.hashCode ^
        detectionColor.hashCode;
  }
}
