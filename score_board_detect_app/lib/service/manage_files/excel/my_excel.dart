import 'dart:io';
import 'dart:math';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:score_board_detect/service/detect_table_api/model/detect_table_api_model.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';
import 'package:score_board_detect/service/manage_files/sql/manage_files_db.dart';

class MyExcel {
  //create empty excel file
  static Future<File> createEmptyExcel({String name = 'MyExcel'}) async {
    final excel = Excel.createExcel();
    File file = await saveExcelFile(excel, name);

    return file;
  }

  static Future<File> saveExcelFile(Excel excel, String name) async {
    var bytes = excel.save();
    var directory = await getApplicationDocumentsDirectory();

    var file = File(
        "${directory.path}/${name}_id${DateTime.now().millisecondsSinceEpoch}.xlsx")
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
    return file;
  }

  static Future<ManageFile?> createDataExcel(List<DetectTableAPIModel> data,
      {String name = 'MyExcel'}) async {
    try {
      final excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      sheetObject.appendRow([
        "STT",
        "Mã SV",
        "Họ và tên",
        "Ngày sinh",
        "Lớp",
        "Đ.KT",
        "Đ.GK",
        "Đ.Thi",
        "Ký tên",
        "Đề",
        "S.Tờ",
        "Ghi chú"
      ]);
      String dKt, dGk, dThi;
      List<String> points;
      int sum;
      for (DetectTableAPIModel datum in data) {
        points = datum.predicted?.map<String>((cell) {
              if (cell.isEmpty) return '';
              sum = 0;
              for (int i = cell.length - 1; i >= 0; i--) {
                sum = sum + cell[i] * pow(10, cell.length - 1 - i).toInt();
              }
              double temp = 1.0 * sum;

              if (cell.length > 1) {
                temp = temp / 10;
                while (temp > 10) {
                  temp = temp / 10;
                }
              }
              return temp.toString();
            }).toList() ??
            [];
        for (int i = 0; i < 3 - points.length; i++) {
          points.add('');
        }

        [dKt, dGk, dThi] = points;

        sheetObject.appendRow(
            [datum.stt, datum.id, '', '', '', dKt, dGk, dThi, '', '', '', '']);
      }

      File file = await saveExcelFile(excel, name);
      return await ManageFilesDB.createManageFile(
          file.path, FileType.documentExcel);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error: $e\nStackSTrace: ${stackTrace.toString()}");
      }
      return null;
    }
  }

  //load excel file from path
  static Future<Excel?> loadExcel(String path) async {
    try {
      var bytes = File(path).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      return excel;
    } catch (e) {
      return null;
    }
  }

  //open file from path
  static Future<String?> open(String path) async {
    var permission = await Permission.manageExternalStorage.status;
    if (!permission.isGranted) {
      if ((await Permission.manageExternalStorage.request()) !=
          PermissionStatus.granted) {
        return 'You need to grant permission to access the file';
      }
    }

    final file = File(path);
    final exists = await file.exists();
    if (!exists) {
      if (kDebugMode) {
        print('File not exists');
      }
      return 'File not exists';
    }

    // Process.run('open', [path]);
    try {
      var openResult = await OpenFile.open(
        path,
        type:
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );
      if (openResult.type == ResultType.done) {
        if (kDebugMode) {
          print("Done");
        }
      } else {
        if (kDebugMode) {
          print("Error: ${openResult.message}");
          throw openResult.message;
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error: $e\nStackSTrace: ${stackTrace.toString()}");
      }
      return "Can't open the file now";
    }

    return null;
  }
}
