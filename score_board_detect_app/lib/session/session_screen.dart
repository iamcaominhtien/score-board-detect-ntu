import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:score_board_detect/configs.dart';
import 'package:score_board_detect/pages/home/home.dart';

part 'forgot_password.dart';

part 'login.dart';

part 'register.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({Key? key}) : super(key: key);
  static const routeName = '/sign-in';

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool _signingScreen = true;

  @override
  Widget build(BuildContext context) {
    return _signingScreen
        ? SigninScreen(toggleScreen)
        : SignupScreen(toggleScreen);
  }

  void toggleScreen() {
    setState(() {
      _signingScreen = !_signingScreen;
    });
  }
}

BoxDecoration ntuBackground() {
  return const BoxDecoration(
    image: DecorationImage(
      image: AssetImage(
        'assets/images/bg/ntu.jpg',
      ),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.blue,
        BlendMode.modulate,
      ),
    ),
  );
}
