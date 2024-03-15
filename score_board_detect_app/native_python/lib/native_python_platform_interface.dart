import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_python_method_channel.dart';

abstract class NativePythonPlatform extends PlatformInterface {
  /// Constructs a NativePythonPlatform.
  NativePythonPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativePythonPlatform _instance = MethodChannelNativePython();

  /// The default instance of [NativePythonPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativePython].
  static NativePythonPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativePythonPlatform] when
  /// they register themselves.
  static set instance(NativePythonPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List?> getLinesTable(Map<String, dynamic> data) {
    throw UnimplementedError('getLinesTable() has not been implemented.');
  }

  Future<dynamic> processImageAPI(Map<String, dynamic> data) {
    throw UnimplementedError('processImageAPI() has not been implemented.');
  }
}
