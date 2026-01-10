import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/office_provider.dart';

class IsometricOffice extends ConsumerStatefulWidget {
  final VoidCallback? onWorkerTapped;

  const IsometricOffice({
    super.key,
    this.onWorkerTapped,
  });

  @override
  ConsumerState<IsometricOffice> createState() => IsometricOfficeState();
}

class IsometricOfficeState extends ConsumerState<IsometricOffice> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;
  SMIInput<double>? _workerCountInput;
  SMIBool? _isTalkingInput;
  SMITrigger? _waveTrigger;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  Future<void> _loadRiveFile() async {
    try {
      final data = await rootBundle
          .load('assets/riv/isometric_marketing_agency_animation.riv');
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;

      // Attempt to find a state machine.
      var controller =
          StateMachineController.fromArtboard(artboard, 'State Machine 1');
      controller ??= StateMachineController.fromArtboard(artboard, 'Main');

      // Fallback: try the first state machine found
      if (controller == null && artboard.stateMachines.isNotEmpty) {
        controller = StateMachineController.fromArtboard(
            artboard, artboard.stateMachines.first.name);
      }

      if (controller != null) {
        debugPrint('Rive: Found controller');
        artboard.addController(controller);
        _controller = controller;

        debugPrint(
            'Rive: Available inputs: ${controller.inputs.map((e) => '${e.name} (${e.runtimeType})').join(', ')}');

        // Bind inputs manually since findInput might be missing
        for (final input in controller.inputs) {
          if (input.name == 'WorkerCount' && input is SMIInput<double>) {
            _workerCountInput = input;
            debugPrint('Rive: Bound WorkerCount');
          } else if (input.name == 'IsTalking' && input is SMIBool) {
            _isTalkingInput = input;
            debugPrint('Rive: Bound IsTalking');
          } else if (input.name == 'Wave' && input is SMITrigger) {
            _waveTrigger = input;
            debugPrint('Rive: Bound Wave');
          }
        }
      } else {
        debugPrint(
            'Rive: No controller found! Available state machines: ${artboard.stateMachines.map((e) => e.name).join(', ')}');
      }

      setState(() {
        _riveArtboard = artboard;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading Rive file: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Public methods for external control
  void setTalking(bool isTalking) {
    if (_isTalkingInput != null) {
      _isTalkingInput!.value = isTalking;
    }
  }

  void triggerWave() {
    if (_waveTrigger != null) {
      _waveTrigger!.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to officeProvider for state changes
    final workerCount = ref.watch(officeProvider.select((s) => s.workerCount));

    // Update Rive input if it exists
    if (_workerCountInput != null) {
      _workerCountInput!.value = workerCount.toDouble();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_riveArtboard == null) {
      return const Center(child: Text('Failed to load office scene'));
    }

    return Stack(
      children: [
        // The Rive Animation
        Rive(
          artboard: _riveArtboard!,
          fit: BoxFit.cover,
        ),

        // Invisible touch layer for interaction
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              if (details.localPosition.dy >
                  MediaQuery.of(context).size.height * 0.4) {
                widget.onWorkerTapped?.call();
              }
            },
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
