import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';
import 'package:score_board_detect/service/manage_files/sql/manage_files_db.dart';

part 'state.dart';

part 'action.dart';

class MainPageBloc extends Bloc<MainPageAction, MainPageState> {
  final _manageFilesDB = ManageFilesDB();

  //animated list for image list
  final GlobalKey<AnimatedListState> keyImageList = GlobalKey();
  final _imageList = <ManageFile>[];

  List<ManageFile> get imageList => _imageList;

  //animated list for file list
  final GlobalKey<AnimatedListState> keyExcelFileList = GlobalKey();
  final _excelFileList = <ManageFile>[];

  List<ManageFile> get excelFileList => _excelFileList;

  MainPageBloc() : super(const MainPageState(true, false, false)) {
    on<LoadMainPage>(_onLoadMainPage);
    on<EndMainPage>(_onEndMainPage);
    on<RefreshMainPage>(_onRefreshMainPage);
    on<AddNewFile>(_onAddNewFile);
    on<DeleteFile>(_onDeleteFile);
  }

  Future<FutureOr<void>> _onLoadMainPage(
      LoadMainPage event, Emitter<MainPageState> emit) async {
    emit(state.copyWith(loading: true));
    await loadFiles();
    emit(state.copyWith(
        loading: false,
        isWorkingSpaceEmpty: _imageList.isEmpty && _excelFileList.isEmpty));
  }

  Future<void> loadFiles() async {
    try {
      var listFile = await ManageFilesDB().queryAllFiles();
      for (var file in listFile) {
        if (file.type == FileType.image) {
          _addImageFile(file);
        } else {
          _addExcelFile(file);
        }
      }
    } catch (e, stackStrace) {
      if (kDebugMode) {
        print(
            "Error load files page: $e\nStackStrace: ${stackStrace.toString()}");
      }
    }
  }

  FutureOr<void> _onEndMainPage(
      EndMainPage event, Emitter<MainPageState> emit) {
    _imageList.clear();
    _excelFileList.clear();
    emit(const MainPageState(true, false, false));
  }

  FutureOr<void> _onRefreshMainPage(
      RefreshMainPage event, Emitter<MainPageState> emit) {
    emit(state.copyWith(isRefresh: event.status));
  }

  Future<FutureOr<void>> _onAddNewFile(
      AddNewFile event, Emitter<MainPageState> emit) async {
    int id = await _manageFilesDB.insertFile(event.manageFile);
    if (id != -1) {
      ManageFile file = event.manageFile.copyWith(id: id);
      if (file.type == FileType.image) {
        _addImageFile(file);
        emit(state.copyWith(
            isWorkingSpaceEmpty: _imageList.isEmpty && _excelFileList.isEmpty,
            newImages: [file]));
      } else {
        _addExcelFile(file);
        emit(state.copyWith(
            isWorkingSpaceEmpty: _imageList.isEmpty && _excelFileList.isEmpty,
            newFiles: [file]));
      }
    }
  }

  _addImageFile(ManageFile file) {
    if (!_imageList.contains(file)) {
      _imageList.insert(0, file);
      keyImageList.currentState
          ?.insertItem(0, duration: const Duration(milliseconds: 800));
    }
  }

  Future<FutureOr<void>> _onDeleteFile(
      DeleteFile event, Emitter<MainPageState> emit) async {
    if (event.fileType == FileType.image) {
      for (var file in event.files) {
        int index = _imageList.indexOf(file);
        if (index != -1) {
          _imageList.removeAt(index);
          keyImageList.currentState?.removeItem(
              index, (context, animation) => Container(),
              duration: const Duration(milliseconds: 800));
        }
      }
      ManageFilesDB().removeFiles(event.files);
      emit(
        state.copyWith(
          isWorkingSpaceEmpty: _imageList.isEmpty && _excelFileList.isEmpty,
          deletedImages: event.files,
        ),
      );
    } else {
      for (var file in event.files) {
        int index = _excelFileList.indexOf(file);
        if (index != -1) {
          _excelFileList.removeAt(index);
          keyExcelFileList.currentState?.removeItem(
              index, (context, animation) => Container(),
              duration: const Duration(milliseconds: 800));
        }
      }
      ManageFilesDB().removeFiles(event.files);
      emit(
        state.copyWith(
          isWorkingSpaceEmpty: _imageList.isEmpty && _excelFileList.isEmpty,
          deletedExcels: event.files,
        ),
      );
    }
  }

  _addExcelFile(ManageFile file) {
    if (!_excelFileList.contains(file)) {
      _excelFileList.insert(0, file);
      keyExcelFileList.currentState
          ?.insertItem(0, duration: const Duration(milliseconds: 800));
    }
  }
}
