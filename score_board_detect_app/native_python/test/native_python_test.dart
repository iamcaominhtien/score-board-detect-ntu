import 'package:flutter_test/flutter_test.dart';
import 'package:native_python/native_python.dart';
import 'package:native_python/native_python_platform_interface.dart';
import 'package:native_python/native_python_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativePythonPlatform
    with MockPlatformInterfaceMixin
    implements NativePythonPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List?> getLinesTable(Map<String, dynamic> data) {
    // TODO: implement getLinesTable
    throw UnimplementedError();
  }

  @override
  Future processImageAPI(Map<String, dynamic> data) {
    // TODO: implement processImageAPI
    throw UnimplementedError();
  }
}

void main() {
  final NativePythonPlatform initialPlatform = NativePythonPlatform.instance;

  test('$MethodChannelNativePython is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativePython>());
  });

  test('getPlatformVersion', () async {
    NativePython nativePythonPlugin = NativePython();
    MockNativePythonPlatform fakePlatform = MockNativePythonPlatform();
    NativePythonPlatform.instance = fakePlatform;

    expect(await nativePythonPlugin.getPlatformVersion(), '42');
  });
}
