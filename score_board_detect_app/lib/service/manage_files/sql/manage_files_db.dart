import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:score_board_detect/service/fire_storage.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';

class ManageFilesDB {
  //Singleton
  static final ManageFilesDB _manageFilesDB = ManageFilesDB._internal();

  factory ManageFilesDB() => _manageFilesDB;

  ManageFilesDB._internal();

  sql.Database? _db;
  static String? _tableName;

  //Init DB
  Future<void> initDB() async {
    if (_db != null) {
      return;
    }
    _tableName = 'manage_files${FirebaseAuth.instance.currentUser?.uid ?? ""}';
    try {
      final dbPath = await sql.getDatabasesPath();
      _db = await sql.openDatabase(
        '$dbPath/$_tableName.db',
        onCreate: (db, version) {
          return db.execute('''CREATE TABLE $_tableName(
               id INTEGER PRIMARY KEY AUTOINCREMENT, 
               path TEXT, 
               pathOnFly TEXT, 
               name TEXT,
               type TEXT, 
               lastModified TEXT, 
               created TEXT, 
               size REAL)
              ''');
        },
        version: 1,
      );
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
    } finally {
      debugPrint("database was loaded");
    }
  }

  //query all files
  Future<List<ManageFile>> queryAllFiles() async {
    await initDB();
    if (_db != null) {
      try {
        final List<Map<String, dynamic>> maps = await _db!.query(_tableName!);
        final List<ManageFile> files =
            await compute(_generateFilesFromMap, maps);
        return files;
        // return List.generate(10000000, (i) {
        //   return ManageFile.fromJson(maps[0]);
        // });
        // return List.generate(maps.length, (i) {
        //   return ManageFile.fromJson(maps[i]);
        // });
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print("Stacktrace: $stackTrace");
        }
      }
    }
    return [];
  }

  static List<ManageFile> _generateFilesFromMap(
      List<Map<String, dynamic>> maps) {
    // return List.generate(10000000, (i) {
    //   return ManageFile.fromJson(maps[0]);
    // });
    return List.generate(maps.length, (i) {
      return ManageFile.fromJson(maps[i]);
    });
  }

  //insert files, files sort by created, newest first
  Future<int> insertFile(ManageFile file) async {
    await initDB();
    if (_db != null) {
      try {
        return await _db!.insert(
          _tableName!,
          file.toJson(),
          conflictAlgorithm: sql.ConflictAlgorithm.replace,
        );
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print("Stacktrace: $stackTrace");
        }
      }
    }
    return -1;
  }

  Future<bool> insertFiles(List<ManageFile> files) async {
    await initDB();
    if (_db != null) {
      try {
        files.sort((a, b) {
          if (a.created == null && b.created == null) {
            return a.name?.compareTo(b.name ?? '') ??
                0; // sắp xếp theo tên nếu cả created đều null
          }
          if (a.created == null) {
            return 1;
          }
          if (b.created == null) {
            return -1;
          }
          final createdComparison = a.created!.compareTo(b.created!);
          if (createdComparison != 0) {
            return createdComparison;
          }
          if (a.name == null && b.name == null) {
            return a.path.compareTo(
                b.path); // sắp xếp theo đường dẫn nếu cả name đều null
          }
          if (a.name == null) {
            return 1;
          }
          if (b.name == null) {
            return -1;
          }
          return a.name!.compareTo(b.name!);
        });

        for (var file in files) {
          await _db!.insert(
            _tableName!,
            file.toJson(),
            conflictAlgorithm: sql.ConflictAlgorithm.replace,
          );
        }
        return true;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print("Stacktrace: $stackTrace");
        }
        return false;
      }
    }
    return false;
  }

  //remove file, given a list of file
  Future<bool> removeFiles(Iterable<ManageFile> files) async {
    await initDB();
    if (_db != null) {
      try {
        if (files.isEmpty) return true;
        await Future.wait([
          _db!.delete(
            _tableName!,
            where: 'id IN (${files.map((e) => e.id).join(',')})',
          ),
          removeFilesByLocation(files),
        ]);
        // await _db!.delete(
        //   _tableName!,
        //   where: 'id IN (${files.map((e) => e.id).join(',')})',
        // );
        // removeFilesByLocation(files);
        return true;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print("Stacktrace: $stackTrace");
        }
      }
    }
    return false;
  }

  //update file
  Future<bool> updateFile(Iterable<ManageFile> files) async {
    await initDB();
    if (_db != null) {
      try {
        for (var file in files) {
          await _db!.update(
            _tableName!,
            file.toJson(),
            where: 'id = ?',
            whereArgs: [file.id],
          );
        }
        return true;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print("Stacktrace: $stackTrace");
        }
      }
    }
    return false;
  }

  //create manage file object, given path. Suppose file path is in cache, we need to create a new file object in app folder to manage it
  static Future<ManageFile?> createManageFile(String path, FileType fileType,
      {String? pathOnFly, String? name}) async {
    late String filePath;
    late double fileSize;
    if (fileType == FileType.documentExcel) {
      final file = File(path);
      if ((await file.exists()) == false) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('File not exist');
        }
        return null;
      }
      filePath = path;
      fileSize = await file.length() / 1024 / 1024;
    } else {
      final cacheFile = File(path);
      late final File file;

      //move file to app folder
      try {
        var directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/${path.split('/').last}';
        file = await cacheFile.copy(filePath);
        await cacheFile.delete();
        fileSize = await file.length() / 1024 / 1024;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print(e);
          print("Stacktrace: $stackTrace");
        }
        return null;
      }
    }

    return ManageFile(
      filePath,
      fileType,
      name: name ?? filePath.split('/').last,
      created: DateTime.now(),
      lastModified: DateTime.now(),
      size: fileSize,
      pathOnFly: pathOnFly,
    );
  }

  //remove file by location
  static Future<bool> removeFilesByLocation(
      Iterable<ManageFile> manageFiles) async {
    try {
      Iterable<String> urls = manageFiles
          .where((element) => element.pathOnFly != null)
          .map((e) => e.pathOnFly!);
      Iterable<String> paths = manageFiles.map((e) => e.path);
      var results =
          await Future.wait([removeFilesOnDisk(paths), removeFilesOnFly(urls)]);
      return results[0] == paths.length && results[1] == urls.length;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(e);
        print("Stacktrace: $stackTrace");
      }
      return false;
    }
  }

  //close database
  Future<void> closeDb() async {
    if (_db == null) return;
    try {
      if (_db!.isOpen) {
        await _db!.close();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(e);
        print("Stack trace: $stackTrace");
      }
    } finally {
      _db = null;
      debugPrint("database is closed");
    }
  }

  Future<void> deleteDatabase() async {
    await closeDb();
    final dbPath = await sql.getDatabasesPath();
    await sql.deleteDatabase('$dbPath/$_tableName.db');
  }

  static Future<int> removeFilesOnDisk(Iterable<String> paths) async {
    int successCount = 0;

    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) {
        if (kDebugMode) {
          print('File not exist: $path');
        }
        continue;
      }

      try {
        await file.delete();
        successCount++;
      } catch (e) {
        if (kDebugMode) {
          print('Failed to delete file: $path - Error: $e');
        }
      }
    }

    return successCount;
  }

  static Future<int> removeFilesOnFly(Iterable<String> urls) async {
    // return FireStorage.removeFileFromStorage(path);
    int successCount = 0;

    for (final url in urls) {
      if (await FireStorage.removeFileFromStorage(url)) {
        successCount++;
      }
    }

    return successCount;
  }

  //check a path is valid or not
  bool isValidPath(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return false;
    }
    return true;
  }
}
