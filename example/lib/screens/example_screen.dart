import 'dart:ui' as ui;

import 'package:example/index.dart';
import 'package:livelyness_detection/livelyness_detection.dart';

const _accent = Color(0xFF00E5A0);
const _cardBg = Color(0xFF12141E);
const _border = Color(0xFF1E2030);
const _dimText = Color(0xFF6B6F80);

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  String? _capturedImagePath;
  bool _startWithInfo = true;
  bool _showFacialVertices = false;
  bool _allowAfterTimeOut = false;
  int _timeOutDuration = 30;
  final List<LivelynessStepItem> _steps = [];

  @override
  void initState() {
    super.initState();
    _steps.addAll([
      LivelynessStepItem(
        step: LivelynessStep.blink,
        title: 'Blink your eyes',
        isCompleted: false,
      ),
      LivelynessStepItem(
        step: LivelynessStep.smile,
        title: 'Give us a smile',
        isCompleted: false,
      ),
    ]);
  }

  Future<void> _onDetect() async {
    setState(() => _capturedImagePath = null);
    final messenger = ScaffoldMessenger.of(context);
    final response = await LivelynessDetection.detect(
      context: context,
      config: DetectionConfig(
        steps: _steps,
        startWithInfoScreen: _startWithInfo,
        showFacialVertices: _showFacialVertices,
        maxSecToDetect: _timeOutDuration >= 100 ? 2500 : _timeOutDuration,
        allowAfterMaxSec: _allowAfterTimeOut,
        captureButtonColor: _accent,
        infoScreenConfig: const InfoScreenConfig(
          title: 'Quick identity check',
        ),
        onStepCompleted: (step, completed, total) =>
            debugPrint('Step done: $step ($completed/$total)'),
        onComplete: (result) => debugPrint(
          // Don't log the biometric image path; log only whether one exists.
          'Detection complete: ${result != null ? 'captured' : 'no capture'}',
        ),
        thresholds: [
          SmileDetectionThreshold(probability: 0.8),
          BlinkDetectionThreshold(
            leftEyeProbability: 0.25,
            rightEyeProbability: 0.25,
          ),
        ],
      ),
    );
    if (response == null) return;
    setState(() => _capturedImagePath = response.imgPath);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Captured (${response.completedSteps.length} steps verified)',
        ),
      ),
    );
  }

  bool _isStepSelected(LivelynessStep step) =>
      _steps.any((s) => s.step == step);

  void _toggleStep(LivelynessStep step) {
    if (_isStepSelected(step)) {
      if (_steps.length <= 1) return;
      _steps.removeWhere((s) => s.step == step);
    } else {
      _steps.add(LivelynessStepItem(
        step: step,
        title: _labelFor(step),
        isCompleted: false,
      ));
    }
    setState(() {});
  }

  String _labelFor(LivelynessStep step) => switch (step) {
        LivelynessStep.blink => 'Blink',
        LivelynessStep.turnLeft => 'Turn Left',
        LivelynessStep.turnRight => 'Turn Right',
        LivelynessStep.smile => 'Smile',
      };

  IconData _iconFor(LivelynessStep step) => switch (step) {
        LivelynessStep.blink => Icons.remove_red_eye_outlined,
        LivelynessStep.turnLeft => Icons.turn_left_rounded,
        LivelynessStep.turnRight => Icons.turn_right_rounded,
        LivelynessStep.smile => Icons.sentiment_satisfied_alt_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Scaffold(
      body: SingleChildScrollView(
        padding:
            EdgeInsets.fromLTRB(20, padding.top + 20, 20, padding.bottom + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildHero(),
            const SizedBox(height: 32),
            _buildCta(),
            const SizedBox(height: 36),
            _buildStepSelector(),
            const SizedBox(height: 24),
            _buildSettingsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [_accent, Color(0xFF00B4D8)],
            ),
          ),
          child: const Icon(Icons.face_retouching_natural,
              color: Colors.black, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Liveness',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _accent.withValues(alpha: 0.12),
          ),
          child: const Text(
            'v2.0',
            style: TextStyle(
              color: _accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Center(
      child: SizedBox(
        width: 200,
        height: 260,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _capturedImagePath != null
              ? _buildCapturedImage()
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      key: const ValueKey('placeholder'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _border, width: 1.5),
        color: _cardBg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 48,
              color: _accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No capture yet',
            style: TextStyle(
              color: _dimText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImage() {
    return ClipRRect(
      key: const ValueKey('captured'),
      borderRadius: BorderRadius.circular(100),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
          // subtle gradient at bottom
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: _accent, size: 16),
                SizedBox(width: 6),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [_accent, Color(0xFF00B4D8)],
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onDetect,
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Start Detection',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VERIFICATION STEPS',
          style: TextStyle(
            color: _dimText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LivelynessStep.values.map((step) {
            final selected = _isStepSelected(step);
            return GestureDetector(
              onTap: () => _toggleStep(step),
              child: AnimatedContainer(
                // ponytail: const not possible here — selected is runtime

                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected ? _accent.withValues(alpha: 0.12) : _cardBg,
                  border: Border.all(
                    color: selected ? _accent.withValues(alpha: 0.4) : _border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconFor(step),
                      size: 16,
                      color: selected ? _accent : _dimText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _labelFor(step),
                      style: TextStyle(
                        color: selected ? Colors.white : _dimText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _cardBg,
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _settingsRow(
            'Info screen',
            'Show instructions before detection',
            Switch(
              value: _startWithInfo,
              onChanged: (v) => setState(() => _startWithInfo = v),
            ),
          ),
          const Divider(color: _border, height: 1, indent: 16, endIndent: 16),
          _settingsRow(
            'Face mesh',
            'Draw facial contour vertices',
            Switch(
              value: _showFacialVertices,
              onChanged: (v) => setState(() => _showFacialVertices = v),
            ),
          ),
          const Divider(color: _border, height: 1, indent: 16, endIndent: 16),
          _settingsRow(
            'Manual capture',
            'Allow photo after timeout',
            Switch(
              value: _allowAfterTimeOut,
              onChanged: (v) => setState(() => _allowAfterTimeOut = v),
            ),
          ),
          const Divider(color: _border, height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timeout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Seconds before detection expires',
                        style: TextStyle(color: _dimText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF1E2030),
                  ),
                  child: Text(
                    _timeOutDuration >= 100 ? '∞' : '${_timeOutDuration}s',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
            child: Slider(
              min: 5,
              max: 100,
              divisions: 19,
              value: _timeOutDuration.toDouble(),
              onChanged: (v) => setState(() => _timeOutDuration = v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(String title, String subtitle, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _dimText, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
