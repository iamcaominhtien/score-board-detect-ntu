import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:score_board_detect/configs.dart';
import 'package:score_board_detect/pages/detection_page/cubit.dart';
import 'package:score_board_detect/pages/detection_page/widgets/bottombar.dart';
import 'package:score_board_detect/pages/detection_page/widgets/detected_lines.dart';
import 'package:score_board_detect/pages/detection_page/widgets/topbar.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({Key? key}) : super(key: key);

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage>
    with WidgetsBindingObserver {
  CameraController? _camController;
  final DetectionPageCubit _detectionPageCubit = DetectionPageCubit();
  double _aspectRatio = 1;
  IconData _flashIcon = Icons.flashlight_off;
  bool _onStreamCamera = false;
  bool _disposeCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _camController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      //check camera is disposed or not
      if (_disposeCamera == false) {
        _disposeCamera = true;
        if (_onStreamCamera) {
          _onStreamCamera = false;
          _camController
              ?.stopImageStream()
              .then((value) => _camController!.dispose());
        } else {
          _camController?.dispose();
        }
      }
    } else if (state == AppLifecycleState.inactive) {
      if (_onStreamCamera) {
        _onStreamCamera = false;
        _camController?.stopImageStream();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_disposeCamera) {
        _disposeCamera = false;
        _onStreamCamera = true;
        _initCamera();
      } else {
        _onStreamCamera = true;
        _camController?.startImageStream(_imageStreamProcessing);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detectionPageCubit.close();
    _camController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(),
          if (_camController != null)
            AspectRatio(
              aspectRatio: 1 / _aspectRatio,
              child: CameraPreview(_camController!),
            ),
          if (_camController != null)
            DetectedLines(
                detectionPageCubit: _detectionPageCubit,
                aspectRatio: _aspectRatio),
          Positioned(
            top: 10,
            left: 5,
            right: 5,
            child: TopBarDetectionPage(
                flashIcon: _flashIcon, flashToggle: _flashToggle),
          ),
          Positioned(
            bottom: 50,
            left: 10,
            right: 10,
            child: BottomBarDetectionPage(
              pickImage: _pickImage,
              takePicture: _takePicture,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initCamera() async {
    var desc = await Config().getCameraDescription();
    if (desc == null) return;
    _camController = CameraController(
      desc,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _camController!.initialize();
      _camController!.setFlashMode(FlashMode.off);
      _camController!
          .startImageStream(_imageStreamProcessing)
          .then((value) => _onStreamCamera = true);
      _aspectRatio = _camController!.value.aspectRatio;
    } catch (e) {
      debugPrint("Error initializing camera, error: ${e.toString()}");
    }
    setState(() {});
  }

  Future<void> _imageStreamProcessing(image) async {
    if (mounted) {
      _detectionPageCubit.detectTable(image);
    }
  }

  Future<void> _takePicture() async {
    if (_camController == null) return;
    _camController!.stopImageStream();
    _camController!.takePicture().then((value) {
      Navigator.pop(context, value.path);
    });
  }

  void _pickImage() {
    final ImagePicker picker = ImagePicker();
    picker.pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            Navigator.pop(context, image.path);
          },
        );
      }
    });
  }

  void _flashToggle() {
    if (_camController != null) {
      if (_camController!.value.flashMode == FlashMode.torch) {
        _camController!.setFlashMode(FlashMode.off);
        _flashIcon = Icons.flashlight_off;
      } else {
        _camController!.setFlashMode(FlashMode.torch);
        _flashIcon = Icons.flashlight_on;
      }
      setState(() {});
    }
  }
}
