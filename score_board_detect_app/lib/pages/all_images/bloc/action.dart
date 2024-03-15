part of "bloc.dart";

@immutable
abstract class AllImagesAction extends Equatable {
  const AllImagesAction();

  @override
  List<Object?> get props => [];
}

class SelectImageOfToday extends AllImagesAction {
  final Set<ManageFile> images;

  const SelectImageOfToday(this.images);

  @override
  List<Object?> get props => [images];
}

class SelectImageOfYesterday extends AllImagesAction {
  final Set<ManageFile> images;

  const SelectImageOfYesterday(this.images);

  @override
  List<Object?> get props => [images];
}

class SelectImageOfLast7Days extends AllImagesAction {
  final Set<ManageFile> images;

  const SelectImageOfLast7Days(this.images);

  @override
  List<Object?> get props => [images];
}

class SelectImageOfLast30Days extends AllImagesAction {
  final Set<ManageFile> images;

  const SelectImageOfLast30Days(this.images);

  @override
  List<Object?> get props => [images];
}

class SelectImageOfOlder extends AllImagesAction {
  final Set<ManageFile> images;

  const SelectImageOfOlder(this.images);

  @override
  List<Object?> get props => [images];
}

class UnSelectImageOfToday extends AllImagesAction {
  final Set<ManageFile> images;

  const UnSelectImageOfToday(this.images);

  @override
  List<Object?> get props => [images];
}

class UnSelectImageOfYesterday extends AllImagesAction {
  final Set<ManageFile> images;

  const UnSelectImageOfYesterday(this.images);

  @override
  List<Object?> get props => [images];
}

class UnSelectImageOfLast7Days extends AllImagesAction {
  final Set<ManageFile> images;

  const UnSelectImageOfLast7Days(this.images);

  @override
  List<Object?> get props => [images];
}

class UnSelectImageOfLast30Days extends AllImagesAction {
  final Set<ManageFile> images;

  const UnSelectImageOfLast30Days(this.images);

  @override
  List<Object?> get props => [images];
}

class UnSelectImageOfOlder extends AllImagesAction {
  final Set<ManageFile> images;

  const UnSelectImageOfOlder(this.images);

  @override
  List<Object?> get props => [images];
}

class SelectAllImage extends AllImagesAction {
  final Map<KeyDay, List<ManageFile>> images;

  const SelectAllImage(this.images);

  @override
  List<Object?> get props => [images];
}

class UnSelectAllImage extends AllImagesAction {}

class SelectAllImageOfADay extends AllImagesAction {
  final KeyDay keyDay;
  final List<ManageFile> images;

  const SelectAllImageOfADay(this.keyDay, this.images);

  @override
  List<Object?> get props => [keyDay, images];
}

class UnSelectAllImageOfADay extends AllImagesAction {
  final KeyDay keyDay;

  const UnSelectAllImageOfADay(this.keyDay);

  @override
  List<Object?> get props => [keyDay];
}

class DeleteSelectedImage extends AllImagesAction {
  final MainPageBloc mainPageBloc;
  final FileType fileType;

  const DeleteSelectedImage(this.mainPageBloc, this.fileType);
}

class ImageSelectedOfADayIsEmpty extends AllImagesAction {
  final Set<KeyDay> keyDays;
  final FileType type;

  const ImageSelectedOfADayIsEmpty(this.keyDays, this.type);
}

class ShareMultipleSelectedImage extends AllImagesAction {}

class EndAllImagesAction extends AllImagesAction {}
