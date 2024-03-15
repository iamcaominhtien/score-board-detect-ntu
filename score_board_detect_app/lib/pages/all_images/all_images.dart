import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:score_board_detect/pages/all_images/bloc/bloc.dart';
import 'package:score_board_detect/pages/all_images/image_preview_animation/image_preview_animation.dart';
import 'package:score_board_detect/pages/home/bloc/bloc.dart';
import 'package:score_board_detect/pages/main_page/bloc/bloc.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';

class AllImages extends StatefulWidget {
  const AllImages({Key? key}) : super(key: key);
  static const routeName = '/all-images';

  @override
  State<AllImages> createState() => _AllImagesState();
}

class _AllImagesState extends State<AllImages> {
  Map<KeyDay, List<ManageFile>> _imageSplittedByDay = {};
  final today = DateTime.now();
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  late final MainPageBloc _mainPageBloc;
  late final AllImagesBloc _allImagesBloc;
  late final BottomBarBloc _bottomBarBloc;

  @override
  void initState() {
    super.initState();
    _mainPageBloc = BlocProvider.of<MainPageBloc>(context);
    _allImagesBloc = BlocProvider.of<AllImagesBloc>(context);
    _bottomBarBloc = BlocProvider.of<BottomBarBloc>(context);
    _imageSplittedByDay = _splitImageByDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<MainPageBloc, MainPageState>(
        child: Column(
          children: [
            _buildToolbarAbove(),
            Expanded(child: _localBody()),
          ],
        ),
        listener: (context, state) {
          Map<KeyDay, List<ManageFile>> imageSplittedByDayTemp =
              _splitImageByDay();
          if (state.isRefresh) {
            if (const DeepCollectionEquality()
                    .equals(imageSplittedByDayTemp, _imageSplittedByDay) ==
                false) {
              _imageSplittedByDay = imageSplittedByDayTemp;
              setState(() {});
            }
            _mainPageBloc.add(const RefreshMainPage(false));
          }
        },
        listenWhen: (previous, current) => current.isRefresh == true,
      ),
      bottomNavigationBar: _buildToolBarBottom(),
    );
  }

  Widget _localBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        await _mainPageBloc.loadFiles();
        _mainPageBloc.add(const RefreshMainPage(true));
      },
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              children: _imageSplittedByDay.keys.map(
                (key) {
                  gridView(
                          String label,
                          List<ManageFile> list,
                          Set<ManageFile>? selected,
                          bool haveSelected,
                          KeyDay keyDay) =>
                      _gridImageByDayPattern(
                          label, list, selected, haveSelected, keyDay);
                  if (key == KeyDay.today) {
                    return _buildStreamForImageOfToday(key, gridView);
                  }
                  if (_imageSplittedByDay[key]!.isNotEmpty) {
                    return _buildBlocForOtherDays(key, gridView);
                  }
                  return const SizedBox(
                    height: 0,
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Map<KeyDay, List<ManageFile>> _splitImageByDay() {
    var imageSplittedByDay = {
      KeyDay.today: <ManageFile>[],
      KeyDay.yesterday: <ManageFile>[],
      KeyDay.last7Days: <ManageFile>[],
      KeyDay.last30Days: <ManageFile>[],
      KeyDay.older: <ManageFile>[]
    };
    for (var element in _mainPageBloc.imageList) {
      final date = DateTime.fromMillisecondsSinceEpoch(
          (element.created ?? DateTime.now()).millisecondsSinceEpoch);
      if (date.day == today.day &&
          date.month == today.month &&
          date.year == today.year) {
        imageSplittedByDay[KeyDay.today]!.add(element);
      } else if (date.day == yesterday.day &&
          date.month == yesterday.month &&
          date.year == yesterday.year) {
        imageSplittedByDay[KeyDay.yesterday]!.add(element);
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        imageSplittedByDay[KeyDay.last7Days]!.add(element);
      } else if (date.isAfter(today.subtract(const Duration(days: 30)))) {
        imageSplittedByDay[KeyDay.last30Days]!.add(element);
      } else {
        imageSplittedByDay[KeyDay.older]!.add(element);
      }
    }

    return imageSplittedByDay;
  }

  Widget _buildToolbarAbove() {
    return BlocBuilder<AllImagesBloc, AllImagesState>(
      builder: (context, state) {
        _bottomBarBloc.add(ChangeShow(!state.haveSelected));

        if (!state.haveSelected) {
          return Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            height: 60,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Text(
                  'photo_gallery'.tr,
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ],
            ),
          );
        }

        int count = state.countImagesSelected();
        bool selectedAll = (count == _mainPageBloc.imageList.length);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 0.5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: IconButton(
                  onPressed: () {
                    _allImagesBloc.add(UnSelectAllImage());
                  },
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
              Text(
                "$count ${'item_selected'.tr}",
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
              IconButton(
                onPressed: () {
                  if (selectedAll) {
                    _allImagesBloc.add(UnSelectAllImage());
                  } else {
                    _allImagesBloc.add(SelectAllImage(_imageSplittedByDay));
                  }
                },
                icon: Icon(
                  Icons.select_all_outlined,
                  color: selectedAll
                      ? Theme.of(context).colorScheme.onBackground
                      : null,
                ),
              )
            ],
          ),
        );
      },
      buildWhen: (previous, current) => previous != current,
    );
  }

  Widget _buildToolBarBottom() {
    return BlocBuilder<BottomBarBloc, BottomBarState>(
      builder: (context, state) => !state.show
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 0),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 0.5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      _allImagesBloc.add(ShareMultipleSelectedImage());
                    },
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  IconButton(
                    onPressed: () {
                      // _mainPageBloc.add(DeleteFile([]));
                      _allImagesBloc.add(
                          DeleteSelectedImage(_mainPageBloc, FileType.image));
                    },
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ],
              ),
            )
          : const SizedBox(
              height: 0,
            ),
      buildWhen: (previous, current) => previous.show != current.show,
    );
  }

  Widget _buildBlocForOtherDays(
      KeyDay key,
      Widget Function(String label, List<ManageFile> list,
              Set<ManageFile>? selected, bool haveSelected, KeyDay keyDay)
          gridView) {
    return BlocBuilder<MainPageBloc, MainPageState>(
      builder: (context, mainPageState) {
        return BlocBuilder<AllImagesBloc, AllImagesState>(
          builder: (context, state) {
            if (mainPageState.deletedImages != null) {
              _imageSplittedByDay[key]!.removeWhere(
                  (element) => mainPageState.deletedImages!.contains(element));
            }
            return gridView(
                key.name,
                _imageSplittedByDay[key]!,
                state.getExactlyImagesSelected(key).listImage,
                state.haveSelected,
                key);
          },
          buildWhen: (previous, current) {
            return (previous.getExactlyImagesSelected(key) !=
                    current.getExactlyImagesSelected(key)) ||
                (previous.haveSelected != current.haveSelected);
          },
        );
      },
      buildWhen: (previous, current) {
        return !const DeepCollectionEquality()
            .equals(previous.deletedImages, current.deletedImages);
      },
    );
  }

  Widget _buildStreamForImageOfToday(
      KeyDay key,
      Column Function(String label, List<ManageFile> list,
              Set<ManageFile>? selected, bool haveSelected, KeyDay keyDay)
          gridView) {
    return BlocBuilder<MainPageBloc, MainPageState>(
      builder: (context, state) {
        Function widgetReturn =
            (Set<ManageFile>? selected, bool haveSelected) =>
                const SizedBox(height: 0);
        if (state.newImages != null) {
          for (var imageFile in state.newImages!) {
            if (_imageSplittedByDay[KeyDay.today]!.contains(imageFile) ==
                false) {
              _imageSplittedByDay[KeyDay.today]!.insert(0, imageFile);
            }
          }
        }
        if (state.deletedImages != null) {
          for (var imageFile in state.deletedImages!) {
            if (_imageSplittedByDay[KeyDay.today]!.contains(imageFile) ==
                true) {
              _imageSplittedByDay[KeyDay.today]!.remove(imageFile);
            }
          }
        }
        var list = _imageSplittedByDay[key]!;
        if (list.isNotEmpty) {
          widgetReturn = (Set<ManageFile>? selected, bool haveSelected) =>
              gridView(key.name, list, selected, haveSelected, KeyDay.today);
        }
        return BlocBuilder<AllImagesBloc, AllImagesState>(
          builder: (context, state) {
            return widgetReturn(state.today.listImage, state.haveSelected);
          },
          buildWhen: (previous, current) {
            return (previous.today != current.today) ||
                (previous.haveSelected != current.haveSelected);
          },
        );
      },
      buildWhen: (previous, current) {
        return !const DeepCollectionEquality()
                .equals(previous.newImages, current.newImages) ||
            !const DeepCollectionEquality()
                .equals(previous.deletedImages, current.deletedImages);
      },
    );
  }

  Column _gridImageByDayPattern(String label, List<ManageFile> list,
      Set<ManageFile>? selected, bool haveSelected, KeyDay keyDay) {
    bool selectedAll = ((selected ?? <ManageFile>{}).length == list.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
              ),
              if (haveSelected)
                ElevatedButton(
                  onPressed: () {
                    //check if all image is selected
                    if (!selectedAll) {
                      _allImagesBloc.add(SelectAllImageOfADay(keyDay, list));
                    } else {
                      _allImagesBloc.add(UnSelectAllImageOfADay(keyDay));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 20),
                    visualDensity: const VisualDensity(
                      horizontal: VisualDensity.minimumDensity,
                      vertical: VisualDensity.minimumDensity,
                    ),
                  ),
                  child: Text(
                    !selectedAll ? "Select all" : "Deselect",
                    style: const TextStyle(fontSize: 12),
                  ),
                )
            ],
          ),
        ),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5),
          itemBuilder: (context, index) {
            return ImagePreviewAnimation(
              list[index],
              keyDay,
              selected?.contains(list[index]) ?? false,
              haveSelected,
            );
          },
          shrinkWrap: true,
          itemCount: list.length,
          physics: const NeverScrollableScrollPhysics(),
          addAutomaticKeepAlives: true,
        ),
      ],
    );
  }
}
