part of "bloc.dart";

@immutable
class ImagesSelected extends Equatable {
  final KeyDay nameKey;
  final Set<ManageFile> listImage;

  const ImagesSelected(this.nameKey, this.listImage);

  //copyWith
  ImagesSelected copyWith({KeyDay? nameKey, Set<ManageFile>? listImage}) {
    return ImagesSelected(nameKey ?? this.nameKey, listImage ?? this.listImage);
  }

  @override
  List<Object?> get props => [nameKey, listImage];
}

@immutable
class AllImagesState extends Equatable {
  final bool haveSelected;
  final ImagesSelected today;
  final ImagesSelected yesterday;
  final ImagesSelected last7Days;
  final ImagesSelected last30Days;
  final ImagesSelected older;
  final Set<KeyDay> emptyDay; //It is NOT Image selected

  const AllImagesState({
    this.haveSelected = false,
    this.today = const ImagesSelected(KeyDay.today, {}),
    this.yesterday = const ImagesSelected(KeyDay.yesterday, {}),
    this.last7Days = const ImagesSelected(KeyDay.last7Days, {}),
    this.last30Days = const ImagesSelected(KeyDay.last30Days, {}),
    this.older = const ImagesSelected(KeyDay.older, {}),
    this.emptyDay = const <KeyDay>{},
  });

  @override
  List<Object?> get props => [
        haveSelected,
        today,
        yesterday,
        last7Days,
        last30Days,
        older,
        emptyDay,
      ];

  //copyWith
  AllImagesState copyWith(
      {bool? haveSelected,
      ImagesSelected? today,
      ImagesSelected? yesterday,
      ImagesSelected? last7Days,
      ImagesSelected? last30Days,
      ImagesSelected? older,
      Set<KeyDay>? emptyDay}) {
    return AllImagesState(
      haveSelected: haveSelected ?? this.haveSelected,
      today: today ?? this.today,
      yesterday: yesterday ?? this.yesterday,
      last7Days: last7Days ?? this.last7Days,
      last30Days: last30Days ?? this.last30Days,
      older: older ?? this.older,
      emptyDay: emptyDay ?? this.emptyDay,
    );
  }

  Iterable<ImagesSelected> get allImagesSelected => [
        today,
        yesterday,
        last7Days,
        last30Days,
        older,
      ];

  ImagesSelected getExactlyImagesSelected(KeyDay keyDay) {
    switch (keyDay) {
      case KeyDay.today:
        return today;
      case KeyDay.yesterday:
        return yesterday;
      case KeyDay.last7Days:
        return last7Days;
      case KeyDay.last30Days:
        return last30Days;
      case KeyDay.older:
        return older;
      default:
        return today;
    }
  }

  int countImagesSelected() {
    int count = 0;
    for (var item in allImagesSelected) {
      count += item.listImage.length;
    }
    return count;
  }

  bool get haveAnySelected {
    bool have = false;
    for (var item in allImagesSelected) {
      if (item.listImage.isNotEmpty) {
        have = true;
        break;
      }
    }
    return have;
  }

  AllImagesState createNewInstanceFromMe(Map<KeyDay, List<ManageFile>> myMap) {
    var newInstance = AllImagesState(
      haveSelected: haveSelected,
      today: today.copyWith(
          listImage: myMap[KeyDay.today]?.toSet() ?? today.listImage),
      yesterday: yesterday.copyWith(
          listImage: myMap[KeyDay.yesterday]?.toSet() ?? yesterday.listImage),
      last7Days: last7Days.copyWith(
          listImage: myMap[KeyDay.last7Days]?.toSet() ?? last7Days.listImage),
      last30Days: last30Days.copyWith(
          listImage: myMap[KeyDay.last30Days]?.toSet() ?? last30Days.listImage),
      older: older.copyWith(
          listImage: myMap[KeyDay.older]?.toSet() ?? older.listImage),
      emptyDay: emptyDay,
    );
    return newInstance.copyWith(haveSelected: newInstance.haveAnySelected);
  }

  ///keyDays == null => clear all
  AllImagesState clearExactlyAllImageOfImagesSelected(
      Iterable<KeyDay>? keyDays) {
    if (keyDays != null) {
      var newInstance = AllImagesState(
        haveSelected: haveSelected,
        today: today.copyWith(
            listImage: keyDays.contains(KeyDay.today) ? {} : today.listImage),
        yesterday: yesterday.copyWith(
            listImage:
                keyDays.contains(KeyDay.yesterday) ? {} : yesterday.listImage),
        last7Days: last7Days.copyWith(
            listImage:
                keyDays.contains(KeyDay.last7Days) ? {} : last7Days.listImage),
        last30Days: last30Days.copyWith(
            listImage: keyDays.contains(KeyDay.last30Days)
                ? {}
                : last30Days.listImage),
        older: older.copyWith(
            listImage: keyDays.contains(KeyDay.older) ? {} : older.listImage),
      );
      return newInstance.copyWith(haveSelected: newInstance.haveAnySelected);
    } else {
      var newInstance = AllImagesState(
        haveSelected: false,
        today: today.copyWith(listImage: {}),
        yesterday: yesterday.copyWith(listImage: {}),
        last7Days: last7Days.copyWith(listImage: {}),
        last30Days: last30Days.copyWith(listImage: {}),
        older: older.copyWith(listImage: {}),
      );
      return newInstance;
    }
  }

  AllImagesState clearExactlySomeImagesOfImagesSelected(
      Map<KeyDay, Set<ManageFile>> myMap) {
    var newInstance = AllImagesState(
      haveSelected: haveSelected,
      today: today.copyWith(
          listImage: today.listImage.difference(myMap[KeyDay.today] ?? {})),
      yesterday: yesterday.copyWith(
          listImage:
              yesterday.listImage.difference(myMap[KeyDay.yesterday] ?? {})),
      last7Days: last7Days.copyWith(
          listImage:
              last7Days.listImage.difference(myMap[KeyDay.last7Days] ?? {})),
      last30Days: last30Days.copyWith(
          listImage:
              last30Days.listImage.difference(myMap[KeyDay.last30Days] ?? {})),
      older: older.copyWith(
          listImage: older.listImage.difference(myMap[KeyDay.older] ?? {})),
    );
    return newInstance.copyWith(haveSelected: newInstance.haveAnySelected);
  }
}
