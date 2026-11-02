import 'package:collection/collection.dart';
import 'package:example/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:livelyness_detection/livelyness_detection.dart';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  //* MARK: - Private Variables
  //? =========================================================
  String? _capturedImagePath;
  final bool _isLoading = false;
  bool _startWithInfo = true;
  bool _showFacialVertices = false;
  bool _allowAfterTimeOut = false;
  final List<LivelynessStepItem> _veificationSteps = [];
  int _timeOutDuration = 30;

  //* MARK: - Life Cycle Methods
  //? =========================================================
  @override
  void initState() {
    _initValues();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  //* MARK: - Private Methods for Business Logic
  //? =========================================================
  void _initValues() {
    _veificationSteps.addAll(
      [
        LivelynessStepItem(
          step: LivelynessStep.blink,
          title: "Blink your eyes",
          isCompleted: false,
          detectionColor: Colors.amber,
        ),
        LivelynessStepItem(
          step: LivelynessStep.smile,
          title: "Give us a smile",
          isCompleted: false,
          detectionColor: Colors.green.shade800,
        ),
      ],
    );
  }

  void _onStartLivelyness() async {
    setState(() => _capturedImagePath = null);
    final CapturedImage? response = await LivelynessDetection.detect(
      context: context,
      config: DetectionConfig(
        steps: _veificationSteps,
        startWithInfoScreen: _startWithInfo,
        showFacialVertices: _showFacialVertices,
        maxSecToDetect: _timeOutDuration == 100 ? 2500 : _timeOutDuration,
        allowAfterMaxSec: _allowAfterTimeOut,
        captureButtonColor: Colors.red,
        thresholds: [
          SmileDetectionThreshold(probability: 0.8),
          BlinkDetectionThreshold(
            leftEyeProbability: 0.25,
            rightEyeProbability: 0.25,
          ),
        ],
        contourLineColor: Colors.white,
        contourDotColor: Colors.purple.shade800,
        contourLineWidth: 2,
        dashValues: const [2.0, 5.0],
        displayDots: false,
        displayLines: true,
      ),
    );
    if (response == null) {
      return;
    }
    setState(
      () => _capturedImagePath = response.imgPath,
    );
  }

  String _getTitle(LivelynessStep step) {
    switch (step) {
      case LivelynessStep.blink:
        return "Blink";
      case LivelynessStep.turnLeft:
        return "Turn Your Head Left";
      case LivelynessStep.turnRight:
        return "Turn Your Head Right";
      case LivelynessStep.smile:
        return "Smile";
    }
  }

  String _getSubTitle(LivelynessStep step) {
    switch (step) {
      case LivelynessStep.blink:
        return "Detects Blink on the face visible in camera";
      case LivelynessStep.turnLeft:
        return "Detects Left Turn of the on the face visible in camera";
      case LivelynessStep.turnRight:
        return "Detects Right Turn of the on the face visible in camera";
      case LivelynessStep.smile:
        return "Detects Smile on the face visible in camera";
    }
  }

  bool _isSelected(LivelynessStep step) {
    final LivelynessStepItem? doesExist = _veificationSteps.firstWhereOrNull(
      (p0) => p0.step == step,
    );
    return doesExist != null;
  }

  void _onStepValChanged(LivelynessStep step, bool value) {
    if (!value && _veificationSteps.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Need to have atleast 1 step of verification",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.red.shade900,
        ),
      );
      return;
    }
    final LivelynessStepItem? doesExist = _veificationSteps.firstWhereOrNull(
      (p0) => p0.step == step,
    );

    if (doesExist == null && value) {
      _veificationSteps.add(
        LivelynessStepItem(
          step: step,
          title: _getTitle(step),
          isCompleted: false,
        ),
      );
    } else {
      if (!value) {
        _veificationSteps.removeWhere(
          (p0) => p0.step == step,
        );
      }
    }
    setState(() {});
  }

  //* MARK: - Private Methods for UI Components
  //? =========================================================
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        " Livelyness Detection",
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildContent(),
        Visibility(
          visible: _isLoading,
          child: const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Spacer(
          flex: 4,
        ),
        Visibility(
          visible: _capturedImagePath != null,
          child: Expanded(
            flex: 7,
            child: Image.file(
              File(_capturedImagePath ?? ""),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Visibility(
          visible: _capturedImagePath != null,
          child: const Spacer(),
        ),
        Center(
          child: ElevatedButton(
            onPressed: _onStartLivelyness,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
            ),
            child: const Text(
              "Detect Livelyness",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(
              flex: 3,
            ),
            const Text(
              "Start with info screen:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            CupertinoSwitch(
              value: _startWithInfo,
              onChanged: (value) => setState(
                () => _startWithInfo = value,
              ),
            ),
            const Spacer(
              flex: 3,
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(
              flex: 3,
            ),
            const Text(
              "Show facial vertices:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            CupertinoSwitch(
              value: _showFacialVertices,
              onChanged: (value) => setState(
                () => _showFacialVertices = value,
              ),
            ),
            const Spacer(
              flex: 3,
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(
              flex: 3,
            ),
            const Text(
              "Allow after timer is completed:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            CupertinoSwitch(
              value: _allowAfterTimeOut,
              onChanged: (value) => setState(
                () => _allowAfterTimeOut = value,
              ),
            ),
            const Spacer(
              flex: 3,
            ),
          ],
        ),
        const Spacer(),
        Text(
          "Detection Time-out Duration(In Seconds): ${_timeOutDuration == 100 ? "No Limit" : _timeOutDuration}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          min: 0,
          max: 100,
          value: _timeOutDuration.toDouble(),
          onChanged: (value) => setState(
            () => _timeOutDuration = value.toInt(),
          ),
        ),
        Expanded(
          flex: 14,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: LivelynessStep.values.length,
            itemBuilder: (context, index) => ExpansionTile(
              title: Text(
                _getTitle(
                  LivelynessStep.values[index],
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                ListTile(
                  title: Text(
                    _getSubTitle(
                      LivelynessStep.values[index],
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: _isSelected(
                      LivelynessStep.values[index],
                    ),
                    onChanged: (value) => _onStepValChanged(
                      LivelynessStep.values[index],
                      value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
