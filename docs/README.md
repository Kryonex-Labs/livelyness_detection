# livelyness_detection — docs

> **Summary (for AI):** Docs index for a Flutter **face-liveness** package (blink/turn/smile
> gestures → capture a selfie). Pure Dart; camera + face detection come from the `camera`,
> `camerawesome`, `google_mlkit_face_detection` plugins. Entry point:
> `LivelynessDetection.instance.detectLivelyness(context, config:)`. Ships **two platform
> screens** (iOS = V1, else = V2) that diverge in behaviour — see the doc map and known-issues.

Flutter package for **face-liveness detection**: prove a real person is in front of the
camera by making them complete gestures (blink / turn left / turn right / smile) before a
selfie is captured. Pure-Dart package — no native code of its own; camera + face detection
come from the `camera`, `camerawesome`, and `google_mlkit_face_detection` plugins.

> Note: "livelyness" is a permanent misspelling of *liveliness*, baked into the pub package
> name and every public symbol. Don't "fix" it — it's a breaking rename. See
> [known-issues.md](known-issues.md).

## 30-second usage

```dart
import 'package:livelyness_detection/livelyness_detection.dart';

final CapturedImage? result = await LivelynessDetection.instance.detectLivelyness(
  context,
  config: DetectionConfig(
    steps: [
      LivelynessStepItem(step: LivelynessStep.blink, title: 'Blink', isCompleted: false),
      LivelynessStepItem(step: LivelynessStep.smile, title: 'Smile', isCompleted: false),
    ],
    startWithInfoScreen: true,
    maxSecToDetect: 30,
  ),
);
if (result != null) showImage(result.imgPath); // null = user cancelled / timed out
```

Import `package:livelyness_detection/livelyness_detection.dart` — **not** `index.dart` (that's
the internal barrel and does not export the `LivelynessDetection` class).

## Doc map

| File | Answers |
|------|---------|
| [architecture.md](architecture.md) | How the code is organised; the frame→detect→capture pipeline; iOS (V1) vs Android (V2). |
| [api-reference.md](api-reference.md) | Every consumer-facing symbol, param, and default. |
| [detection-flow.md](detection-flow.md) | How each gesture is actually decided (thresholds, blink two-phase, timeout, painters). |
| [known-issues.md](known-issues.md) | Confirmed bugs, dead code, and footguns to work around. |
| [versions.md](versions.md) | SDK / Flutter / FVM pins, dependency table, version-bump history. |

## The one thing to know

The package ships **two detection screens** and picks by platform: **iOS → V1** (`camera`
plugin), **everything else → V2** (`camerawesome`). They diverge in real ways — V2 ignores the
configured thresholds and V1's "turn right" check is broken. Read
[known-issues.md](known-issues.md) before relying on either.
