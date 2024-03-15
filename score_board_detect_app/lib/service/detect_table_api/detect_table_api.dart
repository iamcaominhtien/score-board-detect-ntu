import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:native_python/native_python.dart';
import 'package:score_board_detect/service/detect_table_api/model/detect_table_api_model.dart';

class DetectTableAPI {
  static Future<List<DetectTableAPIModel>?> detectTable(String url) async {
    try {
      final nativePython = NativePython();
      var jsonData = await nativePython.processImageAPI(url);
      var myJson = json.decode(jsonData) as Map<String, dynamic>;
      if (myJson["error"] != null) {
        if (kDebugMode) {
          print(myJson["error"]);
          if (myJson["traceback"] != null) {
            print(myJson["traceback"]);
          }
        }

        throw Exception("Can't detect table");
      }

      if (myJson["data"] == null) return null;
      var list =
          await compute(_generateFilesFromMap, myJson['data'] as List<dynamic>);
      return list;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  static List<DetectTableAPIModel> _generateFilesFromMap(List<dynamic> maps) {
    return List.generate(
        maps.length, (index) => DetectTableAPIModel.fromJson(maps[index]));
  }
}
