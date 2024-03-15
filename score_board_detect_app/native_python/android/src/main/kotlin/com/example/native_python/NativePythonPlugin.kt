package com.example.native_python

import androidx.annotation.NonNull
import android.util.Base64
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import kotlin.concurrent.thread

/** NativePythonPlugin */
class NativePythonPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var py: Python
    private lateinit var module: PyObject
    private lateinit var detectTableAPI: PyObject
    private lateinit var processImageAPI: PyObject
    private val convertYUVAPI = ConvertYUV()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_python")
        channel.setMethodCallHandler(this)

        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(flutterPluginBinding.applicationContext))
        }

        py = Python.getInstance()
        module = py.getModule("script")
        detectTableAPI = module["get_lines_table"]!!
        processImageAPI = module["process_image_api"]!!
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "getLinesTable") {
            try {
                val bytesList: List<ByteArray> = call.argument("platforms")!!
                val strides: IntArray = call.argument("strides")!!
                val width: Int = call.argument("width")!!
                val height: Int = call.argument("height")!!
                thread {
                    val rgbImage = convertYUVAPI.convertYUVToGRB(bytesList, strides, width, height)
                    val encodedImage = Base64.encodeToString(rgbImage, Base64.DEFAULT)
                    val lines = detectTableAPI.call(encodedImage).asList().map { it.toInt() }
                    result.success(lines)
                }
            } catch (e: Exception) {
                result.success(intArrayOf())
            }
        } else if (call.method == "processImageAPI") {
            thread {
                try {
                    val json = processImageAPI.call(call.argument("path")!!)
                    result.success(json.toString())
                    println("Result type: ${json::class.simpleName}")
                } catch (e: Exception) {
                    val jsonError = "{\"error\": \"${e.message}\"}"
                    result.success(jsonError)
                }
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
