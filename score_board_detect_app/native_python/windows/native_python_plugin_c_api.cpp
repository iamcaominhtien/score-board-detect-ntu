#include "include/native_python/native_python_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "native_python_plugin.h"

void NativePythonPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  native_python::NativePythonPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
