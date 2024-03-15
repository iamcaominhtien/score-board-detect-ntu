import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:score_board_detect/service/detect_table_api/detect_table_api.dart';
import 'package:score_board_detect/service/local_notification.dart';
import 'package:score_board_detect/service/manage_files/excel/my_excel.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';

part 'state.dart';

part 'actions.dart';

part 'task.dart';

class DetectTableAPIBloc
    extends Bloc<DetectTableApiAction, DetectTableApiState?> {
  final List<Task> _queue = [];

  List<Task> get queue => _queue;
  int _finishedProgresses = 0;

  DetectTableAPIBloc() : super(null) {
    on<InitialAction>(_initialAction);
    on<AddNewTaskAction>(_addRequestEvent);
    on<UpdateLocalNotificationAction>(_updateLocalNotificationEvent);
    on<CompletedTaskAction>(_completedTaskAction);
    on<CompletedAllTaskAction>(_completedAction);
    on<EndDetectTableAPIAction>(_endDetectTableAPIAction);
  }

  Future<FutureOr<void>> _initialAction(
      InitialAction event, Emitter<DetectTableApiState?> emit) async {
    emit(const InitialState());
    LocalNotificationService.clearAll();
    // print('top_panel_finished'.tr);
    LocalNotificationService.showNotification(
        id: 0, title: 'top_panel_start_detecting'.tr, millisecondDuration: 2000);
    _finishedProgresses = 0;
    // await Future.delayed(const Duration(milliseconds: 2000));
    LocalNotificationService.showNotification(
        id: 1,
        title: "top_panel_processing".tr,
        maxProgress: _queue.length,
        progress: 0,
        sound: false,
        body: "${"top_panel_finished".tr} 0/${_queue.length}");
  }

  Future<FutureOr<void>> _addRequestEvent(
      AddNewTaskAction event, Emitter<DetectTableApiState?> emit) async {
    _queue.add(event.task);
    if (_queue.length == 1) {
      add(InitialAction());
      _wakeUpQueue();
    } else {
      emit(AddNewTaskState(event.task, _queue.length));
      LocalNotificationService.showNotification(
          id: 1,
          title: "top_panel_processing".tr,
          body: "${'top_panel_finished'.tr} $_finishedProgresses/${_queue.length}",
          maxProgress: _queue.length,
          sound: false,
          progress: _finishedProgresses);
    }
  }

  FutureOr<void> _updateLocalNotificationEvent(
      UpdateLocalNotificationAction event, Emitter<DetectTableApiState?> emit) {
    int numberOfSuccess = event.finishedProgresses
        .where((element) => element.success)
        .toList()
        .length;
    int numberOfFailed = event.finishedProgresses.length - numberOfSuccess;
    emit(UpdateProgressState(_queue.length, event.finishedProgresses.length,
        numberOfFailed, numberOfSuccess));
    LocalNotificationService.showNotification(
        id: 1,
        title: "top_panel_processing".tr,
        body: "${'top_panel_finished'.tr} ${event.finishedProgresses.length}",
        maxProgress: _queue.length,
        sound: false,
        progress: event.finishedProgresses.length);
  }

  FutureOr<void> _completedTaskAction(
      CompletedTaskAction event, Emitter<DetectTableApiState?> emit) {
    emit(CompletedTaskState(event.task));
  }

  FutureOr<void> _completedAction(
      CompletedAllTaskAction event, Emitter<DetectTableApiState?> emit) {
    LocalNotificationService.clearAll();
    LocalNotificationService.showNotification(title: "${'top_panel_finished'.tr}!");
    emit(const FinishAllTaskState());
  }

  FutureOr<void> _endDetectTableAPIAction(
      EndDetectTableAPIAction event, Emitter<DetectTableApiState?> emit) {
    _queue.clear();
    _finishedProgresses = 0;
    emit(null);
  }

  void _wakeUpQueue() async {
    Set<Task> finishedProgresses = {};
    _finishedProgresses = 0;
    Task resultTask;
    for (int idx = 0; idx < _queue.length; idx++) {
      resultTask = await _fetchApi(_queue[idx]);
      finishedProgresses.add(resultTask);
      _finishedProgresses = finishedProgresses.length;
      add(UpdateLocalNotificationAction(
          finishedProgresses: finishedProgresses));
      add(CompletedTaskAction(resultTask));
    }
    _queue.clear();
    _finishedProgresses = 0;
    add(CompletedAllTaskAction());
  }

  Future<Task> _fetchApi(Task task) async {
    try {
      if (kDebugMode) {
        print("URL: ${task.imageFile.path}");
      }
      var result = await DetectTableAPI.detectTable(task.imageFile.path);
      if (result != null) {
        var file = await MyExcel.createDataExcel(result);
        return task.copyWith(finished: true, success: true, result: file);
      }
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print("Error: $e");
        print(stacktrace);
      }
    }
    return task.copyWith(finished: true, success: false);
  }
}
