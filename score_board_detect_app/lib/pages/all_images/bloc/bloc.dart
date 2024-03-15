import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:score_board_detect/pages/main_page/bloc/bloc.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';
import 'package:share_plus/share_plus.dart';

part "state.dart";

part 'action.dart';

enum KeyDay {
  today,
  yesterday,
  last7Days,
  last30Days,
  older,
  all,
}

extension KeyDayExtension on KeyDay {
  String get name {
    switch (this) {
      case KeyDay.today:
        return "today".tr;
      case KeyDay.yesterday:
        return "yesterday".tr;
      case KeyDay.last7Days:
        return "last_7_days".tr;
      case KeyDay.last30Days:
        return "last_30_days".tr;
      case KeyDay.older:
        return "older".tr;
      case KeyDay.all:
        return "all".tr;
      default:
        return "";
    }
  }
}

class AllImagesBloc extends Bloc<AllImagesAction, AllImagesState> {
  AllImagesBloc() : super(const AllImagesState()) {
    on<SelectImageOfToday>(_onSelectImageOfToday);
    on<UnSelectImageOfToday>(_onUnSelectImageOfToday);
    on<SelectImageOfYesterday>(_onSelectImageOfYesterday);
    on<UnSelectImageOfYesterday>(_onUnSelectImageOfYesterday);
    on<SelectImageOfLast7Days>(_onSelectImageOfLast7Days);
    on<UnSelectImageOfLast7Days>(_onUnSelectImageOfLast7Days);
    on<SelectImageOfLast30Days>(_onSelectImageOfLast30Days);
    on<UnSelectImageOfLast30Days>(_onUnSelectImageOfLast30Days);
    on<SelectImageOfOlder>(_onSelectImageOfOlder);
    on<UnSelectImageOfOlder>(_onUnSelectImageOfOlder);
    on<SelectAllImage>(_onSelectAllImage);
    on<UnSelectAllImage>(_onUnSelectAllImage);
    on<SelectAllImageOfADay>(_onSelectAllImageOfADay);
    on<UnSelectAllImageOfADay>(_onUnSelectAllImageOfADay);
    on<DeleteSelectedImage>(_onDeleteSelectedImage);
    on<ImageSelectedOfADayIsEmpty>(_onImageSelectedOfADayIsEmpty);
    on<ShareMultipleSelectedImage>(_onShareMultipleSelectedImage);
    on<EndAllImagesAction>(_onEndAllImagesAction);
  }

  //region select images
  FutureOr<void> _onSelectImageOfToday(
      SelectImageOfToday event, Emitter<AllImagesState> emit) {
    var listToday = <ManageFile>{};
    listToday.addAll(state.today.listImage);
    listToday.addAll(event.images);
    var newState =
        state.copyWith(today: state.today.copyWith(listImage: listToday));
    emit(newState.copyWith(haveSelected: newState.haveAnySelected));
  }

  FutureOr<void> _onSelectImageOfYesterday(
      SelectImageOfYesterday event, Emitter<AllImagesState> emit) {
    var listYesterday = <ManageFile>{};
    listYesterday.addAll(state.yesterday.listImage);
    listYesterday.addAll(event.images);
    var newState = state.copyWith(
        yesterday: state.yesterday.copyWith(listImage: listYesterday));
    emit(newState.copyWith(haveSelected: newState.haveAnySelected));
  }

  FutureOr<void> _onSelectImageOfLast7Days(
      SelectImageOfLast7Days event, Emitter<AllImagesState> emit) {
    var listLast7Days = <ManageFile>{};
    listLast7Days.addAll(state.last7Days.listImage);
    listLast7Days.addAll(event.images);
    var newState = state.copyWith(
        last7Days: state.last7Days.copyWith(listImage: listLast7Days));
    emit(newState.copyWith(haveSelected: newState.haveAnySelected));
  }

  FutureOr<void> _onSelectImageOfLast30Days(
      SelectImageOfLast30Days event, Emitter<AllImagesState> emit) {
    var listLast30Days = <ManageFile>{};
    listLast30Days.addAll(state.last30Days.listImage);
    listLast30Days.addAll(event.images);
    var newState = state.copyWith(
        last30Days: state.last30Days.copyWith(listImage: listLast30Days));
    emit(newState.copyWith(haveSelected: newState.haveAnySelected));
  }

