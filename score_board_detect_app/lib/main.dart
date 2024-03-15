import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:score_board_detect/pages/all_files/all_files.dart';
import 'package:score_board_detect/pages/all_images/all_images.dart';
import 'package:score_board_detect/pages/all_images/bloc/bloc.dart';
import 'package:score_board_detect/pages/home/bloc/bloc.dart';
import 'package:score_board_detect/pages/main_page/bloc/bloc.dart';
import 'package:score_board_detect/pages/settings/settings.dart';
import 'package:score_board_detect/pages/settings/settings_state.dart';
import 'package:score_board_detect/service/detect_table_api/bloc/bloc.dart'
    show DetectTableAPIBloc;
import 'package:score_board_detect/service/firebase_ui_localization/firebase_ui_localization.dart';
import 'package:score_board_detect/service/localization.dart';
import 'configs.dart';
import 'firebase_options.dart';
import 'package:score_board_detect/session/session_screen.dart';
import 'package:score_board_detect/pages/home/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as auth_ui;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'my_test/test_page.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  Config().rootIsolateToken = RootIsolateToken.instance!;
  Config().getCameraDescription();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    GetStorage.init()
  ]);
  auth_ui.FirebaseUIAuth.configureProviders([
    auth_ui.EmailAuthProvider(),
  ]);
  auth_ui.FirebaseUIAuth.configureProviders([
    GoogleProvider(clientId: Config().googleClientId),
  ]);
  runApp(const MyApp());
  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    StoreBinding(context).dependencies();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BottomBarBloc(),
        ),
        BlocProvider(
          create: (context) => MainPageBloc(),
        ),
        BlocProvider(
          create: (context) => AllImagesBloc(),
        ),
        BlocProvider(
          create: (context) => AllFilesBloc(),
        ),
        BlocProvider(
          create: (context) => DetectTableAPIBloc(),
        ),
      ],
      child: GetBuilder<SettingsState>(
        builder: (controller) {
          return GetMaterialApp(
            title: 'Flutter Demo',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: FirebaseAuth.instance.currentUser == null
                ? SessionScreen.routeName
                : MyHomePage.routeName,
            // initialRoute: '/test',
            routes: {
              SessionScreen.routeName: (context) => const SessionScreen(),
              MyHomePage.routeName: (context) => const MyHomePage(),
              AllFiles.routeName: (context) => const AllFiles(),
              AllImages.routeName: (context) => const AllImages(),
              SettingsPage.routeName: (context) => const SettingsPage(),
              '/test': (context) => const TestPage(),
            },
            // initialBinding: StoreBinding(context),
            locale: LocalizationService.locale,
            fallbackLocale: LocalizationService.defaultLocale,
            translations: LocalizationService(),
            localizationsDelegates: controller.language.nameToSave == 'vi'
                ? [
                    FirebaseUILocalizations.withDefaultOverrides(
                        const VietnameseLabelOverrides()),

                    // This delegate is required to provide the labels that are not overridden by LabelOverrides
                    FirebaseUILocalizations.delegate,
                  ]
                : [
                    FirebaseUILocalizations.withDefaultOverrides(
                        EnglishLabelOverrides()),

                    // This delegate is required to provide the labels that are not overridden by LabelOverrides
                    FirebaseUILocalizations.delegate,
                  ],
          );
        },
      ),
    );
  }
}

class StoreBinding implements Bindings {
  final BuildContext context;

  StoreBinding(this.context);

  @override
  void dependencies() {
    Get.lazyPut(() => SettingsState(MediaQuery.of(context).platformBrightness));
  }
}
