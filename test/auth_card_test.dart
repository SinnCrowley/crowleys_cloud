import 'package:crowleys_cloud/auth_card.dart';
import 'package:crowleys_cloud/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthCard defaults to login mode', (tester) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthCard(
            title: 'Sign In',
            usernameController: usernameController,
            passwordController: passwordController,
            onSubmit: (mode, {email}) async => false,
          ),
        ),
      ),
    );

    expect(find.text('Log In'), findsNWidgets(2));
    expect(find.text('Register'), findsOneWidget);
    expect(
      find.text('Do not have an account? Switch to Register.'),
      findsOneWidget,
    );

    usernameController.dispose();
    passwordController.dispose();
  });

  testWidgets('AuthCard hides biometric button without saved credentials', (
    tester,
  ) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthCard(
            title: 'Sign In',
            usernameController: usernameController,
            passwordController: passwordController,
            biometricAvailable: false,
            onBiometricLogin: () async => false,
            onSubmit: (mode, {email}) async {
              expect(mode, AuthMode.login);
              return false;
            },
          ),
        ),
      ),
    );

    expect(find.text('Use Biometrics'), findsNothing);

    usernameController.dispose();
    passwordController.dispose();
  });
}
