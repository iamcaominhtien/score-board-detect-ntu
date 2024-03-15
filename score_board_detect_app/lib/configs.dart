import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Config {
  //singleton
  static final Config _instance = Config._internal();

  factory Config() => _instance;

  Config._internal();

  //RootIsolateToken
  late RootIsolateToken rootIsolateToken;

  //GOOGLE_CLIENT_ID
  String get googleClientId =>
      '263171351553-6r9j0tga54sihsu491k7mgrgp0f3sl7m.apps.googleusercontent.com';

  //FACEBOOK_CLIENT_ID
  String get facebookClientId => '696295478962340';

  //CAMERA DESCRIPTION
  CameraDescription? _cameraDescription;

  Future<CameraDescription?> getCameraDescription() async {
    if (_cameraDescription == null) {
      try {
        final cameras = await availableCameras();
        var idx = cameras
            .indexWhere((c) => c.lensDirection == CameraLensDirection.back);
        if (idx < 0) {
          log("No Back camera found - weird");
          return null;
        }
        _cameraDescription = cameras[idx];
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
    return _cameraDescription!;
  }
}
