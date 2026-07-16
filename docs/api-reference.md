# API reference (consumer-facing)

> **Summary (for AI):** The supported public contract. Import
> `package:livelyness_detection/livelyness_detection.dart` (**not** `index.dart`).
> `LivelynessDetection.instance.detectLivelyness(context, {required config})` → `CapturedImage?`
> is the main call; `configure({thresholds, style...})` sets overlay style + thresholds (thresholds
> affect iOS/V1 only). Config types: `DetectionConfig`, `LivelynessStepItem`, `LivelynessStep`
> enum, and `DetectionThreshold` subtypes — all with defaults listed below.

Import:

```dart
import 'package:livelyness_detection/livelyness_detection.dart';
```

## `LivelynessDetection` (singleton)

`LivelynessDetection.instance` — the only accessor (private constructor).

### `detectLivelyness` — the main call

```dart
Future<CapturedImage?> detectLivelyness(
  BuildContext context, {
  required DetectionConfig config,
})
```

Pushes the platform-specific capture screen (iOS → V1, else → V2) and returns the captured
image, or `null` if the user cancels or times out without a capture.
`context` is used both to read safe-area padding and to `Navigator.push`.

### `configure` — optional one-time styling + thresholds

```dart
void configure({
  required List<DetectionThreshold> thresholds,
  Color lineColor    = const Color(0xffab48e0),
  Color dotColor     = const Color(0xffab48e0),
  double lineWidth   = 1.6,
  double dotSize     = 2.0,
  bool displayLines  = true,
  bool displayDots   = true,
  List<double>? dashValues, // [dashLength, dashGap], length must be 2
})
```

Sets the facial-vertex overlay style and the detection thresholds. Only **V1 (iOS)** honours
`thresholds`; V2 ignores them. Has a latent assert bug — see [known-issues.md](known-issues.md).
Call once (e.g. in `initState`) before `detectLivelyness`.

## `DetectionConfig` — per-run config

```dart
DetectionConfig({
  required List<LivelynessStepItem> steps, // asserts non-empty
  bool startWithInfoScreen = false,         // show intro screen first
  int  maxSecToDetect      = 15,            // timeout for the whole flow (seconds)
  bool allowAfterMaxSec    = false,         // after timeout, allow manual capture instead of failing
  bool showFacialVertices  = false,         // draw the contour overlay
  Color? captureButtonColor,                // tint of the manual-capture button
})
```

## `LivelynessStepItem` — one challenge step

```dart
LivelynessStepItem({
  required LivelynessStep step,
  required String title,        // instruction shown to the user
  required bool isCompleted,    // pass false; the flow flips it
  double? thresholdToCheck,     // loose per-step override (unrelated to DetectionThreshold classes)
  Color?  detectionColor,       // overlay tint for this step
})
```

## `LivelynessStep` — the four gestures

```dart
enum LivelynessStep { blink, turnLeft, turnRight, smile }
```

## `DetectionThreshold` subtypes (V1 only)

Passed to `configure(thresholds: [...])`. Defaults:

| Class | Param(s) | Default | Meaning |
|---|---|---|---|
| `SmileDetectionThreshold` | `probability` | `0.75` | min ML-Kit smile confidence |
| `BlinkDetectionThreshold` | `leftEyeProbability`, `rightEyeProbability` | `0.25` each | eye-open prob below which the eye is "closed" |
| `HeadTurnDetectionThreshold` | `rotationAngle` | `45.0` | head-yaw angle to pass; **+ = left, − = right** |

> The range asserts on all three are no-ops (`||` where `&&` was meant), so out-of-range
> values pass silently. See [known-issues.md](known-issues.md).

## `CapturedImage` — the result

```dart
class CapturedImage {
  final String imgPath;                 // file path of the captured selfie
  final bool   didCaptureAutomatically; // true = auto-captured on success, false = manual button
}
```

`detectLivelyness` returns `CapturedImage?`; read `.imgPath` (e.g. `Image.file(File(result.imgPath))`).

## Also exported, but not the supported contract

Exported via the `src` barrel but internal: `LivelynessDetectionScreenV1/V2`,
`LivelynessDetectionPageV2`, `LivelynessDetectionStepOverlay`, `PreviewDecoratorWidget`,
`FaceDetectionModel`, `MLHelper`, `MathHelper`, the two painters, and the dead
`platform_interface` / `method_channel` pair. `LivelynessInfoWidget({onStartTap})` is the one
borderline-useful widget if you want to reuse the intro screen.
