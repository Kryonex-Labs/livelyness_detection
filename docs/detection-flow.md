# How liveness is decided

> **Summary (for AI):** How a camera frame becomes a passed gesture. Thresholds are evaluated
> inline in each screen's `_detect()`: `smile` = `smilingProbability > 0.75`, `turnLeft` =
> `headEulerAngleY > 45`, `turnRight` = `headEulerAngleY < -50` (**V1 wrongly uses `>`**), `blink`
> = two-phase debounce (eyes `< 0.25` then `< 0.75`). Roll/tilt is never read. Losing the face
> resets all steps; timeout → fail (or manual capture if `allowAfterMaxSec`); the overlay adds
> ~3s per step. Painters draw contours only, when `showFacialVertices` is on.

The functionality: how a camera frame becomes a passed/failed gesture and, eventually, a
captured selfie. Thresholds are evaluated **inline in each screen's `_detect()` method**
(`m7_livelyness_detection_screen.dart` V1, `..._screen_v2.dart` V2) — there is no shared
decision helper, so V1 and V2 differ (noted per-step below).

## Inputs read from each ML-Kit `Face`

- `leftEyeOpenProbability`, `rightEyeOpenProbability` (0..1) — need classification enabled.
- `headEulerAngleY` — yaw in degrees. **+ = head turned to user's left, − = right.**
- `smilingProbability` (0..1).
- `contours` — used only to draw the overlay, never for the pass/fail decision.

`headEulerAngleZ` (roll / tilt) is **never read** — there is no tilt gesture despite the name
sometimes suggesting one.

## Per-step decision

| Step | Passes when | V1 | V2 |
|---|---|---|---|
| `smile` | `smilingProbability > 0.75` | ✓ | ✓ |
| `turnLeft` | `headEulerAngleY > 45` | ✓ | ✓ |
| `turnRight` | `headEulerAngleY < -50` | **✗ uses `>` — auto-passes** | ✓ |
| `blink` | two-phase (below) | ✓ | ✓ |

V1 reads these from `LivelynessDetection.instance.thresholdConfig`; **V2 hardcodes them and
ignores your config** — so `configure(thresholds:)` only affects iOS.

### Blink is two-phase (a debounce, not open→close→open)

1. **Close** (in `_detect`): both eye-open probabilities `< 0.25` → set `_didCloseEyes = true`,
   start processing this step.
2. **Confirm** (next frames, in `_processImage`): while `_didCloseEyes`, if both probabilities
   `< 0.75` → complete the step.

The second phase confirms the eyes are *still fairly closed*, not that they re-opened — so it
debounces a single noisy frame rather than verifying a full blink. Good enough to gate the
step, but not a strong anti-spoof signal.

### No-face handling

Every frame with zero detected faces **resets all steps** to incomplete and jumps the overlay
back to step 0. Look away mid-flow and you start over.

### Dead anti-spoof signals

V2 computes eye/cheek/ear/mouth **symmetry**; V1 computes a face "golden ratio". Both are only
`print`ed in debug — neither gates pass/fail. Real anti-spoofing was stubbed and never wired.

## Step sequencing (the overlay)

`LivelynessDetectionStepOverlay` (`components/m7_livelyness_detection_steps_overlay.dart`) owns
the sequence, driven by both screens via a `GlobalKey`:

- On a passed step, `nextPage()` runs `500ms delay → 500ms page animation → 2s wait`, then
  advances. So each transition costs **~3s regardless of user speed** — total flow ≥ `3s ×
  steps`. Card transitions use `animate_do` (`ZoomIn`/`FadeInRight` in, `ZoomOut`/`FadeOutLeft`
  out). The `PageView` is wrapped in `AbsorbPointer` so users can't swipe manually.
- After the last step, `onCompleted()` fires → capture.

## Timeout and capture

A single `Timer(seconds: config.maxSecToDetect)` runs per session:

- **Timed out, `allowAfterMaxSec == false`** → pop `null` (failure).
- **Timed out, `allowAfterMaxSec == true`** → reveal a manual capture button
  (`Icons.camera_alt`, tinted `captureButtonColor`); tapping it captures with
  `didCaptureAutomatically: false`.
- **All steps passed** → 500ms later, auto-capture with `didCaptureAutomatically: true`.

Capture differs by screen: V1 `stopImageStream()` + `takePicture()` → `XFile`; V2
`_cameraState.when(onPhotoMode: takePhoto())`. Both then `Navigator.pop` a `CapturedImage`, or
`null` if the user hit the close button.

## Overlay painters

Only drawn when `config.showFacialVertices == true`. Both painters render **`Face.contours`
only** — connected line segments plus optional dots. Neither draws a bounding box or
`Face.landmarks`. The bounding-box/mesh idea survives only as a commented-out `MeshPainter`.

- **V1** `FaceDetectorPainter` — maps points via `MathHelper.translateX/Y`; contours as open
  polylines.
- **V2** `AndroidFaceDetectorPainter` — maps points via `_croppedPosition`; contours as closed
  polygons, optionally dashed; applies an Android-only canvas mirror/rotation transform to
  correct the non-mirrored analysis image (iOS skips it).

The iOS/Android coordinate difference (a width/height swap at 90°/270° rotation) is implemented
**twice** with the same intent but different code — once in `MathHelper` (V1) and once in
`_croppedPosition` (V2).
