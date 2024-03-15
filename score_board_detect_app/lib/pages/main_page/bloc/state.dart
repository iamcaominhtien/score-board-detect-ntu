part of 'bloc.dart';

@immutable
class MainPageState extends Equatable {
  final bool isWorkingSpaceEmpty;
  final bool loading;
  final bool isRefresh;
  final Iterable<ManageFile>? deletedImages;
  final Iterable<ManageFile>? deletedExcels;
  final Iterable<ManageFile>? newImages;
  final Iterable<ManageFile>? newFiles;

  const MainPageState(
    this.isWorkingSpaceEmpty,
    this.loading,
    this.isRefresh, {
    this.deletedImages,
    this.deletedExcels,
    this.newImages,
    this.newFiles,
  });

  @override
  List<Object?> get props => [
        isWorkingSpaceEmpty,
        loading,
        isRefresh,
        deletedImages,
        deletedExcels,
        newImages,
        newFiles,
      ];

  MainPageState copyWith({
    bool? isWorkingSpaceEmpty,
    bool? loading,
    bool? isRefresh,
    Iterable<ManageFile>? deletedImages,
    Iterable<ManageFile>? deletedExcels,
    Iterable<ManageFile>? newImages,
    Iterable<ManageFile>? newFiles,
  }) {
    return MainPageState(
      isWorkingSpaceEmpty ?? this.isWorkingSpaceEmpty,
      loading ?? this.loading,
      isRefresh ?? this.isRefresh,
      deletedImages: deletedImages ?? this.deletedImages,
      deletedExcels: deletedExcels ?? this.deletedExcels,
      newImages: newImages ?? this.newImages,
      newFiles: newFiles ?? this.newFiles,
    );
  }
}
