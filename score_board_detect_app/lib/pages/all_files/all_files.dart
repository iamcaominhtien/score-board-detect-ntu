import 'dart:io';

import 'package:collection/collection.dart';
import 'package:document_file_save_plus/document_file_save_plus.dart';

// import 'package:excel/excel.dart';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:score_board_detect/pages/all_images/bloc/bloc.dart';
import 'package:score_board_detect/pages/home/bloc/bloc.dart';
import 'package:score_board_detect/pages/main_page/bloc/bloc.dart';
import 'package:score_board_detect/service/helper.dart';
import 'package:score_board_detect/service/manage_files/excel/my_excel.dart';
import 'package:score_board_detect/service/manage_files/excel/row_excel.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';
import 'package:score_board_detect/service/manage_files/sql/manage_files_db.dart';
import 'package:score_board_detect/service/notify.dart';

class AllFilesBloc extends AllImagesBloc {}

class AllFiles extends StatefulWidget {
  const AllFiles({Key? key}) : super(key: key);
  static const routeName = '/all-files';

  @override
  State<AllFiles> createState() => _AllFilesState();
}

class _AllFilesState extends State<AllFiles> {
  Map<KeyDay, List<ManageFile>> _fileSplittedByDay = {};
  Map<KeyDay, GlobalKey<AnimatedListState>> _keyListFileSplittedByDay = {};
  final today = DateTime.now();
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  late final MainPageBloc _mainPageBloc;
  late final AllFilesBloc _allFilesBloc;
  late final BottomBarBloc _bottomBarBloc;

