# livelyness_detection

![](https://img.shields.io/pub/publisher/livelyness_detection) ![](https://img.shields.io/github/issues-raw/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/languages/count/GhagSagar23/livelyness_detection)
![](https://img.shields.io/pub/likes/livelyness_detection) ![](https://img.shields.io/pub/points/livelyness_detection) ![](https://img.shields.io/pub/popularity/livelyness_detection) ![](https://img.shields.io/pub/v/livelyness_detection)
![](https://img.shields.io/github/directory-file-count/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/repo-size/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/commit-activity/w/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/contributors/GhagSagar23/livelyness_detection)

## Index

- [What is Livelyness Detection?](#what-is-livelyness-detection)
- [Platform Support](#platform-support)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [DetectionConfig](#detectionconfig)
  - [LivelynessStep & LivelynessStepItem](#livelynessstep--livelynessstepitem)
  - [DetectionThreshold](#detectionthreshold)
  - [OvalConfig](#ovalconfig)
  - [CameraConfig](#cameraconfig)
  - [StepCardStyle](#stepcardstyle)
  - [InfoScreenConfig](#infoscreenconfig)
- [Privacy & Biometric Data](#privacy--biometric-data)
- [Contributors](#contributors)

## What is Livelyness Detection?

Liveness detection for face recognition in biometrics is a technique where an algorithm detects if the person in front of the camera is alive and real. The algorithm is able to recognize a live person from presentation attacks - where a bad actor uses someone else's physical characteristics or biometric data (known as "spoofs") for impersonation.

`Spoofing` attempts using printed photos, recordings, deep fake pictures, and 3D masks poses a serious threat. `Facial Liveness Detection` incorporates specialized features to identify biometric spoofing attacks. Even though face recognition can reliably answer "Is this the right person?", it cannot answer "Is this a live person?" This is where liveness detection plays a significant role in fraud detection and mitigation.

## Platform Support

| iOS | Android | MacOS | Web | Linux | Windows |
| :-: | :-----: | :---: | :-: | :---: | :-----: |
| ✅  |   ✅    |  ❌   | ❌  |  ❌   |   ❌    |

## Installation

#### Flutter Setup

Add `livelyness_detection` to your `pubspec.yaml` dependencies.

```sh
flutter pub add livelyness_detection
```

#### Native Setup

<details>
  <summary>iOS</summary>

1. Open the `ios/Runner/Info.plist` file and add the camera usage description inside the `<dict>` tag:

```xml
<key>NSCameraUsageDescription</key>
<string>Used to verify you are a live person.</string>
```

> The camera runs with audio disabled, so no `NSMicrophoneUsageDescription` is required. Use a purpose-specific string: App Review rejects vague copy.

2. Open the `ios/Runner/Podfile` and set the platform:

```ruby
platform :ios, '14.0'
```

3. Set the deployment target in the Xcode project accordingly.

</details>

<details>
  <summary>Android</summary>

1. Set `minSdkVersion` to `21` in `android/app/build.gradle`.
2. Add the camera permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

</details>

## Usage

```dart
final CapturedImage? result = await LivelynessDetection.detect(
  context: context,
  config: DetectionConfig(
    steps: [
      LivelynessStepItem(
        step: LivelynessStep.blink,
        title: "Blink",
        isCompleted: false,
      ),
      LivelynessStepItem(
        step: LivelynessStep.smile,
        title: "Smile",
        isCompleted: false,
      ),
    ],
    startWithInfoScreen: true,
  ),
);
```

The returned `CapturedImage` contains:
- `imgPath` - path to the captured JPEG
- `didCaptureAutomatically` - whether the capture was auto-triggered
- `completedSteps` - list of steps the user completed

### Demo

<img width="480" alt="Livelyness Detection Demo" src="https://github.com/user-attachments/assets/c2b967ea-a5bd-467c-98e3-2b1676abac14" />

## Configuration

### DetectionConfig

The main configuration object passed to `LivelynessDetection.detect()`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `steps` | `List<LivelynessStepItem>` | **required** | Ordered list of liveness challenges the user must complete. |
| `thresholds` | `List<DetectionThreshold>?` | `null` | Custom sensitivity thresholds per detection type. Uses built-in defaults when `null`. |
| `startWithInfoScreen` | `bool` | `false` | Show an instructional screen before detection begins. |
| `maxSecToDetect` | `int` | `15` | Timeout in seconds. Detection ends after this duration. |
| `allowAfterMaxSec` | `bool` | `false` | If `true`, returns the captured image even on timeout. If `false`, returns `null`. |
| `showFacialVertices` | `bool` | `false` | Render raw face mesh vertices on the camera preview (debug). |
| `displayLines` | `bool` | `true` | Draw face contour lines on the preview. |
| `displayDots` | `bool` | `true` | Draw face contour dots on the preview. |
| `contourLineColor` | `Color` | `#EAEAEA` | Color of the face contour lines. |
| `contourDotColor` | `Color` | `#EAEAEA` | Color of the face contour dots. |
| `contourLineWidth` | `double` | `1.6` | Width of contour lines. |
| `contourDotRadius` | `double` | `2.0` | Radius of contour dots. |
| `dashValues` | `List<double>?` | `null` | Dash pattern for contour lines. Solid line when `null`. |
| `captureButtonColor` | `Color?` | `null` | Color of the manual capture button. |
| `overlayColor` | `Color` | `0xCC000000` | Color of the area outside the face oval. |
| `progressColor` | `Color` | `0xFF4CD964` | Color of the progress ring around the oval. |
| `stepCardStyle` | `StepCardStyle?` | `null` | Styling for the step instruction card. |
| `ovalConfig` | `OvalConfig?` | `null` | Shape and size of the face oval guide. |
| `cameraConfig` | `CameraConfig?` | `null` | Camera resolution, lens, and FPS. |
| `infoScreenConfig` | `InfoScreenConfig?` | `null` | Content for the info screen (when `startWithInfoScreen` is `true`). |
| `routeBuilder` | `Route Function(Widget)?` | `null` | Custom route transition. Uses `MaterialPageRoute` when `null`. |

#### Callbacks

| Callback | Signature | Description |
|----------|-----------|-------------|
| `onStepCompleted` | `void Function(LivelynessStep)` | Fired each time a step is completed. |
| `onFaceDetected` | `void Function(FaceDetectionModel)` | Fired on every frame where a face is detected. |
| `onTimeout` | `void Function()` | Fired when `maxSecToDetect` is reached. |
| `onComplete` | `void Function(CapturedImage)` | Fired when all steps complete and the image is captured. |

### LivelynessStep & LivelynessStepItem

`LivelynessStep` is an enum defining the available challenges:

| Step | Description |
|------|-------------|
| `blink` | User must blink both eyes. |
| `turnLeft` | User must turn head to the left. |
| `turnRight` | User must turn head to the right. |
| `smile` | User must smile. |

Wrap each step in a `LivelynessStepItem`:

```dart
LivelynessStepItem(
  step: LivelynessStep.blink,
  title: "Blink your eyes",  // displayed to the user
  isCompleted: false,         // always start as false
  detectionColor: Colors.green, // optional: color when this step completes
)
```

### DetectionThreshold

Fine-tune sensitivity per detection type. Pass these in `DetectionConfig.thresholds`.

#### SmileDetectionThreshold

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `probability` | `0.75` | 0.0 - 1.0 | Minimum smile probability to register. Lower = more sensitive. |

#### BlinkDetectionThreshold

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `leftEyeProbability` | `0.25` | 0.0 - 1.0 | Left eye open probability **below** which a blink is registered. |
| `rightEyeProbability` | `0.25` | 0.0 - 1.0 | Right eye open probability **below** which a blink is registered. |

#### HeadTurnDetectionThreshold

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `rotationAngle` | `45.0` | 0 - 180 | Minimum head rotation angle (degrees) to register a turn. |

```dart
DetectionConfig(
  steps: [...],
  thresholds: [
    SmileDetectionThreshold(probability: 0.6),
    BlinkDetectionThreshold(
      leftEyeProbability: 0.3,
      rightEyeProbability: 0.3,
    ),
    HeadTurnDetectionThreshold(rotationAngle: 30.0),
  ],
)
```

### OvalConfig

Controls the face guide oval overlay.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `widthFraction` | `0.72` | Oval width as fraction of screen width. |
| `aspectRatio` | `1.32` | Height-to-width ratio of the oval. |
| `verticalOffsetFraction` | `-0.06` | Vertical offset (-1.0 to 1.0). Negative = up. |
| `blurSigma` | `8.0` | Blur intensity of the area outside the oval. |
| `ringStrokeWidth` | `5.0` | Width of the progress ring stroke. |
| `ringTrackColor` | `0x33FFFFFF` | Color of the unfilled ring track. |
| `ringPadding` | `6.0` | Padding between the oval and the ring. |

### CameraConfig

| Parameter | Default | Description |
|-----------|---------|-------------|
| `resolution` | `ResolutionPreset.high` | Camera resolution preset. |
| `preferredLens` | `CameraLensDirection.front` | Which camera to use. |
| `maxDetectionFps` | `30` | Max frames per second for face detection processing. Lower = less CPU. |

### StepCardStyle

Customize the instruction card shown during each step.

| Parameter | Type | Description |
|-----------|------|-------------|
| `backgroundColor` | `Color?` | Card background color. |
| `borderColor` | `Color?` | Card border color. |
| `borderRadius` | `BorderRadius?` | Card corner radius. |
| `textStyle` | `TextStyle?` | Text style for the step title. |
| `iconColor` | `Color?` | Color of the step icon. |

### InfoScreenConfig

Shown when `startWithInfoScreen: true`. Lets you display preparation instructions before detection.

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | `String?` | Screen title. |
| `subtitle` | `String?` | Subtitle / description. |
| `guidanceItems` | `List<GuidanceItem>?` | List of guidance tips (icon + text pairs). |
| `buttonText` | `String?` | CTA button text. |
| `backgroundGradient` | `Gradient?` | Background gradient. |
| `buttonGradient` | `Gradient?` | Button gradient. |
| `lottieAsset` | `String?` | Lottie animation asset path. |
| `lottieFromPackage` | `bool?` | Whether the Lottie asset is from a package. |

## Privacy & Biometric Data

A captured face is **biometric data**. Depending on your jurisdiction it may be regulated as a special category of personal data (GDPR Art. 9) or under biometric privacy laws such as BIPA.

What this package does and does not do:

- It performs **no network I/O** and keeps **no persistent storage** beyond a single unencrypted JPEG written to the app's temporary directory.
- It returns the file path in `CapturedImage`. You (the app) are the data controller: obtain explicit consent before launching detection.
- **Delete the file as soon as you are done** via `await capturedImage.delete()`. The package does not delete it for you.
- Do **not** log `CapturedImage` naively - `toString()` redacts the path, but `imgPath`/`toJson()` still expose it.
- `completedSteps` and auto-capture results are **client-side liveness signals only**; they are not tamper-proof. Perform **server-side verification** for any authentication decision.

## Contributors

<a href="https://github.com/GhagSagar23/livelyness_detection/graphs/contributors"><img src="https://contrib.rocks/image?repo=GhagSagar23/livelyness_detection" width="128" height="128" /></a>
