part of 'bloc.dart';

@immutable
abstract class DetectTableApiState extends Equatable {
  const DetectTableApiState();
}

class InitialState extends DetectTableApiState {
  const InitialState();

  @override
  List<Object?> get props => [];
}

class AddNewTaskState extends DetectTableApiState {
  final Task task;
  final int total;

  const AddNewTaskState(this.task, this.total);

  @override
  List<Object?> get props => [task, total];
}

class UpdateProgressState extends DetectTableApiState {
  final int total;
  final int finishedProgresses;
  final int numberOfSuccess;
  final int numberOfFail;

  const UpdateProgressState(this.total, this.finishedProgresses,
      this.numberOfFail, this.numberOfSuccess);

  @override
  List<Object?> get props =>
      [finishedProgresses, total, numberOfFail, numberOfSuccess];
}

class CompletedTaskState extends DetectTableApiState {
  final Task task;

  const CompletedTaskState(this.task);

  @override
  List<Object?> get props => [task];
}

class FinishAllTaskState extends DetectTableApiState {
  const FinishAllTaskState();

  @override
  List<Object?> get props => [];
}