  @override
  void initState() {
    super.initState();
    _mainPageBloc = BlocProvider.of<MainPageBloc>(context);
    _bottomBarBloc = BlocProvider.of<BottomBarBloc>(context);
    _allFilesBloc = BlocProvider.of<AllFilesBloc>(context);
    _splitFileByDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<MainPageBloc, MainPageState>(
        child: _localBody(),
        listener: (context, mainPageState) {
          if (mainPageState.isRefresh) {
            var imageSplittedByDayTemp = _splitFileByDayForCheck();
            if (const DeepCollectionEquality()
                    .equals(imageSplittedByDayTemp, _fileSplittedByDay) ==
                false) {
              _fileSplittedByDay = imageSplittedByDayTemp;
            }
            _mainPageBloc.add(const RefreshMainPage(false));
          } else {
            if (mainPageState.newFiles != null) {
              for (var excelFile in mainPageState.newFiles!) {
                _addFile(KeyDay.today, excelFile, index: 0);
              }
            }
            if (mainPageState.deletedExcels != null) {
              for (var file in mainPageState.deletedExcels!) {
                _deleteFile(_determineKeyDay(file.created), file);
              }
            }
          }
          _checkEmptyDay();
        },
        listenWhen: (previous, current) {
          return current.isRefresh == true ||
              !const DeepCollectionEquality()
                  .equals(previous.newFiles, current.newFiles) ||
              !const DeepCollectionEquality()
                  .equals(previous.deletedExcels, current.deletedExcels);
        },
      ),
      bottomNavigationBar: _buildToolBarBottom(),
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
                      _allFilesBloc.add(ShareMultipleSelectedImage());
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
                      _allFilesBloc.add(DeleteSelectedImage(
                          _mainPageBloc, FileType.documentExcel));
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
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

  Widget _localBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        await _mainPageBloc.loadFiles();
        _mainPageBloc.add(const RefreshMainPage(true));
        setState(() {});
      },
      child: Column(
        children: [
          _buildToolbarAbove(),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _fileSplittedByDay.keys.map(
                      (key) {
                        return _animatedListPattern(key);
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarAbove() {
    return BlocBuilder<AllFilesBloc, AllImagesState>(
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
                  'file_managers'.tr,
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ],
            ),
          );
        }

        int count = state.countImagesSelected();
        bool selectedAll = (count == _mainPageBloc.excelFileList.length);

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
                    _allFilesBloc.add(UnSelectAllImage());
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
                    _allFilesBloc.add(UnSelectAllImage());
                  } else {
                    _allFilesBloc.add(SelectAllImage(_fileSplittedByDay));
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

  Widget _animatedListPattern(KeyDay key) {
    return BlocBuilder<AllFilesBloc, AllImagesState>(
      builder: (context, state) {
        if (_fileSplittedByDay[key]!.isEmpty) {
          return const SizedBox(
            height: 0,
          );
        }
        var selected = state.getExactlyImagesSelected(key).listImage;
        bool selectedAll = selected.length == _fileSplittedByDay[key]!.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  if (state.haveSelected)
                    ElevatedButton(
                      onPressed: () {
                        // check if all image is selected
                        if (!selectedAll) {
                          _allFilesBloc.add(SelectAllImageOfADay(
                              key, _fileSplittedByDay[key]!));
                        } else {
                          _allFilesBloc.add(UnSelectAllImageOfADay(key));
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
            AnimatedList(
              itemBuilder: (context, index, animation) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Slidable(
                    key: const ValueKey(0),
                    endActionPane: ActionPane(
                      extentRatio: 0.7,
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            _mainPageBloc.add(
                              DeleteFile(
                                {_fileSplittedByDay[key]![index]},
                                FileType.documentExcel,
                              ),
                            );
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_forever,
                          label: 'delete'.tr,
                        ),
                        SlidableAction(
                          onPressed: (context) {
                            Helper.shareFile(
                                _fileSplittedByDay[key]![index].path);
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.share,
                          label: 'share'.tr,
                        ),
                        SlidableAction(
                          onPressed: (context) async {
                            String fileName =
                                _fileSplittedByDay[key]![index].name ??
                                    "SBD_Excel_File${DateTime.now()}";
                            File file =
                                File(_mainPageBloc.excelFileList[index].path);
                            DocumentFileSavePlus()
                                .saveFile(await file.readAsBytes(), fileName,
                                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
                                .then((value) {
                              Fluttertoast.showToast(
                                  msg: "file_save_in_download_folder".tr);
                            }).catchError((e) {
                              Fluttertoast.showToast(
                                  msg: "file_save_failed".tr);
                            });
                          },
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          icon: Icons.save_alt,
                          label: 'save'.tr,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onLongPress: () {
                        _toggleSelectFile(
                            _fileSplittedByDay[key]![index],
                            selected.contains(_fileSplittedByDay[key]![index]),
                            key);
                      },
                      behavior: HitTestBehavior.translucent,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _openFile(_fileSplittedByDay[key]![index].path);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0,
                            end: 1,
                          ).animate(animation),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: SizedBox(
                                height: 60,
                                child: Stack(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          width: 60,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.blue,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.file_copy,
                                            size: 30,
                                            color:
                                                _fileSplittedByDay[key]![index]
                                                            .type ==
                                                        FileType.documentExcel
                                                    ? Colors.green
                                                    : null,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _fileSplittedByDay[key]![index]
                                                        .name ??
                                                    "No name",
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onBackground,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                '${_fileSplittedByDay[key]![index].getSize}, ${Helper.getTime(_fileSplittedByDay[key]![index].created ?? DateTime.now())}',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onBackground
                                                      .withOpacity(0.7),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 35,
                                          child: !state.haveSelected
                                              ? _openPopupMenu(
                                                  key,
                                                  index,
                                                  selected.contains(
                                                      _fileSplittedByDay[key]![
                                                          index]),
                                                )
                                              : null,
                                        )
                                      ],
                                    ),
                                    if (selected.contains(
                                        _fileSplittedByDay[key]![index]))
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    if (state.haveSelected)
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        right: 5,
                                        child: SizedBox(
                                          width: 20,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _toggleSelectFile(
                                                  _fileSplittedByDay[key]![
                                                      index],
                                                  selected.contains(
                                                      _fileSplittedByDay[key]![
                                                          index]),
                                                  key);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              shape: const CircleBorder(
                                                side: BorderSide(
                                                  color: Colors.black,
                                                  width: 1,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(0),
                                              visualDensity:
                                                  const VisualDensity(
                                                horizontal: VisualDensity
                                                    .minimumDensity,
                                                vertical: VisualDensity
                                                    .minimumDensity,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(3),
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    selected.contains(
                                                            _fileSplittedByDay[
                                                                key]![index])
                                                        ? Colors.blue
                                                        : Colors.transparent,
                                                radius: 8,
                                                child: Container(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              initialItemCount: _fileSplittedByDay[key]!.length,
              key: _keyListFileSplittedByDay[key]!,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
            ),
          ],
        );
      },
      buildWhen: (previous, current) {
        return (previous.getExactlyImagesSelected(key) !=
                current.getExactlyImagesSelected(key)) ||
            (previous.haveSelected != current.haveSelected) ||
            const DeepCollectionEquality()
                .equals(previous.emptyDay, current.emptyDay) ||
            (previous.emptyDay.contains(key) != current.emptyDay.contains(key));
      },
    );
  }

  Align _openPopupMenu(KeyDay key, int index, bool isSelected) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<int>(
        padding: EdgeInsets.zero,
        offset: const Offset(-30, 45),
        iconSize: 25,
        icon: Icon(
          Icons.more_vert,
          color: Theme.of(context).colorScheme.onBackground,
        ),
        color: Theme.of(context).colorScheme.background,
        onSelected: (value) {
          switch (value) {
            case 0:
              _toggleSelectFile(
                  _fileSplittedByDay[key]![index], isSelected, key);
              break;
            case 1:
              _openFile(_fileSplittedByDay[key]![index].path);
              break;
            case 2:
              Helper.shareFile(_fileSplittedByDay[key]![index].path);
              break;
            case 3:
              break;
            case 4:
              _mainPageBloc.add(
                DeleteFile(
                  {_fileSplittedByDay[key]![index]},
                  FileType.documentExcel,
                ),
              );
              break;
            case 5:
              _createReport(key, index);
              break;
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<int>(
            value: 0,
            child: Text('select'.tr),
          ),
          PopupMenuItem<int>(
            value: 1,
            child: Text('open'.tr),
          ),
          PopupMenuItem<int>(
            value: 2,
            child: Text('share'.tr),
          ),
          // const PopupMenuItem<int>(
          //   value: 3,
          //   child: Text('Rename'),
          // ),
          PopupMenuItem<int>(
            value: 4,
            child: Text('delete'.tr),
          ),
          PopupMenuItem<int>(
            value: 5,
            child: Text('check'.tr),
          ),
        ],
        elevation: 5,
      ),
    );
  }

  Future<void> _createReport(KeyDay key, int index) async {
    try {
      //choose file
      var listFilePath =
          await Helper.pickFile(['xlsx', 'xls'], multipleFile: false);
      if (listFilePath == null || listFilePath.isEmpty) return;

      //_fileSplittedByDay[key]![index].path
      // MyExcel.open(listFilePath.first);
      // return;
      // var src = await MyExcel.loadExcel(_fileSplittedByDay[key]![index].path);
      // var des = await MyExcel.loadExcel(listFilePath.first);
      var [src, des] = await Future.wait([
        MyExcel.loadExcel(_fileSplittedByDay[key]![index].path),
        MyExcel.loadExcel(listFilePath.first)
      ]);
      if (src == null || des == null) {
        Fluttertoast.showToast(msg: "some_thing_went_wrong".tr);
        return;
      }

      //define getRowData function
      (int, int, List<RowExcel>) getRowDataSrc(excel.Excel des, String sheet) {
        int paddingTop = 0;
        int paddingLeft = 0;
        var rows = des.tables[sheet]?.rows ?? [];
        List<RowExcel> arr = [];
        //find the position of "STT"
        for (int idx = 0; idx < rows.length; idx++) {
          for (int jdx = 0; jdx < rows[idx].length; jdx++) {
            if (rows[idx][jdx]?.value.toString().toLowerCase() == "STT".toLowerCase()) {
              paddingTop = idx;
              paddingLeft = jdx;
              break;
            }
          }
        }

        List<excel.Data?> row;
        for (int idx = paddingTop + 1; idx < rows.length; idx++) {
          row = rows[idx];
          double? dKt = row[paddingLeft + 5]?.value != null
              ? double.tryParse(row[paddingLeft + 5]!.value!.toString())
              : null;
          double? dGk = row[paddingLeft + 6]?.value != null
              ? double.tryParse(row[paddingLeft + 6]!.value!.toString())
              : null;
          double? dThi = row[paddingLeft + 7]?.value != null
              ? double.tryParse(row[paddingLeft + 7]!.value!.toString())
              : null;
          try {
            arr.add(RowExcel(
              stt: row[paddingLeft]?.value.toString() ?? "",
              id: row[paddingLeft + 1]?.value.toString() ?? "",
              dKt: '${dKt ?? ''}',
              dGk: '${dGk ?? ''}',
              dThi: '${dThi ?? ''}',
            ));
            // print('${dKt ?? ''} - ${dGk ?? ''} - ${dThi ?? ''}');
          } catch (e) {
            continue;
          }
        }

        return (paddingLeft, paddingTop, arr);
      }

      (int, int, List<RowExcel>) getRowDataDes(excel.Excel des, String sheet) {
        int paddingTop = 0;
        int paddingLeft = 0;
        var rows = des.tables[sheet]?.rows ?? [];
        List<RowExcel> arr = [];
        //find the position of "STT"
        for (int idx = 0; idx < rows.length; idx++) {
          for (int jdx = 0; jdx < rows[idx].length; jdx++) {
            if (rows[idx][jdx]?.value.toString() == "STT") {
              paddingTop = idx;
              paddingLeft = jdx;
              break;
            }
          }
        }

        List<excel.Data?> row;
        for (int idx = paddingTop + 1; idx < rows.length; idx++) {
          row = rows[idx];
          double? dKt = row[paddingLeft + 4]?.value != null
              ? double.tryParse(row[paddingLeft + 4]!.value!.toString())
              : null;
          double? dGk = row[paddingLeft + 5]?.value != null
              ? double.tryParse(row[paddingLeft + 5]!.value!.toString())
              : null;
          double? dThi = row[paddingLeft + 6]?.value != null
              ? double.tryParse(row[paddingLeft + 6]!.value!.toString())
              : null;
          try {
            arr.add(RowExcel(
              stt: row[paddingLeft]?.value.toString() ?? "",
              id: row[paddingLeft + 1]?.value.toString() ?? "",
              dKt: '${dKt ?? ''}',
              dGk: '${dGk ?? ''}',
              dThi: '${dThi ?? ''}',
            ));
            // print('${dKt ?? ''} - ${dGk ?? ''} - ${dThi ?? ''}');
          } catch (e) {
            continue;
          }
        }

        return (paddingLeft, paddingTop, arr);
      }

      // List<RowExcel> rowsSrc;
      var (_, _, List<RowExcel> rowsSrc) =
          getRowDataSrc(src, src.tables.keys.first);
      var (paddingLeft, paddingTop, List<RowExcel> rowsDes) =
          getRowDataDes(des, des.tables.keys.first);

      Map<String, int> analysis = {};
      for (var rowDes in rowsDes) {
        for (var rowSrc in rowsSrc) {
          bool isFounded = false;
          if (rowDes.id == null) continue;
          if (rowDes.compareIDWith(rowSrc) > 0.7) {
            isFounded = true;
            analysis[rowDes.id!] = rowDes.compareTo(rowSrc);
          } else if (rowSrc.id != null &&
              ((rowDes.id?.contains(rowSrc.id!) ?? false) ||
                  (rowSrc.id?.contains(rowDes.id!) ?? false))) {
            isFounded = true;
            analysis[rowDes.id!] = rowDes.compareTo(rowSrc);
          }
          if (isFounded) {
            rowsSrc.remove(rowSrc);
            break;
          }
        }
      }

      //create new excel from des
      var desRow = des.tables[des.tables.keys.first]?.rows ?? [];
      for (int idx = paddingTop + 1; idx < desRow.length; idx++) {
        var row = desRow[idx];
        String id = row[paddingLeft + 1]?.value.toString() ?? "";
        if (id == "") continue;
        if (analysis[id] == 1) {
          //add color green to row
          for (int jdx = 0; jdx < row.length; jdx++) {
            des.tables[des.tables.keys.first]?.rows[idx][jdx]?.cellStyle =
                excel.CellStyle(
                  backgroundColorHex: "#00FF00",
                  leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
                  rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
                  topBorder: excel.Border(
                      borderStyle: excel.BorderStyle.Thin,
                      borderColorHex: '#000000'),
                  bottomBorder: excel.Border(
                      borderStyle: excel.BorderStyle.Thin,
                      borderColorHex: '#000000'),
                );
          }
        } else if (analysis[id] == 2) {
          //add color yellow to row
          for (int jdx = 0; jdx < row.length; jdx++) {
            des.tables[des.tables.keys.first]?.rows[idx][jdx]?.cellStyle =
                excel.CellStyle(
                  backgroundColorHex: "#FFFF00",
                  leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
                  rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
                  topBorder: excel.Border(
                      borderStyle: excel.BorderStyle.Thin,
                      borderColorHex: '#000000'),
                  bottomBorder: excel.Border(
                      borderStyle: excel.BorderStyle.Thin,
                      borderColorHex: '#000000'),
                );
          }
        } else if (analysis[id] == 3) {
          //add color red to row
          for (int jdx = 0; jdx < row.length; jdx++) {
            des.tables[des.tables.keys.first]?.rows[idx][jdx]?.cellStyle =
                excel.CellStyle(
                  backgroundColorHex: "#FF0000",
                  leftBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
                  rightBorder: excel.Border(borderStyle: excel.BorderStyle.Thin),
                  topBorder: excel.Border(
                      borderStyle: excel.BorderStyle.Thin,
                      borderColorHex: '#000000'),
                  bottomBorder: excel.Border(
                      borderStyle: excel.BorderStyle.Thin,
                      borderColorHex: '#000000'),
                );
          }
        }
        analysis.remove(id);
      }

      //save to new file
      var fileName = "report_${DateTime.now().millisecondsSinceEpoch}";
      var savedFile = await MyExcel.saveExcelFile(des, fileName);
      ManageFile? savedManageFile = await ManageFilesDB.createManageFile(
          savedFile.path, FileType.documentExcel);
      if (savedManageFile == null) {
        Fluttertoast.showToast(msg: "some_thing_went_wrong".tr);
        return;
      }
      _mainPageBloc.add(AddNewFile(savedManageFile));
      Fluttertoast.showToast(msg: "export_report_successfully".tr);
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      Fluttertoast.showToast(msg: "some_thing_went_wrong".tr);
    }
  }

  void _addFile(KeyDay key, ManageFile element, {int? index}) {
    if (!_fileSplittedByDay[key]!.contains(element)) {
      index ??= _fileSplittedByDay[key]!.length;
      _fileSplittedByDay[key]!.insert(index, element);
      _keyListFileSplittedByDay[key]!
          .currentState
          ?.insertItem(index, duration: const Duration(milliseconds: 800));
    }
  }

  int _deleteFile(KeyDay key, ManageFile element) {
    final index = _fileSplittedByDay[key]!.indexOf(element);
    if (index != -1) {
      _fileSplittedByDay[key]!.removeAt(index);
      _keyListFileSplittedByDay[key]!.currentState?.removeItem(
          index, (context, animation) => Container(),
          duration: const Duration(milliseconds: 800));
    }
    return index;
  }

  KeyDay _determineKeyDay(DateTime? createdDay) {
    final date = DateTime.fromMillisecondsSinceEpoch(
        (createdDay ?? DateTime.now()).millisecondsSinceEpoch);

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return KeyDay.today;
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return KeyDay.yesterday;
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return KeyDay.last7Days;
    } else if (date.isAfter(today.subtract(const Duration(days: 30)))) {
      return KeyDay.last30Days;
    } else {
      return KeyDay.older;
    }
  }

  void _toggleSelectFile(ManageFile excelFile, bool selected, KeyDay keyDay) {
    switch (keyDay) {
      case KeyDay.today:
        selected
            ? _allFilesBloc.add(UnSelectImageOfToday({excelFile}))
            : _allFilesBloc.add(SelectImageOfToday({excelFile}));
        break;
      case KeyDay.yesterday:
        selected
            ? _allFilesBloc.add(UnSelectImageOfYesterday({excelFile}))
            : _allFilesBloc.add(SelectImageOfYesterday({excelFile}));
        break;
      case KeyDay.last7Days:
        selected
            ? _allFilesBloc.add(UnSelectImageOfLast7Days({excelFile}))
            : _allFilesBloc.add(SelectImageOfLast7Days({excelFile}));
        break;
      case KeyDay.last30Days:
        selected
            ? _allFilesBloc.add(UnSelectImageOfLast30Days({excelFile}))
            : _allFilesBloc.add(SelectImageOfLast30Days({excelFile}));
        break;
      case KeyDay.older:
        selected
            ? _allFilesBloc.add(UnSelectImageOfOlder({excelFile}))
            : _allFilesBloc.add(SelectImageOfOlder({excelFile}));
        break;
      default:
        break;
    }
  }

  void _splitFileByDay() {
    _fileSplittedByDay = {
      KeyDay.today: <ManageFile>[],
      KeyDay.yesterday: <ManageFile>[],
      KeyDay.last7Days: <ManageFile>[],
      KeyDay.last30Days: <ManageFile>[],
      KeyDay.older: <ManageFile>[]
    };
    _keyListFileSplittedByDay = {
      KeyDay.today: GlobalKey<AnimatedListState>(),
      KeyDay.yesterday: GlobalKey<AnimatedListState>(),
      KeyDay.last7Days: GlobalKey<AnimatedListState>(),
      KeyDay.last30Days: GlobalKey<AnimatedListState>(),
      KeyDay.older: GlobalKey<AnimatedListState>(),
    };

    for (var element in _mainPageBloc.excelFileList) {
      _addFile(_determineKeyDay(element.created), element);
    }
    _checkEmptyDay();
  }

  Map<KeyDay, List<ManageFile>> _splitFileByDayForCheck() {
    var fileSplittedByDay = {
      KeyDay.today: <ManageFile>[],
      KeyDay.yesterday: <ManageFile>[],
      KeyDay.last7Days: <ManageFile>[],
      KeyDay.last30Days: <ManageFile>[],
      KeyDay.older: <ManageFile>[]
    };
    for (var element in _mainPageBloc.excelFileList) {
      fileSplittedByDay[_determineKeyDay(element.created)]!.add(element);
    }

    return fileSplittedByDay;
  }

  Future<void> _openFile(String path) async {
    var error = await MyExcel.open(
      path,
    );
    if (error != null) {
      Notify.getxSnackBarError(error);
    }
  }

  void _checkEmptyDay() {
    Set<KeyDay> emptyDays = {};
    for (var key in _fileSplittedByDay.keys) {
      if (_fileSplittedByDay[key]!.isEmpty) {
        emptyDays.add(key);
      }
    }
    _allFilesBloc
        .add(ImageSelectedOfADayIsEmpty(emptyDays, FileType.documentExcel));
  }
}
