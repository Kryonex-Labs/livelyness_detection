import 'dart:ui' as ui;

import 'package:livelyness_detection/index.dart';

/// Introductory screen shown before detection when
/// [DetectionConfig.startWithInfoScreen] is `true`.
///
/// Dark, neutral background with a centered face Lottie, glassmorphic guidance
/// cards and a gradient "Begin Verification" button.
class LivelynessInfoWidget extends StatelessWidget {
  final VoidCallback onStartTap;
  final InfoScreenConfig config;

  const LivelynessInfoWidget({
    required this.onStartTap,
    this.config = const InfoScreenConfig(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: config.backgroundGradient,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          padding.top + 24,
          24,
          padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              config.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              config.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB8BDC9),
                fontWeight: FontWeight.w400,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            Expanded(
              child: Center(
                child: Lottie.asset(
                  config.lottieAsset ?? AssetConstants.lottie.livelynessStart,
                  package: config.lottieAsset == null
                      ? AssetConstants.packageName
                      : (config.lottieFromPackage
                          ? AssetConstants.packageName
                          : null),
                  animate: true,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            for (int i = 0; i < config.guidanceItems.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _buildGuidanceCard(
                icon: config.guidanceItems[i].icon,
                title: config.guidanceItems[i].title,
                subTitle: config.guidanceItems[i].description,
              ),
            ],
            const SizedBox(height: 28),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceCard({
    required IconData icon,
    required String title,
    required String subTitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0x1AFFFFFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subTitle,
                      style: const TextStyle(
                        color: Color(0xFFB8BDC9),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: config.buttonGradient,
        ),
        boxShadow: [
          BoxShadow(
            // Derived from the button gradient so a custom gradient is honored.
            color: config.buttonGradient.last.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStartTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              config.buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
