part of 'bloc.dart';

@immutable
abstract class DetectTableApiAction {}

class InitialAction extends DetectTableApiAction {}

class AddNewTaskAction extends DetectTableApiAction {
  final Task task;

  AddNewTaskAction(this.task);
}

class UpdateLocalNotificationAction extends DetectTableApiAction {
  final Set<Task> finishedProgresses;

  UpdateLocalNotificationAction({this.finishedProgresses = const {}});
}

class CompletedTaskAction extends DetectTableApiAction {
  final Task task;

  CompletedTaskAction(this.task);
}

class CompletedAllTaskAction extends DetectTableApiAction {}

class EndDetectTableAPIAction extends DetectTableApiAction {}
