// Copyright (C) 2026 Sinn Crowley
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
