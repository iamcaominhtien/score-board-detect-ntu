part of 'session_screen.dart';

class SignupScreen extends StatelessWidget {
  final Function() toggleScreen;

  const SignupScreen(this.toggleScreen, {super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterScreen(
      providers: [
        EmailAuthProvider(),
      ],
      headerMaxExtent: 80,
      headerBuilder: (context, constraints, shrinkOffset) => Container(
        decoration: ntuBackground(),
      ),
      showAuthActionSwitch: false,
      subtitleBuilder: (context, action) {
        return Row(
          children: [
            Text(
              "already_have_an_account".tr,
              style: const TextStyle(fontSize: 13),
            ),
            GestureDetector(
              onTap: () => toggleScreen(),
              child: Text(
                " ${'sign_in'.tr}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        );
      },
      oauthButtonVariant: OAuthButtonVariant.icon_and_text,
      sideBuilder: (context, constraints) {
        return Container(
          height: double.infinity,
          // color: Colors.blue,
          decoration: ntuBackground(),
        );
      },
      actions: [
        AuthStateChangeAction<UserCreated>((context, state) {
          final user = state.credential.user;
          if (user != null) {
            auth.FirebaseAuth.instance.currentUser
                ?.updateDisplayName(user.email ?? "User");
            Fluttertoast.showToast(
                msg: "Register successfully!",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 16.0);
          } else {
            Fluttertoast.showToast(
                msg: "Register failed",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Theme.of(context).colorScheme.error,
                textColor: Theme.of(context).colorScheme.onError,
                fontSize: 16.0);
          }
          auth.FirebaseAuth.instance.signOut();
        }),
      ],
    );
  }
}
