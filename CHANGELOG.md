## 2.0.1

### Docs

- Rewrote README with full configuration reference (all `DetectionConfig`, `DetectionThreshold`, `OvalConfig`, `CameraConfig`, `StepCardStyle`, `InfoScreenConfig` parameters documented).
- Updated code example to v2 API (`LivelynessDetection.detect()`).
- Replaced broken Lottie iframes with clean platform support table.
- New demo gif.

## 2.0.0

### Breaking changes

- **API**: Dropped singleton pattern. `LivelynessDetection.detect(context:, config:)` replaces `LivelynessDetection.instance.detectLivelyness()` + `configure()`.
- **Config**: All configuration (thresholds, contour styling, UI colors) moved into `DetectionConfig`. The `configure()` method no longer exists.
- **Unified screen**: Removed platform-specific V1 (iOS) and V2 (Android) screens. One screen for both platforms using the `camera` plugin.
- **Dependencies dropped**: `camerawesome`, `rxdart`, `path_provider`, `image` removed.
- **Model rename**: `caputred_image.dart` → `captured_image.dart`.
- **Result type**: `CapturedImage` now includes `completedSteps` and a `delete()` method for biometric data cleanup.

### New features

- **Modern UI**: Full-bleed camera with frosted oval face guide, animated progress ring, glassmorphic step cards, dark info screen with gradient CTA.
- **`InfoScreenConfig`**: Customise title, subtitle, guidance items, button text, background/button gradients, and Lottie asset.
- **`OvalConfig`**: Control oval width fraction, aspect ratio, vertical offset, blur sigma, ring stroke width, ring track color, and ring padding.
- **`CameraConfig`**: Set resolution preset, preferred lens direction, and max detection FPS for low-end devices.
- **`StepCardStyle`**: Style the glassmorphic step card (background, border, radius, text style, icon color).
- **Callbacks**: `onStepCompleted`, `onFaceDetected`, `onTimeout`, `onComplete` for analytics and telemetry.
- **`routeBuilder`**: Supply a custom `PageRoute` for the detection flow (e.g. slide-up, bottom sheet).
- **Double-launch guard**: Concurrent calls to `detect()` return `null` instead of pushing duplicate routes.

### Fixes

- **Face mesh alignment**: Contour vertices now render inside the same coordinate transform as the camera preview, fixing drift caused by `BoxFit.cover` scaling.
- **Blink detection**: Changed from single-threshold to close-then-reopen state machine, eliminating false positives and deadlocks.
- **Turn right detection**: Fixed sign bug that triggered on neutral head position.
- **Camera lifecycle**: Proper `WidgetsBindingObserver` handling — pauses timer and disposes controller on inactive, restarts on resume.
- **Re-entrancy guard**: Generation-token pattern prevents permission-dialog / app-lifecycle races from clobbering the camera controller.
- **Capture retry**: Up to 2 retries on `CameraException` during `takePicture`, with graceful fallback to pop.
- **Callback safety**: All consumer callbacks wrapped in `_safeInvoke` — a throw never breaks the detection flow or hangs `detect()`.
- **Steps deep-copied**: Caller's step list is no longer mutated; a second `detect()` with the same config starts fresh.

### Dependencies updated

- `google_mlkit_face_detection`: `^0.11.0` → `^0.15.1`
- `camera`: `^0.11.0+1` → `^0.12.2`
- `animate_do`: `^3.3.4` → `^5.1.0`
- `equatable`: `^2.0.5` → `^3.0.0`
- `lottie`: `^3.1.2` → `^3.8.2`
- `collection`: `^1.17.0` → `^1.19.1`
- `uuid`: `^4.4.2` → `^4.6.0`
- `plugin_platform_interface`: `^2.1.3` → `^2.1.8`
- `flutter_lints`: `^4.0.0` → `^6.0.0`

### Example app

- Redesigned: dark futuristic theme with collapsible config sections.
- Interactive controls for every configuration option (sliders, color chips, text fields, dropdowns).
- Real-time event log panel showing callback firings.

### Housekeeping

- Android build tooling: Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0.
- SDK constraint: `flutter: '>=3.22.0'`, `sdk: '>=3.4.3 <4.0.0'`.
- Repository URLs updated to `Kryonex-Labs/livelyness_detection`.
- Removed dead `MeshPainter` code and unused barrel exports.
- Biometric privacy dartdocs on `onFaceDetected`, `onComplete`, and `CapturedImage`.

## 0.0.1+5

Updates:

- Updated versions of the below-mentioned dependencies:
  - `camerawesome: ^2.0.1` -> `camerawesome: ^2.1.0`
  - `rxdart: ^0.27.7` -> `rxdart: ^0.28.0`

## 0.0.1+4

Updates:

- Renamed classes
- Re-do gif demo
- Added show facial vertices to example app

## 0.0.1+3

- Updates:

  - Updated README.md
  - Added `SECURITY.md` to report security vulnerabilities
  - Added `CODE_OF_CONDUCT.md` to maintain a healthy community
  - Added `CONTRIBUTING.md` to guide contributors
  - Added `PULL_REQUEST_TEMPLATE.md` to guide contributors

- Issues Addressed/Fixed:
  - [Head Turn Right](https://github.com/GhagSagar23/livelyness_detection/issues/8)

## 0.0.1+2

- hideFacialVertices config, front-camera, demo and updated README.md

## 0.0.1+1

- Updated README.md

## 0.0.1

Initial Release.
