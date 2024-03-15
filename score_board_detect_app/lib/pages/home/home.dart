import 'dart:async';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:score_board_detect/components/keep_alive_page.dart';
import 'package:score_board_detect/pages/all_files/all_files.dart';
import 'package:score_board_detect/pages/all_images/all_images.dart';
import 'package:score_board_detect/pages/all_images/bloc/bloc.dart';
import 'package:score_board_detect/pages/detection_page/detection_page.dart';
import 'package:score_board_detect/pages/home/top_panel.dart';
import 'package:score_board_detect/pages/main_page/bloc/bloc.dart';
import 'package:score_board_detect/pages/main_page/main_page.dart';
import 'package:score_board_detect/pages/settings/settings.dart';
import 'package:score_board_detect/pages/settings/settings_state.dart';
import 'package:score_board_detect/service/detect_table_api/bloc/bloc.dart';
import 'package:score_board_detect/service/local_notification.dart';
import 'package:score_board_detect/service/manage_files/models/manage_file.dart';
import 'package:score_board_detect/service/manage_files/sql/manage_files_db.dart';
import 'package:score_board_detect/session/session_screen.dart';
import 'bloc/bloc.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  static const String routeName = '/home';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PageController _pageController = PageController();
  late final BottomBarBloc _bottomBarBloc;
  late final MainPageBloc _mainPageBloc;
  late final AllFilesBloc _allFilesBloc;
  late final AllImagesBloc _allImagesBloc;
  late final DetectTableAPIBloc _detectTableAPIBloc;

  final _iconList = <IconData>[
    Icons.home,
    Icons.file_copy_outlined,
    Icons.photo,
    Icons.settings,
  ];

  StreamSubscription<User?>? authSubscript;

  @override
  void initState() {
    super.initState();
    LocalNotificationService.initialize();
    ManageFilesDB().initDB();
    _bottomBarBloc = BlocProvider.of<BottomBarBloc>(context);
    _mainPageBloc = BlocProvider.of<MainPageBloc>(context);
    _allFilesBloc = BlocProvider.of<AllFilesBloc>(context);
    _allImagesBloc = BlocProvider.of<AllImagesBloc>(context);
    _detectTableAPIBloc = BlocProvider.of<DetectTableAPIBloc>(context);
    authSubscript = FirebaseAuth.instance.authStateChanges().listen((event) {
      if (event == null && mounted) {
        _closeBloc();
        Navigator.of(context)
            .pushNamedAndRemoveUntil(SessionScreen.routeName, (route) => false);
        ManageFilesDB().closeDb();
        authSubscript?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          BlocBuilder<DetectTableAPIBloc, DetectTableApiState?>(
            builder: (context, state) {
              if (state is InitialState) {
                return const TopPanel();
              }
              return const SizedBox();
            },
            buildWhen: (previous, current) =>
                previous != current &&
                (current is InitialState || current is FinishAllTaskState),
          ),
          Expanded(
            child: Scaffold(
              floatingActionButton: BlocBuilder<BottomBarBloc, BottomBarState>(
                builder: (context, state) => state.show
                    ? FloatingActionButton(
                        onPressed: _floatingActionMethod,
                        child: const Icon(
                          Icons.document_scanner_outlined,
                          size: 35,
                        ),
                      )
                    : const SizedBox(
                        height: 0,
                        width: 0,
                      ),
                buildWhen: (previous, current) => previous != current,
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BlocBuilder<BottomBarBloc, BottomBarState>(
                builder: (context, state) => state.show
                    ? AnimatedBottomNavigationBar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Colors.white,
                        activeColor: Colors.yellow,
                        gapLocation: GapLocation.center,
                        notchSmoothness: NotchSmoothness.verySmoothEdge,
                        icons: _iconList,
                        activeIndex: state.currentIndex,
                        onTap: (index) {
                          int currentPageIndex = state.currentIndex;
                          _bottomBarBloc.add(ChangeIndex(index: index));
                          if ((currentPageIndex - index).abs() == 1) {
                            _pageController.animateToPage(index,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.ease);
                          } else {
                            _pageController.jumpToPage(index);
                          }
                        },
                        elevation: 0,
                      )
                    : const SizedBox(
                        height: 0,
                      ),
                buildWhen: (previous, current) => previous != current,
              ),
              body: BlocListener<DetectTableAPIBloc, DetectTableApiState?>(
                child: PageView(
                  controller: _pageController,
                  children: [
                    KeepAlivePage(child: MainPage(_pageController)),
                    // const KeepAlivePage(child: AllFiles()),
                    const KeepAlivePage(child: AllFiles()),
                    const KeepAlivePage(child: AllImages()),
                    const KeepAlivePage(child: SettingsPage()),
                  ],
                  onPageChanged: (index) {
                    _bottomBarBloc.add(ChangeIndex(index: index));
                  },
                ),
                listener: (context, state) {
                  if (state == null) return;
                  if (state is CompletedTaskState) {
                    if (state.task.result != null) {
                      _mainPageBloc.add(AddNewFile(state.task.result!));
                    }
                  } else if (state is AddNewTaskState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Đã thêm vào hàng đợi..."),
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  }
                },
                listenWhen: (previous, current) => previous != current,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _floatingActionMethod() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const DetectionPage()))
        .then((path) async {
      if (path != null) {
        var imageFile =
            await ManageFilesDB.createManageFile(path, FileType.image);
        if (imageFile != null) {
          _mainPageBloc.add(AddNewFile(imageFile));
          _detectTableAPIBloc.add(AddNewTaskAction(Task(imageFile)));
        }
      }
    });
  }

  void _closeBloc() {
    LocalNotificationService.clearAll();
    _mainPageBloc.add(const EndMainPage());
    _bottomBarBloc.add(EndBottomBarAction());
    _allImagesBloc.add(EndAllImagesAction());
    _allFilesBloc.add(EndAllImagesAction());
    _detectTableAPIBloc.add(EndDetectTableAPIAction());
    Get.find<SettingsState>().clear();
  }
}
