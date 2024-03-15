part of 'bloc.dart';

@immutable
abstract class MainPageAction extends Equatable {
  const MainPageAction();

  @override
  List<Object?> get props => [];
}

class LoadMainPage extends MainPageAction {
  const LoadMainPage();
}

class EndMainPage extends MainPageAction {
  const EndMainPage();
}

class RefreshMainPage extends MainPageAction {
  final bool status;
  const RefreshMainPage(this.status);
}

class AddNewFile extends MainPageAction {
  final ManageFile manageFile;

  const AddNewFile(this.manageFile);

  @override
  List<Object?> get props => [manageFile];
}

class DeleteFile extends MainPageAction {
  final Set<ManageFile> files;
  final FileType fileType;

  const DeleteFile(this.files, this.fileType);

  @override
  List<Object?> get props => [files, fileType];
}
