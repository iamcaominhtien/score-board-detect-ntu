import 'dart:io';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:get/get.dart';
import 'package:score_board_detect/pages/all_images/image_preview_animation/image_preview.dart';
import 'package:score_board_detect/pages/main_page/bloc/bloc.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as auth_ui;
import 'package:score_board_detect/service/helper.dart';
import 'package:score_board_detect/service/manage_files/excel/my_excel.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';
import 'package:score_board_detect/service/notify.dart';

class MainPage extends StatefulWidget {
  final PageController pageController;

  const MainPage(this.pageController, {Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final MainPageBloc _mainPageBloc;
  late final PageController _homePageController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _mainPageBloc = context.read<MainPageBloc>();
    _mainPageBloc.add(const LoadMainPage());
    // ManageFilesDB().removeAllManageFiles();
    _homePageController = widget.pageController;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(),
        Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            backgroundColor: Theme.of(context).colorScheme.background,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.userChanges(),
                  builder: (context, snapshot) {
                    return Column(
                      children: [
                        auth_ui.UserAvatar(
                          key: ValueKey(snapshot.data?.photoURL ?? 'avatar'),
                          placeholderColor:
                              Theme.of(context).colorScheme.onBackground,
                        ),
                        auth_ui.EditableUserDisplayName(
                          key: ValueKey(snapshot.data?.displayName ?? 'name'),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: auth_ui.SignOutButton(
                            variant: auth_ui.ButtonVariant.filled,
                            key: UniqueKey(),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: auth_ui.DeleteAccountButton(
                            key: UniqueKey(),
                          ),
                        ),
                      ],
                    );
                  }),
            ),
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.blue,
            elevation: 0,
            leading: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      height: 45,
                      width: 45,
                      child: IconButton(
                        icon: Builder(
                          builder: (context) {
                            if (FirebaseAuth.instance.currentUser?.photoURL !=
                                null) {
                              return auth_ui.UserAvatar(
                                key: ValueKey(
                                    snapshot.data?.photoURL ?? 'avatar'),
                                placeholderColor:
                                    Theme.of(context).colorScheme.onBackground,
                              );
                            }
                            return const Icon(
                              Icons.account_circle_sharp,
                              size: 45,
                            );
                          },
                        ),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ),
                  );
                }),
            title: StreamBuilder<User?>(
              builder: (context, snapshot) {
                return RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                      style: TextStyle(
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.onBackground),
                      children: [
                        TextSpan(text: '${'hello'.tr} '),
                        TextSpan(
                          text:
                              FirebaseAuth.instance.currentUser?.displayName ??
                                  "User",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]),
                );
              },
              stream: FirebaseAuth.instance.userChanges(),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
              await _mainPageBloc.loadFiles();
              _mainPageBloc.add(const RefreshMainPage(true));
              setState(() {});
            },
            child: ListView(
              children: [
                // ElevatedButton(
                //   onPressed: _press,
                //   child: Text("press"),
                // ),
                // ElevatedButton(
                //   onPressed: _notify,
                //   child: Text("notification"),
                // ),
                const SizedBox(
                  height: 20,
                ),
                BlocBuilder<MainPageBloc, MainPageState>(
                    builder: (context, state) {
                  if (state.isWorkingSpaceEmpty) {
                    return buildWhenWorkingSpaceEmpty(context);
                  }
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 19),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildRecentImages(),
                          const SizedBox(
                            height: 10,
                          ),
                          buildRecentFiles(),
                        ],
                      ),
                    ),
                  );
                }, buildWhen: (previous, current) {
                  return current.isWorkingSpaceEmpty !=
                      previous.isWorkingSpaceEmpty;
                }),
              ],
            ),
          ),
        ),
        BlocBuilder<MainPageBloc, MainPageState>(
          builder: (context, state) {
            if (state.loading) {
              return Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 15,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox(
              height: 0,
              width: 0,
            );
          },
          buildWhen: (previous, current) => current.loading != previous.loading,
        ),
      ],
    );
  }

  Widget buildRecentFiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "recent_files".tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                _homePageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease,
                );
              },
              child: Text("see_all".tr),
            ),
          ],
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
                            {_mainPageBloc.excelFileList[index]},
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
                            _mainPageBloc.excelFileList[index].path);
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.share,
                      label: 'share'.tr,
                    ),
                    SlidableAction(
                      onPressed: (context) async {
                        String fileName =
                            _mainPageBloc.excelFileList[index].name ??
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
                          Fluttertoast.showToast(msg: "file_save_failed".tr);
                        });
                      },
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.save_alt,
                      label: 'save'.tr,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    var error = await MyExcel.open(
                      _mainPageBloc.excelFileList[index].path,
                    );
                    if (error != null) {
                      Notify.getxSnackBarError(error);
                    }
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.file_copy,
                                  size: 30,
                                  color:
                                      _mainPageBloc.excelFileList[index].type ==
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mainPageBloc.excelFileList[index].name ??
                                          "No name",
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      '${_mainPageBloc.excelFileList[index].getSize}, ${Helper.getTime(_mainPageBloc.excelFileList[index].created ?? DateTime.now())}',
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          initialItemCount: min(_mainPageBloc.excelFileList.length, 40),
          key: _mainPageBloc.keyExcelFileList,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
        ),
      ],
    );
  }

  Widget buildRecentImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'recent_images'.tr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                _homePageController.jumpToPage(2);
              },
              child: Text("see_all".tr),
            ),
          ],
        ),
        SizedBox(
          height: 100,
          child: AnimatedList(
            itemBuilder: (context, index, animation) {
              return ScaleTransition(
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: OpenContainer(
                        transitionType: ContainerTransitionType.fade,
                        openBuilder: (context, action) {
                          return ImagePreview(
                            _mainPageBloc.imageList[index].path,
                            _mainPageBloc.imageList[index],
                          );
                        },
                        closedBuilder: (context, action) => Row(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                shape: BoxShape.rectangle,
                                image: DecorationImage(
                                  image: FileImage(
                                    File(_mainPageBloc.imageList[index].path),
                                  ),
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                          ],
                        ),
                        closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        closedElevation: 0,
                        tappable: true,
                      ),
                    ),
                  ),
                ),
              );
            },
            initialItemCount: min(_mainPageBloc.imageList.length, 20),
            key: _mainPageBloc.keyImageList,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
          ),
        ),
      ],
    );
  }

  Widget buildWhenWorkingSpaceEmpty(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(50.0),
            child: Image.asset(
              "assets/images/working_space_empty.png",
              // fit: BoxFit.fitWidth,
            ),
          ),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 20.0,
              color: Theme.of(context).colorScheme.onBackground,
              fontFamily: 'Agne',
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'working_space_empty'.tr,
                  speed: const Duration(milliseconds: 80),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
