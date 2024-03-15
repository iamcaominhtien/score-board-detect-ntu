import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FireStorage {
  static final _ref = FirebaseStorage.instance.ref();
  static const _foldersDefault = ['admin', 'images', 'test'];

  //push image to firebase storage, given file path
  //return url of image
  static Future<String?> pushImageToStorage(String? path,
      {List<String> folders = _foldersDefault,
      String extension = 'jpg'}) async {
    if (path != null) {
      try {
        File image = File(path);
        String contentType = 'image/jpeg';
        if (extension == 'png') {
          contentType = 'image/png';
        }
        var ref = _ref;
        for (var folder in folders) {
          ref = ref.child(folder);
        }
        ref = ref
            .child("image_${DateTime.now().microsecondsSinceEpoch}.$extension");
        //create metadata
        var metadata = SettableMetadata(
            contentType: contentType,
            customMetadata: {'picked-file-path': image.path});
        await ref.putFile(image, metadata);
        return ref.getDownloadURL();
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print(stackTrace);
        }
        return null;
      }
    }
    return null;
  }

  //remove image from firebase storage, given url
  static Future<bool> removeFileFromStorage(String url) async {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return false;
  }

  //push image to user firebase storage
  //return url of image
  static Future<String?> pushImageToMyStorage(XFile xFile, String userId,
      {String? imageName}) async {
    try {
      File image = File(xFile.path);
      String path = image.path;
      String contentType = 'image/jpeg';
      String extension = path.split('.').last;
      if (extension == 'png') {
        contentType = 'image/png';
      }
      if (imageName == null) {
        imageName = "image_${DateTime.now().microsecondsSinceEpoch}.$extension";
      } else {
        imageName = "$imageName.$extension";
      }
      var ref = _ref.child("users").child(userId).child(imageName);
      //create metadata
      var metadata = SettableMetadata(
          contentType: contentType, customMetadata: {'picked-file-path': path});
      await ref.putFile(image, metadata);
      return ref.getDownloadURL();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(e);
        print(stackTrace);
      }
      return null;
    }
  }
}
