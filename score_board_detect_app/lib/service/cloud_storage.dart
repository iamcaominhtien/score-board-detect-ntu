import 'dart:io';

class CloudStorage {
  //upload file to firebase storage
  static Future<String?> uploadFile(String? filePath, File? file) async {
    if (filePath != null) {
      file = File(filePath);
    }
    if (file == null) {
      return null;
    }
    return null;

    // //upload file
    // final ref = FirebaseStorage.instance.ref().child('images/${file.path}');
    // final uploadTask = ref.putFile(file);
    // final snapshot = await uploadTask.whenComplete(() => null);
    // final downloadUrl = await snapshot.ref.getDownloadURL();
    // return downloadUrl;
  }
}
