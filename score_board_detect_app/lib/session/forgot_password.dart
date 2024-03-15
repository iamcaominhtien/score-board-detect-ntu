part of 'session_screen.dart';

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({Key? key, this.email}) : super(key: key);
  final String? email;

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordScreen(
      resizeToAvoidBottomInset: true,
      email: email,
    );
  }
}
