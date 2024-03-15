part of 'bloc.dart';

class Task extends Equatable {
  late final int id;
  final ManageFile imageFile;
  final String? url;
  final bool finished;
  final bool success;
  final ManageFile? result;

  Task(this.imageFile,
      {this.url,
      this.finished = false,
      this.success = false,
      this.result,
      int? id}) {
    this.id = id ?? UniqueKey().hashCode;
  }

  @override
  List<Object?> get props => [imageFile, id];

  //copyWith
  Task copyWith({
    String? url,
    bool? finished,
    bool? success,
    ManageFile? result,
  }) {
    return Task(
      imageFile,
      id: id,
      url: url ?? this.url,
      finished: finished ?? this.finished,
      success: success ?? this.success,
      result: result ?? this.result,
    );
  }
}