  FutureOr<void> _onSelectImageOfOlder(
      SelectImageOfOlder event, Emitter<AllImagesState> emit) {
    var listOlder = <ManageFile>{};
    listOlder.addAll(state.older.listImage);
    listOlder.addAll(event.images);
    var newState =
        state.copyWith(older: state.older.copyWith(listImage: listOlder));
    emit(newState.copyWith(haveSelected: newState.haveAnySelected));
  }

  FutureOr<void> _onSelectAllImage(
      SelectAllImage event, Emitter<AllImagesState> emit) {
    emit(state.createNewInstanceFromMe(event.images));
  }

  FutureOr<void> _onSelectAllImageOfADay(
      SelectAllImageOfADay event, Emitter<AllImagesState> emit) {
    emit(state.createNewInstanceFromMe({event.keyDay: event.images}));
  }

  //endregion

  //region unselect images
  FutureOr<void> _onUnSelectImageOfToday(
      UnSelectImageOfToday event, Emitter<AllImagesState> emit) {
    emit(state
        .clearExactlySomeImagesOfImagesSelected({KeyDay.today: event.images}));
  }

  FutureOr<void> _onUnSelectImageOfYesterday(
      UnSelectImageOfYesterday event, Emitter<AllImagesState> emit) {
    emit(state.clearExactlySomeImagesOfImagesSelected(
        {KeyDay.yesterday: event.images}));
  }

  FutureOr<void> _onUnSelectImageOfLast7Days(
      UnSelectImageOfLast7Days event, Emitter<AllImagesState> emit) {
    emit(state.clearExactlySomeImagesOfImagesSelected(
        {KeyDay.last7Days: event.images}));
  }

  FutureOr<void> _onUnSelectImageOfLast30Days(
      UnSelectImageOfLast30Days event, Emitter<AllImagesState> emit) {
    emit(state.clearExactlySomeImagesOfImagesSelected(
        {KeyDay.last30Days: event.images}));
  }

  FutureOr<void> _onUnSelectImageOfOlder(
      UnSelectImageOfOlder event, Emitter<AllImagesState> emit) {
    emit(state
        .clearExactlySomeImagesOfImagesSelected({KeyDay.older: event.images}));
  }

  FutureOr<void> _onUnSelectAllImage(
      UnSelectAllImage event, Emitter<AllImagesState> emit) {
    emit(state.clearExactlyAllImageOfImagesSelected(null));
  }

  FutureOr<void> _onUnSelectAllImageOfADay(
      UnSelectAllImageOfADay event, Emitter<AllImagesState> emit) {
    emit(state.clearExactlyAllImageOfImagesSelected([event.keyDay]));
  }

//endregion

  FutureOr<void> _onDeleteSelectedImage(
      DeleteSelectedImage event, Emitter<AllImagesState> emit) {
    var removeFiles = <ManageFile>{};
    for (var item in state.allImagesSelected) {
      removeFiles.addAll(item.listImage);
    }
    event.mainPageBloc.add(DeleteFile(removeFiles, event.fileType));
    emit(state.clearExactlyAllImageOfImagesSelected(null));
  }

  FutureOr<void> _onImageSelectedOfADayIsEmpty(
      ImageSelectedOfADayIsEmpty event, Emitter<AllImagesState> emit) {
    emit(state.copyWith(emptyDay: event.keyDays));
  }

  FutureOr<void> _onShareMultipleSelectedImage(
      ShareMultipleSelectedImage event, Emitter<AllImagesState> emit) {
    try {
      var shareFiles = <ManageFile>{};
      for (var item in state.allImagesSelected) {
        shareFiles.addAll(item.listImage);
      }
      List<XFile> xFiles = [];
      for (var file in shareFiles) {
        XFile xFile = XFile(file.path);
        xFiles.add(xFile);
      }
      Share.shareXFiles(xFiles);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    emit(const AllImagesState());
  }

  FutureOr<void> _onEndAllImagesAction(
      EndAllImagesAction event, Emitter<AllImagesState> emit) {
    emit(const AllImagesState());
  }
}
