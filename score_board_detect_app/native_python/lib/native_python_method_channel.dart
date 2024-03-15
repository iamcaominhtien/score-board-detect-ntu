import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_python_platform_interface.dart';

/// An implementation of [NativePythonPlatform] that uses method channels.
class MethodChannelNativePython extends NativePythonPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_python');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List?> getLinesTable(Map<String, dynamic> data) {
    return methodChannel.invokeMethod<List>('getLinesTable', data);
  }

  @override
  Future<dynamic> processImageAPI(Map<String, dynamic> data) {
    return methodChannel.invokeMethod<dynamic>('processImageAPI', data);
  }
}
