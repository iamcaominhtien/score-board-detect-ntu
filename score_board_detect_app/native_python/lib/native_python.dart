import 'dart:typed_data';

import 'native_python_platform_interface.dart';

class NativePython {
  Future<String?> getPlatformVersion() {
    return NativePythonPlatform.instance.getPlatformVersion();
  }

  Future<dynamic> processImageAPI(String path) {
    return NativePythonPlatform.instance.processImageAPI({'path': path});
  }

  Future<List<int>> getLinesTable(dynamic cameraImage) async {
    var strides = Int32List(cameraImage.planes.length * 2);
    int index = 0;
    var imageBytes = cameraImage.planes.map((plane) {
      strides[index] = (plane.bytesPerRow);
      index++;
      strides[index] = (plane.bytesPerPixel ?? 0);
      index++;
      return plane.bytes;
    }).toList();

    var lines = await NativePythonPlatform.instance.getLinesTable({
      'platforms': imageBytes,
      'height': cameraImage.height,
      'width': cameraImage.width,
      'strides': strides
    });

    return (lines ?? []).map((e) => e as int).toList();
  }
}
