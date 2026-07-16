# livelyness_detection

![](https://img.shields.io/pub/publisher/livelyness_detection) ![](https://img.shields.io/github/issues-raw/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/languages/count/GhagSagar23/livelyness_detection)
![](https://img.shields.io/pub/likes/livelyness_detection) ![](https://img.shields.io/pub/points/livelyness_detection) ![](https://img.shields.io/pub/popularity/livelyness_detection) ![](https://img.shields.io/pub/v/livelyness_detection)
![](https://img.shields.io/github/directory-file-count/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/repo-size/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/commit-activity/w/GhagSagar23/livelyness_detection) ![](https://img.shields.io/github/contributors/GhagSagar23/livelyness_detection)

## Index

- [What is the Livelyness Detection?](#whatIsLivelyness)
- [Platform Support](#platformSupport)
- [Installation](#installation)
  - [Flutter Setup](#flutterSetup)
  - [Native Setup](#flutterSetupNativeSetup)
    - [iOS](#flutterSetupNativeiOS)
    - [Android](#flutterSetupNativeAndroid)
- [Privacy & compliance](#privacy)
- [Contributors](#contributors)

<a name="whatIsLivelyness"></a>

## What is the Livelyness Detection?

This package runs a short sequence of **active liveness challenges** — blink, turn left/right, smile — detected **on-device** via Google ML Kit face detection, and captures a selfie once the challenge steps pass. All processing stays on the device; no images or biometric data are sent anywhere by this package.

> **⚠️ This is active challenge-response, NOT certified anti-spoofing.** The package does **not** implement [ISO/IEC 30107](https://www.iso.org/standard/79520.html) presentation-attack detection (PAD). It performs no texture, depth, motion, or reflection analysis, so a **printed photo, screen replay, recorded video, or 3D mask can defeat the gesture challenge.** Do **not** use it as the sole control for KYC, identity verification, payments, or any security-critical authentication. Pair it with a dedicated PAD/anti-spoofing solution and your own server-side risk checks, and obtain the user's consent before capture (see [Privacy & compliance](#privacy)).

<!-- <iframe src="https://embed.lottiefiles.com/animation/16432" width="100%" aspect-ratio="auto"></iframe> -->

<iframe 
  width="100%"
  src="https://embed.lottiefiles.com/animation/16432"
  frameborder="0"
  allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen>
</iframe>

<a name="platformSupport"></a>

## Platform Support

| iOS | Android |                                            MacOS                                             |                                             Web                                              |                                            Linux                                             |                                           Windows                                            |
| :-: | :-----: | :------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------: |
| ✔️  |   ✔️    | <iframe src="https://embed.lottiefiles.com/animation/96163" height="25" width="25"></iframe> | <iframe src="https://embed.lottiefiles.com/animation/96163" height="25" width="25"></iframe> | <iframe src="https://embed.lottiefiles.com/animation/96163" height="25" width="25"></iframe> | <iframe src="https://embed.lottiefiles.com/animation/96163" height="25" width="25"></iframe> |

<a name="installation"></a>

## Installation

First, we have to install the package on flutter.

<a name="flutterSetup"></a>

#### Flutter Setup

Add `livelyness_detection` to your `pubspec.yaml` dependencies.

<a name="flutterSetupUsingCommandLine"></a>

##### Using command-line

```sh
flutter pub add livelyness_detection
```

<a name="flutterSetupNativeSetup"></a>

#### Native Setup

Next comes the native setup on both android and iOS

<a name="flutterSetupNativeiOS"></a>

<details>
  <summary>iOS</summary>
  
  #### iOS Setup
  1. Open the project in Xcode and set the deployment
  2. Open the `ios/Runner/Info.plist` file as `Source Code`.
  3. Add the below-mentioned code inside the `<dict>` tag.

```xml
  <key>NSCameraUsageDescription</key>
  <string>Camera Access for Scanning</string>
```

> Only the camera permission is required — this package neither records nor plays audio (`enableAudio: false`), so do **not** add `NSMicrophoneUsageDescription`. Declaring an unused microphone purpose string can cause App Store review rejection (Guideline 5.1.1).

4. Open the `ios/Runner/Podfile` and uncomment the second line.

```yaml
platform :ios, '14.0' # <---------- Uncomment this line
```

5. Set the deployment target in the Xcode project

  <img width="1440" alt="Screenshot 2023-01-02 at 11 03 17 AM" src="https://user-images.githubusercontent.com/106381741/210199508-72c0572c-c153-4178-b29a-4ae490f1e989.png">
</details>

<a name="flutterSetupNativeAndroid"></a>

<details>
  <summary>Android</summary>
  
  #### Android Setup
  1. Open the `example/android/app/build.gradle` file and set the `minSdkVersion` as `21`.
</details>

<a name="codeExample"></a>

## Example

A call to a single line function will return a temporary path to the captured image.

<a name="exampleCode"></a>

#### Code

```dart
    final String? response =
        await LivelynessDetection.instance.detectLivelyness(
      context,
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

<a name="exampleVideo"></a>

#### Example Video-Andriod , iOS
![The example app running in Andriod](https://github.com/phil10xs/livelyness_detection/blob/develop/lib/src/assets/demo/livelyness_detection_android.gif?raw=true)



<a name="privacy"></a>

## Privacy & compliance

This package captures **biometric data** (a face selfie and derived facial landmarks) — a special/sensitive data category under most privacy laws. Read this before shipping to production.

**What this package does**

- **On-device only.** Face detection runs locally via Google ML Kit; the package makes **no network calls** and transmits no images or biometric data.
- Uses [Google ML Kit Face Detection](https://developers.google.com/ml-kit/vision/face-detection) — your app must comply with Google's ML Kit terms and disclose its use.
- The captured selfie is written **unencrypted** to the OS temporary directory and returned as a file path. **The package never deletes it** — the file persists until you remove it or the OS evicts the cache.

**What you (the consuming app) are responsible for**

- **Obtain consent before capture.** This package does not collect consent and its info screen is *instructional only* — **not** lawful-basis consent. You must establish a lawful basis: GDPR Art. 9(2)(a) *explicit* consent, Illinois BIPA §15(b) informed *written* release, China PIPL *separate* consent, India DPDP notice+consent, etc.
- **Delete the captured image** as soon as it is no longer needed, and define a retention/destruction schedule (BIPA §15(a); GDPR storage limitation, Art. 5(1)(e)).
- **Do not treat this as anti-spoofing/PAD.** A capture where `didCaptureAutomatically == false` (the manual button shown after a timeout) has passed **no** liveness check — do not accept it as verified.
- If you deploy in the EU for identity purposes, review your EU AI Act obligations (transparency, robustness, human oversight).

## Contributors

<a href="https://github.com/GhagSagar23/livelyness_detection/graphs/contributors"><img src="https://contrib.rocks/image?repo=GhagSagar23/livelyness_detection" width="128" height="128" /></a>
