import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:native_python/native_python.dart';

class DetectionPageState extends Equatable {
  final DateTime? lastTimeDetect;
  final CameraImage? cameraImage;
  final List<int>? lines;

  const DetectionPageState({this.lastTimeDetect, this.cameraImage, this.lines});

  @override
  List<Object?> get props => [lastTimeDetect, cameraImage, lines];

  //copyWith
  DetectionPageState copyWith({
    DateTime? lastTimeDetect,
    CameraImage? cameraImage,
    bool setCameraImageWithNull = false,
    List<int>? lines,
  }) {
    return DetectionPageState(
      lastTimeDetect: lastTimeDetect ?? this.lastTimeDetect,
      cameraImage:
          setCameraImageWithNull ? null : (cameraImage ?? this.cameraImage),
      lines: lines ?? this.lines,
    );
  }
}

class DetectionPageCubit extends Cubit<DetectionPageState> {
  DetectionPageCubit() : super(const DetectionPageState());

  final nativePython = NativePython();

  Future<void> detectTable(CameraImage cameraImage) async {
    if (state.cameraImage != null) return;
    if (state.lastTimeDetect != null &&
        state.lastTimeDetect!.difference(DateTime.now()).inMilliseconds.abs() <
            600) {
      return;
    }

    emit(state.copyWith(
      lastTimeDetect: DateTime.now(),
      cameraImage: cameraImage,
    ));

    var lines = await nativePython.getLinesTable(cameraImage);
    if (isClosed == false) {
      emit(state.copyWith(setCameraImageWithNull: true, lines: lines));
    }
  }
}
