import 'package:livelyness_detection/index.dart';

/// A single guidance row shown on the introductory info screen (an icon, a
/// short title and a one-line description).
class GuidanceItem {
  /// Leading icon for the row.
  final IconData icon;

  /// Bold heading of the guidance row.
  final String title;

  /// Supporting one-line description.
  final String description;

  const GuidanceItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Customisation for the introductory info screen shown before detection when
/// [DetectionConfig.startWithInfoScreen] is `true`.
///
/// Every default reproduces the current v2.0 behaviour, so passing a bare
/// `const InfoScreenConfig()` changes nothing. The string literals here mirror
/// `StringConstants` verbatim; they are inlined (not referenced) so the
/// constructor can stay `const`.
class InfoScreenConfig {
  /// Large title at the top of the screen.
  final String title;

  /// Supporting subtitle under the title.
  final String subtitle;

  /// Guidance rows rendered as glassmorphic cards above the button.
  final List<GuidanceItem> guidanceItems;

  /// Label of the primary call-to-action button.
  final String buttonText;

  /// Vertical background gradient (top -> bottom).
  final List<Color> backgroundGradient;

  /// Gradient fill of the primary button.
  final List<Color> buttonGradient;

  /// Optional custom Lottie asset path. `null` uses the bundled default.
  ///
  /// Must be a bundled asset key declared in a `pubspec.yaml` (this package's
  /// when [lottieFromPackage] is `true`, otherwise the consumer app's). Never
  /// pass user-supplied or remote/network input here.
  final String? lottieAsset;

  /// Whether [lottieAsset] is resolved from this package's assets rather than
  /// the consumer app's assets. Defaults to `false` (consumer asset).
  final bool lottieFromPackage;

  const InfoScreenConfig({
    this.title = "Verify it's really you",
    this.subtitle =
        "Follow the on-screen prompts to confirm you're a real, live person.",
    this.guidanceItems = const [
      GuidanceItem(
        icon: Icons.wb_sunny_outlined,
        title: "Good Lighting",
        description:
            "Make sure you are in a well lit area and both ears are uncovered",
      ),
      GuidanceItem(
        icon: Icons.center_focus_strong_outlined,
        title: "Look Straight",
        description:
            "Hold your phone at eye level and look straight to the camera",
      ),
    ],
    this.buttonText = "Begin Verification",
    this.backgroundGradient = const [Color(0xFF14161B), Color(0xFF1F2330)],
    this.buttonGradient = const [Color(0xFF00E5A0), Color(0xFF00B4D8)],
    this.lottieAsset,
    this.lottieFromPackage = false,
  });
}
