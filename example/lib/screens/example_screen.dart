import 'dart:ui' as ui;

import 'package:example/index.dart';
import 'package:livelyness_detection/livelyness_detection.dart';

const _accent = Color(0xFF00E5A0);
const _cyan = Color(0xFF00B4D8);
const _cardBg = Color(0xFF12141E);
const _border = Color(0xFF1E2030);
const _dimText = Color(0xFF6B6F80);

const _presetColors = [
  ('Mint', Color(0xFF00E5A0)),
  ('Cyan', Color(0xFF00B4D8)),
  ('Purple', Color(0xFF9B59B6)),
  ('Amber', Color(0xFFF39C12)),
  ('Red', Color(0xFFE74C3C)),
  ('White', Colors.white),
];

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  // --- Result ---
  String? _capturedImagePath;

  // --- Steps ---
  final List<LivelynessStepItem> _steps = [];

  // --- Detection settings ---
  bool _startWithInfo = true;
  bool _showFacialVertices = false;
  bool _allowAfterTimeOut = false;
  int _timeOutDuration = 30;

  // --- Info screen config ---
  String _infoTitle = "Verify it's really you";
  String _infoSubtitle =
      "Follow the on-screen prompts to confirm you're a real, live person.";
  String _infoButtonText = "Begin Verification";
  Color _infoBgStart = const Color(0xFF14161B);
  Color _infoBgEnd = const Color(0xFF1F2330);
  Color _infoBtnStart = _accent;
  Color _infoBtnEnd = _cyan;

  // --- Oval config ---
  double _ovalWidth = 0.72;
  double _ovalAspect = 1.32;
  double _ovalOffset = -0.06;
  double _blurSigma = 8.0;
  double _ringStroke = 5.0;
  double _ringPadding = 6.0;
  Color _ringTrackColor = const Color(0x33FFFFFF);

  // --- Camera config ---
  ResolutionPreset _resolution = ResolutionPreset.high;
  int _maxFps = 30;

  // --- Appearance ---
  Color _overlayColor = const Color(0xCC000000);
  Color _progressColor = const Color(0xFF00E5A0);
  Color _contourLineColor = const Color(0xFFEAEAEA);
  Color _contourDotColor = const Color(0xFFEAEAEA);
  double _contourLineWidth = 1.6;
  double _contourDotRadius = 2.0;
  bool _displayLines = true;
  bool _displayDots = true;

  // --- Route ---
  bool _useSlideUpRoute = false;

  // --- Callbacks ---
  bool _callbacksEnabled = true;
  final List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();
    _steps.addAll([
      LivelynessStepItem(
          step: LivelynessStep.blink,
          title: 'Blink your eyes',
          isCompleted: false),
      LivelynessStepItem(
          step: LivelynessStep.smile,
          title: 'Give us a smile',
          isCompleted: false),
    ]);
  }

  void _log(String msg) {
    if (!_callbacksEnabled) return;
    setState(() {
      _eventLog.insert(
          0, '${DateTime.now().toString().substring(11, 19)} $msg');
      if (_eventLog.length > 20) _eventLog.removeLast();
    });
  }

  Future<void> _onDetect() async {
    setState(() {
      _capturedImagePath = null;
      _eventLog.clear();
    });
    final messenger = ScaffoldMessenger.of(context);

    final config = DetectionConfig(
      steps: _steps,
      startWithInfoScreen: _startWithInfo,
      showFacialVertices: _showFacialVertices,
      maxSecToDetect: _timeOutDuration >= 100 ? 2500 : _timeOutDuration,
      allowAfterMaxSec: _allowAfterTimeOut,
      captureButtonColor: _accent,

      // --- Info screen ---
      infoScreenConfig: InfoScreenConfig(
        title: _infoTitle,
        subtitle: _infoSubtitle,
        buttonText: _infoButtonText,
        backgroundGradient: [_infoBgStart, _infoBgEnd],
        buttonGradient: [_infoBtnStart, _infoBtnEnd],
      ),

      // --- Oval ---
      ovalConfig: OvalConfig(
        widthFraction: _ovalWidth,
        aspectRatio: _ovalAspect,
        verticalOffsetFraction: _ovalOffset,
        blurSigma: _blurSigma,
        ringStrokeWidth: _ringStroke,
        ringPadding: _ringPadding,
        ringTrackColor: _ringTrackColor,
      ),

      // --- Camera ---
      cameraConfig: CameraConfig(
        resolution: _resolution,
        maxDetectionFps: _maxFps,
      ),

      // --- Appearance ---
      overlayColor: _overlayColor,
      progressColor: _progressColor,
      contourLineColor: _contourLineColor,
      contourDotColor: _contourDotColor,
      contourLineWidth: _contourLineWidth,
      contourDotRadius: _contourDotRadius,
      displayLines: _displayLines,
      displayDots: _displayDots,

      // --- Thresholds ---
      thresholds: [
        SmileDetectionThreshold(probability: 0.8),
        BlinkDetectionThreshold(
            leftEyeProbability: 0.25, rightEyeProbability: 0.25),
      ],

      // --- Route ---
      routeBuilder: _useSlideUpRoute
          ? (screen) => PageRouteBuilder<CapturedImage?>(
                pageBuilder: (_, __, ___) => screen,
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 400),
              )
          : null,

      // --- Callbacks ---
      onStepCompleted: _callbacksEnabled
          ? (step, done, total) => _log('✓ ${step.name} ($done/$total)')
          : null,
      onFaceDetected: _callbacksEnabled
          ? (_) {} // fires at frame rate — no-op to avoid log spam
          : null,
      onTimeout: _callbacksEnabled ? () => _log('⏱ Timeout') : null,
      onComplete: _callbacksEnabled
          ? (result) => _log(
                result != null ? '📸 Captured' : '✕ Cancelled',
              )
          : null,
    );

    final response = await LivelynessDetection.detect(
      context: context,
      config: config,
    );
    if (response == null) return;
    setState(() => _capturedImagePath = response.imgPath);
    messenger.showSnackBar(SnackBar(
      content: Text('Captured (${response.completedSteps.length} steps)'),
      backgroundColor: _cardBg,
    ));
  }

  // --- Step helpers ---
  bool _isStepSelected(LivelynessStep step) =>
      _steps.any((s) => s.step == step);

  void _toggleStep(LivelynessStep step) {
    if (_isStepSelected(step)) {
      if (_steps.length <= 1) return;
      _steps.removeWhere((s) => s.step == step);
    } else {
      _steps.add(LivelynessStepItem(
        step: step,
        title: _titleFor(step),
        isCompleted: false,
      ));
    }
    setState(() {});
  }

  String _titleFor(LivelynessStep step) => switch (step) {
        LivelynessStep.blink => 'Blink your eyes',
        LivelynessStep.turnLeft => 'Turn your head left',
        LivelynessStep.turnRight => 'Turn your head right',
        LivelynessStep.smile => 'Give us a smile',
      };

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

  // ────────────────────────────── BUILD ──────────────────────────────

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
            const SizedBox(height: 28),
            _buildHero(),
            const SizedBox(height: 28),
            _buildCta(),
            const SizedBox(height: 32),
            _buildStepSelector(),
            const SizedBox(height: 20),
            _buildSection('DETECTION', _buildDetectionSettings()),
            const SizedBox(height: 12),
            _buildSection('INFO SCREEN', _buildInfoScreenSettings()),
            const SizedBox(height: 12),
            _buildSection('FACE GUIDE', _buildOvalSettings()),
            const SizedBox(height: 12),
            _buildSection('CAMERA', _buildCameraSettings()),
            const SizedBox(height: 12),
            _buildSection('APPEARANCE', _buildAppearanceSettings()),
            const SizedBox(height: 12),
            _buildSection('ADVANCED', _buildAdvancedSettings()),
            if (_eventLog.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildEventLog(),
            ],
          ],
        ),
      ),
    );
  }

  // ────────────────────────────── HEADER / HERO / CTA ──────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(colors: [_accent, _cyan]),
          ),
          child: const Icon(Icons.face_retouching_natural,
              color: Colors.black, size: 20),
        ),
        const SizedBox(width: 12),
        const Text('Liveness',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _accent.withValues(alpha: 0.12),
          ),
          child: const Text('v2.0',
              style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Center(
      child: SizedBox(
        width: 180,
        height: 236,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _capturedImagePath != null
              ? ClipRRect(
                  key: const ValueKey('img'),
                  borderRadius: BorderRadius.circular(90),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 50,
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
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: _accent, size: 14),
                          SizedBox(width: 5),
                          Text('Verified',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ]),
                )
              : Container(
                  key: const ValueKey('empty'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    border: Border.all(color: _border, width: 1.5),
                    color: _cardBg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent.withValues(alpha: 0.08),
                        ),
                        child: Icon(Icons.person_outline_rounded,
                            size: 40, color: _accent.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 12),
                      const Text('No capture yet',
                          style: TextStyle(
                              color: _dimText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCta() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [_accent, _cyan]),
          boxShadow: [
            BoxShadow(
                color: _accent.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onDetect,
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                SizedBox(width: 8),
                Text('Start Detection',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────── STEP CHIPS ──────────────────────────────

  Widget _buildStepSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('VERIFICATION STEPS'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LivelynessStep.values.map((step) {
            final on = _isStepSelected(step);
            return GestureDetector(
              onTap: () => _toggleStep(step),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: on ? _accent.withValues(alpha: 0.12) : _cardBg,
                  border: Border.all(
                      color: on ? _accent.withValues(alpha: 0.4) : _border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_iconFor(step),
                      size: 15, color: on ? _accent : _dimText),
                  const SizedBox(width: 6),
                  Text(_labelFor(step),
                      style: TextStyle(
                          color: on ? Colors.white : _dimText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ────────────────────────────── COLLAPSIBLE SECTIONS ──────────────────────────────

  Widget _buildSection(String label, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _cardBg,
          border: Border.all(color: _border),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: _dimText,
          collapsedIconColor: _dimText,
          title: Text(label,
              style: const TextStyle(
                  color: _dimText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          children: [child],
        ),
      ),
    );
  }

  // ────────────────────────────── DETECTION SETTINGS ──────────────────────────────

  Widget _buildDetectionSettings() {
    return Column(children: [
      _switchRow('Info screen', 'Show instructions before detection',
          _startWithInfo, (v) => setState(() => _startWithInfo = v)),
      _divider(),
      _switchRow('Face mesh', 'Draw facial contour vertices',
          _showFacialVertices, (v) => setState(() => _showFacialVertices = v)),
      _divider(),
      _switchRow('Manual capture', 'Allow photo after timeout',
          _allowAfterTimeOut, (v) => setState(() => _allowAfterTimeOut = v)),
      _divider(),
      _sliderRow(
        'Timeout',
        'Seconds before detection expires',
        _timeOutDuration >= 100 ? '∞' : '${_timeOutDuration}s',
        _timeOutDuration.toDouble(),
        5,
        100,
        19,
        (v) => setState(() => _timeOutDuration = v.round()),
      ),
    ]);
  }

  // ────────────────────────────── INFO SCREEN SETTINGS ──────────────────────────────

  Widget _buildInfoScreenSettings() {
    return Column(children: [
      _textFieldRow('Title', _infoTitle, (v) => setState(() => _infoTitle = v)),
      _divider(),
      _textFieldRow(
          'Subtitle', _infoSubtitle, (v) => setState(() => _infoSubtitle = v)),
      _divider(),
      _textFieldRow('Button text', _infoButtonText,
          (v) => setState(() => _infoButtonText = v)),
      _divider(),
      _colorRow('Background start', _infoBgStart,
          (c) => setState(() => _infoBgStart = c)),
      _divider(),
      _colorRow(
          'Background end', _infoBgEnd, (c) => setState(() => _infoBgEnd = c)),
      _divider(),
      _colorRow('Button start', _infoBtnStart,
          (c) => setState(() => _infoBtnStart = c)),
      _divider(),
      _colorRow(
          'Button end', _infoBtnEnd, (c) => setState(() => _infoBtnEnd = c)),
    ]);
  }

  // ────────────────────────────── OVAL / FACE GUIDE ──────────────────────────────

  Widget _buildOvalSettings() {
    return Column(children: [
      _sliderRow(
          'Width',
          'Fraction of screen width',
          _ovalWidth.toStringAsFixed(2),
          _ovalWidth,
          0.4,
          0.95,
          11,
          (v) => setState(() => _ovalWidth = v)),
      _divider(),
      _sliderRow(
          'Aspect ratio',
          'Height multiplier',
          _ovalAspect.toStringAsFixed(2),
          _ovalAspect,
          1.0,
          1.8,
          8,
          (v) => setState(() => _ovalAspect = v)),
      _divider(),
      _sliderRow(
          'Vertical offset',
          'Shift up/down',
          _ovalOffset.toStringAsFixed(2),
          _ovalOffset,
          -0.15,
          0.1,
          25,
          (v) => setState(() => _ovalOffset = v)),
      _divider(),
      _sliderRow(
          'Blur sigma',
          'Frosted glass intensity',
          _blurSigma.toStringAsFixed(0),
          _blurSigma,
          0,
          30,
          30,
          (v) => setState(() => _blurSigma = v)),
      _divider(),
      _sliderRow(
          'Ring stroke',
          'Progress ring thickness',
          _ringStroke.toStringAsFixed(1),
          _ringStroke,
          1,
          12,
          22,
          (v) => setState(() => _ringStroke = v)),
      _divider(),
      _sliderRow(
          'Ring padding',
          'Gap between oval and ring',
          _ringPadding.toStringAsFixed(0),
          _ringPadding,
          0,
          20,
          20,
          (v) => setState(() => _ringPadding = v)),
      _divider(),
      _colorRow('Ring track', _ringTrackColor,
          (c) => setState(() => _ringTrackColor = c)),
    ]);
  }

  // ────────────────────────────── CAMERA ──────────────────────────────

  Widget _buildCameraSettings() {
    return Column(children: [
      _dropdownRow<ResolutionPreset>(
        'Resolution',
        'Camera quality preset',
        _resolution,
        ResolutionPreset.values,
        (v) => setState(() => _resolution = v),
      ),
      _divider(),
      _sliderRow(
          'Max FPS',
          'Detection frame rate',
          _maxFps >= 30 ? 'Max' : '$_maxFps',
          _maxFps.toDouble(),
          5,
          30,
          5,
          (v) => setState(() => _maxFps = v.round())),
    ]);
  }

  // ────────────────────────────── APPEARANCE ──────────────────────────────

  Widget _buildAppearanceSettings() {
    return Column(children: [
      _colorRow('Progress ring', _progressColor,
          (c) => setState(() => _progressColor = c)),
      _divider(),
      _colorRow('Overlay scrim', _overlayColor,
          (c) => setState(() => _overlayColor = c)),
      _divider(),
      _colorRow('Contour lines', _contourLineColor,
          (c) => setState(() => _contourLineColor = c)),
      _divider(),
      _colorRow('Contour dots', _contourDotColor,
          (c) => setState(() => _contourDotColor = c)),
      _divider(),
      _sliderRow(
          'Line width',
          '',
          _contourLineWidth.toStringAsFixed(1),
          _contourLineWidth,
          0.5,
          5,
          9,
          (v) => setState(() => _contourLineWidth = v)),
      _divider(),
      _sliderRow(
          'Dot radius',
          '',
          _contourDotRadius.toStringAsFixed(1),
          _contourDotRadius,
          1,
          6,
          10,
          (v) => setState(() => _contourDotRadius = v)),
      _divider(),
      _switchRow('Draw lines', '', _displayLines,
          (v) => setState(() => _displayLines = v)),
      _divider(),
      _switchRow('Draw dots', '', _displayDots,
          (v) => setState(() => _displayDots = v)),
    ]);
  }

  // ────────────────────────────── ADVANCED ──────────────────────────────

  Widget _buildAdvancedSettings() {
    return Column(children: [
      _switchRow('Slide-up route', 'Custom page transition', _useSlideUpRoute,
          (v) => setState(() => _useSlideUpRoute = v)),
      _divider(),
      _switchRow('Callbacks', 'Log step/timeout/complete events',
          _callbacksEnabled, (v) => setState(() => _callbacksEnabled = v)),
    ]);
  }

  // ────────────────────────────── EVENT LOG ──────────────────────────────

  Widget _buildEventLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _sectionLabel('EVENT LOG'),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _eventLog.clear()),
            child: const Text('Clear',
                style: TextStyle(color: _accent, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF0A0B10),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _eventLog
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(e,
                          style: const TextStyle(
                              color: Color(0xFF8B8FA0),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontFeatures: [ui.FontFeature.tabularFigures()])),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────── REUSABLE ROW WIDGETS ──────────────────────────────

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: _dimText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2));

  Widget _divider() => const Divider(color: _border, height: 1);

  Widget _switchRow(
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(sub, style: const TextStyle(color: _dimText, fontSize: 11)),
            ],
          ]),
        ),
        SizedBox(
          height: 32,
          child: FittedBox(
            child: Switch(value: value, onChanged: onChanged),
          ),
        ),
      ]),
    );
  }

  Widget _sliderRow(String title, String sub, String badge, double value,
      double min, double max, int divisions, ValueChanged<double> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(sub,
                    style: const TextStyle(color: _dimText, fontSize: 11)),
              ],
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF1E2030),
            ),
            child: Text(badge,
                style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [ui.FontFeature.tabularFigures()])),
          ),
        ]),
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(
          min: min,
          max: max,
          divisions: divisions,
          value: value.clamp(min, max),
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  Widget _textFieldRow(
      String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFF1E2030),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _colorRow(String label, Color current, ValueChanged<Color> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((preset) {
            final selected = current == preset.$2;
            return GestureDetector(
              onTap: () => onChanged(preset.$2),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: preset.$2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 16,
                        color: preset.$2.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _dropdownRow<T extends Enum>(String title, String sub, T value,
      List<T> options, ValueChanged<T> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(sub, style: const TextStyle(color: _dimText, fontSize: 11)),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF1E2030),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              dropdownColor: const Color(0xFF1E2030),
              style: const TextStyle(
                  color: _accent, fontSize: 12, fontWeight: FontWeight.w600),
              iconEnabledColor: _dimText,
              iconSize: 18,
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ]),
    );
  }
}
