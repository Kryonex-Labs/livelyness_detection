# Architecture

> **Summary (for AI):** Code layout + the frame→`InputImage`→`FaceDetector`→`_detect()`→capture
> pipeline. Pure-Dart package (no native code, no `flutter: plugin:` block); native comes from
> plugins. **iOS → V1** (`camera`, shared `MLHelper`, thresholds configurable); **Android/other →
> V2** (`camerawesome`, own detector, thresholds hardcoded). Gesture logic is inline in each
> screen's `_detect()` — no shared helper, so V1/V2 diverge.

## What runs where

Pure-Dart Flutter package. No `android/` or `ios/` folders and **no `flutter: plugin:` block
in `pubspec.yaml`** — so it's a plain package, not a federated plugin. All native work is
borrowed from pub plugins:

- `google_mlkit_face_detection` — the actual face detector (landmarks, contours, eye-open /
  smile probabilities, head Euler angles).
- `camera` — camera feed for the **iOS** screen (V1).
- `camerawesome` — camera feed for the **Android/other** screen (V2).

## Module map

```
lib/
  livelyness_detection.dart        ← CONSUMER ENTRY. Defines LivelynessDetection singleton.
  index.dart                       ← internal fat barrel (re-exports every 3rd-party dep). NOT for consumers.
  livelyness_detection_platform_interface.dart  ┐ dead flutter-create plugin template
  livelyness_detection_method_channel.dart       ┘ (getPlatformVersion) — never called. See known-issues.
  src/
    core/
      constants/    string + asset-path constants
      enums/        LivelynessStep { blink, turnLeft, turnRight, smile }
      models/       DetectionConfig, DetectionThreshold(+3 subtypes), LivelynessStepItem,
                    FaceDetectionModel, CapturedImage
      helpers/      MLHelper (FaceDetector wrapper), MathHelper (coord mapping), Utils (uuid, midpoint)
      extensions/   ml_kit_extesion (AnalysisImage→InputImage), num/list helpers
      custom_painters/  FaceDetectorPainter (V1 overlay), AndroidFaceDetectorPainter (V2 overlay)
    screens/
      m7_livelyness_detection_screen.dart      LivelynessDetectionScreenV1  (iOS, camera plugin)
      m7_livelyness_detection_screen_v2.dart   LivelynessDetectionPageV2/ScreenV2 (Android, camerawesome)
      camera_preview.dart                      dead stub (returns Placeholder). See known-issues.
      components/  steps_overlay (step state machine), info_widget (intro), detection_widget (V2 overlay host)
```

Everything under `src/` reaches consumers because `livelyness_detection.dart` does
`export './src/index.dart'`. It's public API surface even though most of it (screens,
painters, helpers) is internal — treat only the symbols in [api-reference.md](api-reference.md)
as the supported contract.

## Import / barrel structure

Two entry points with **asymmetric** surfaces — this trips people up:

- `livelyness_detection.dart` → the `LivelynessDetection` class + all `src/` types. **Use this.**
- `index.dart` → all third-party re-exports + `src/`, but **not** the `LivelynessDetection`
  class. Importing `index.dart` alone gives you the models but not the entry point.

`livelyness_detection.dart` *imports* (not exports) `index.dart`, so third-party packages are
internal plumbing, not re-exposed to consumers.

## Detection pipeline (end to end)

```
detectLivelyness(context, config)
  └─ Navigator.push → platform screen (iOS: V1 / else: V2)
       └─ camera frame stream
            └─ frame → InputImage
                 │   V1: CameraImage bytes → InputImage.fromBytes
                 │   V2: AnalysisImage → .toInputImage()  (ml_kit_extesion.dart)
            └─ MLHelper / FaceDetector.processImage → List<Face>   (3× retry on empty)
                 └─ no face? → reset all steps
                 └─ face? → _detect(face, currentStep)
                      └─ gesture threshold met? → mark step done → overlay.nextPage()
                           └─ last step done → onCompleted → take picture
                                └─ Navigator.pop(CapturedImage(imgPath, didCaptureAutomatically))
```

The gesture thresholds live **inline in each screen's `_detect()` method**, not in a shared
helper — which is why V1 and V2 can (and do) disagree. See [detection-flow.md](detection-flow.md).

## V1 vs V2

| Concern | V1 (iOS) | V2 (Android/other) |
|---|---|---|
| Camera plugin | `camera` (`CameraController`) | `camerawesome` (`CameraAwesomeBuilder.custom`) |
| Face detector | shared `MLHelper.instance` | its **own** `FaceDetector` instance |
| Frame → InputImage | manual `InputImage.fromBytes` | `AnalysisImage.toInputImage()` (NV21, w=250, 30fps) |
| Overlay painter | `FaceDetectorPainter` (open polylines) | `AndroidFaceDetectorPainter` (closed polygons, optional dash) |
| Thresholds source | `LivelynessDetection.instance.thresholdConfig` (configurable) | **hardcoded inline** (config ignored) |
| `turnRight` check | `> -50` **(bug — auto-passes)** | `< -50` (correct) |
| Double-pop guard | `_isTakingPicture` (capture only) | `_isCompleted` flag |
| Preview | camera preview drawn twice with `BackdropFilter` blur | single camerawesome preview |

Shared between both: the `DetectionConfig`, the step-overlay state machine, the `maxSecToDetect`
timeout behaviour, the info screen, the close/cancel button, and the manual-capture button that
appears after timeout when `allowAfterMaxSec` is true.
