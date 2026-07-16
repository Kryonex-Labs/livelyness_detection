# Known issues & footguns

> **Summary (for AI):** Confirmed bugs/footguns to work around. Top bugs: V1 `turnRight` uses `>`
> (auto-passes on iOS); V2 ignores configured thresholds; `configure(dashValues:)` asserts the
> wrong variable; all three `DetectionThreshold` range asserts use `||` and are no-ops. Plus dead
> code (`platform_interface`/`method_channel`, `camera_preview.dart`), **load-bearing misspellings**
> (`Livelyness`, `caputred_image.dart`, `ml_kit_extesion.dart` — do NOT rename), and doc drift.

All confirmed against the source during analysis. Ordered by how likely they are to bite.

## Real bugs

- **V1 `turnRight` never requires a turn.** `m7_livelyness_detection_screen.dart:423` uses
  `headEulerAngleY > -50` where it should be `< -50`. A forward-facing head (yaw ≈ 0) satisfies
  `0 > -50`, so the step auto-completes instantly on iOS. V2 has the correct `< -50`.

- **V2 ignores configured thresholds.** V2 hardcodes `0.25 / 45 / -50 / 0.75` inline and never
  reads `LivelynessDetection.instance.thresholdConfig`. `configure(thresholds: ...)` therefore
  only affects iOS (V1). Configurability regressed between the two screens.

- **`configure(dashValues:)` validates the wrong variable.** The length-must-be-2 assert
  (`livelyness_detection.dart:115-118`) checks the *old* `_dashValues` field instead of the
  incoming `dashValues` parameter — and the parameter is never assigned into `_dashValues` in
  the shown body. The validation is a no-op against the argument.

- **Threshold range asserts are no-ops.** All three `DetectionThreshold` subtypes assert with
  `||` where `&&` was intended, e.g. `probability < 1.0 || probability > 0.0` — always true.
  Out-of-range probabilities/angles pass silently. (`detection_threshold.dart:22-25`, `:96-103`,
  `:175-178`.)

- **Threshold deserialization defaults disagree with constructor defaults.** Every
  `fromMap`/`fromDict` defaults a missing key to `0.0`, not `0.75`/`0.25`/`45.0`. Round-tripping
  an empty map yields all-zero thresholds.

## Behaviour to be aware of (not strictly bugs)

- **Hard iOS-vs-else platform split** (`livelyness_detection.dart:85`). Web/desktop fall through
  to the camerawesome V2 path, which may not be supported there.
- **Blink only debounces, doesn't verify a re-open** — see [detection-flow.md](detection-flow.md).
- **~3s of fixed delay per step** in the overlay, regardless of how fast the user is.
- **Any lost-face frame resets the whole flow** to step 0.
- **`use_build_context_synchronously` is ignored** at the top of V1; `Navigator` is used after
  awaits without `mounted` checks.
- **V1 has no double-completion guard** (V2 has `_isCompleted`), so a timeout racing a manual
  pop could pop the route twice.

## Dead code (safe to delete)

- `livelyness_detection_platform_interface.dart` + `livelyness_detection_method_channel.dart` —
  untouched `flutter create --template=plugin` boilerplate (`getPlatformVersion`). No
  `flutter: plugin:` block exists, so the method channel is never registered natively; calling
  it would `MissingPluginException`. Only referenced by their own `index.dart` re-exports. The
  `plugin_platform_interface` dependency is the only remaining vestige.
- `camera_preview.dart` (`CACameraPreview`) — returns `const Placeholder()`, referenced nowhere.
- `livelyness-success` and `step_completed` Lottie assets — declared in `pubspec.yaml`/
  `asset_constants.dart` but never rendered. Only `livelyness-start` (info screen) is used.
- Commented-out `MeshPainter` (`face_detector_painter.dart:111-310`) — "kept for future release".
- `example/lib/screens/test.dart` (`TestScreen`) — not exported, unreachable.

## Naming — load-bearing, do NOT rename casually

Renaming any of these is a breaking change to the pub package or the export graph:

- Package/symbol `Livelyness` — misspelling of *liveliness*, in the pub name and every symbol.
- `caputred_image.dart` — should be `captured_image.dart` (`CapturedImage` class is spelled
  correctly; only the filename is wrong).
- `ml_kit_extesion.dart` — missing an `n`.
- `CapturedImage.toString()` prints `CaptureImage(...)` (drops the `d`) — cosmetic.

## Docs / metadata drift

- `README.md` code sample shows `detectLivelyness` returning `String?`; the real API returns
  `CapturedImage?`.
- Version uses build-metadata `+N` as a patch counter (base stayed `0.0.1` through `0.0.1+5`);
  `+N` won't order as a real patch bump on pub.dev.
- `Equatable` is dead weight: `DetectionThreshold` extends it but `props` is always `[]` and
  every model hand-rolls `==`/`hashCode`.
