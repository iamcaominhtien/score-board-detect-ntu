part of 'session_screen.dart';

class SigninScreen extends StatelessWidget {
  final Function() toggleScreen;

  const SigninScreen(this.toggleScreen, {super.key});

  @override
  Widget build(BuildContext context) {
    bool haveSignedIn = false;
    return SignInScreen(
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
              'dont_have_an_account'.tr,
              style: const TextStyle(fontSize: 13),
            ),
            GestureDetector(
              onTap: () => toggleScreen(),
              child: Text(
                " ${'register'.tr}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
      footerBuilder: (context, constraints) {
        return AuthStateListener<OAuthController>(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 20,
              ),
              OAuthProviderButton(
                provider: GoogleProvider(clientId: Config().googleClientId),
              ),
              const SizedBox(
                height: 20,
              ),
              const AnonymousLogin(),
            ],
          ),
          listener: (oldState, newState, ctrl) {
            if ((newState is SignedIn || newState is UserCreated) &&
                !haveSignedIn) {
              haveSignedIn = true;
              Navigator.of(context).pushReplacementNamed(MyHomePage.routeName);
            }
            return null;
          },
        );
      },
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          if (state.user != null && !haveSignedIn) {
            haveSignedIn = true;
            Navigator.of(context).pushReplacementNamed(MyHomePage.routeName);
          }
        }),
        ForgotPasswordAction((context, email) {
          //show dialog
          showDialog<void>(
            context: context,
            barrierDismissible: true, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                // title: const Text('AlertDialog Title'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                content: SingleChildScrollView(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                        child: ForgotPassword(
                      email: email,
                    )),
                  ),
                ),
                contentPadding: const EdgeInsets.all(10),
              );
            },
          );
        }),
      ],
    );
  }
}

class AnonymousLogin extends StatefulWidget {
  const AnonymousLogin({
    super.key,
  });

  @override
  State<AnonymousLogin> createState() => _AnonymousLoginState();
}

class _AnonymousLoginState extends State<AnonymousLogin> {
  bool login = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          login = true;
        });
        try {
          await auth.FirebaseAuth.instance.signInAnonymously();
          //change name of anonymous user to "User"
          await auth.FirebaseAuth.instance.currentUser
              ?.updateDisplayName('User');
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(MyHomePage.routeName);
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        } finally {
          setState(() {
            login = false;
          });
        }
      },
      child: login
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Text(
              'anonymous_sign_in'.tr,
            ),
    );
  }
}
