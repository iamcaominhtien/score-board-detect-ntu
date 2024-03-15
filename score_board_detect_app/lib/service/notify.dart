import 'package:flutter/material.dart';
import 'package:get/get.dart';

//using Flutter toast
class Notify {
  //region Getx snackbar
  static getxSnackBarWarning(String message) => _getxSnackBar(
      'Warning', message, Icons.warning_amber_rounded, Colors.yellow);

  static getxSnackBarError(String message) =>
      _getxSnackBar('Error', message, Icons.error_outline_rounded, Colors.red);

  static _getxSnackBar(
      String title, String message, IconData icon, Color iconColor) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 10,
      icon: Icon(
        icon,
        color: iconColor,
      ),
      shouldIconPulse: true,
      onTap: (snack) => Get.back(),
    );
  }
//endregion
}
