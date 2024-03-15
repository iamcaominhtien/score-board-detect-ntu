import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class Helper {
  static Future<Uint8List> loadImageFromAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  static Future<List<String>?> pickFile(List<String>? allowedExtensions,
      {bool multipleFile = false}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? ['jpg', 'png'],
      allowMultiple: multipleFile,
    );
    List<String>? paths = result?.files.map((e) => e.path!).toList();
    return paths;
  }

  static Future<XFile?> pickImage(bool camera) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery);
    return image;
  }

  static getTime(DateTime time) {
    //if second < 10 -> now
    //if second < 60 -> show second + ago
    //if minute < 60 -> show minute + ago
    //if hour < 24 -> show hour + ago
    //if day < 7 -> show day + ago
    //others: MM dd, yyyy if year == current year -> MM dd. Example: Jan 1, 2021, June 21
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 10) {
      return 'now';
    }
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} ${'seconds'.tr} ${'ago'.tr}';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${'minutes'.tr} ${'ago'.tr}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ${'hours'.tr} ${'ago'.tr}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${'days'.tr} ${'ago'.tr}';
    }
    if (now.year == time.year) {
      return DateFormat('MMM dd').format(time);
    }
    return DateFormat('MMM dd, yyyy').format(time);
  }

  static void shareFile(String path) async {
    try {
      XFile file = XFile(path);
      Share.shareXFiles([file]);
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
    }
  }
}
