// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:firabase_multimedia/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:firabase_multimedia/features/auth/presentation/screens/login_screen.dart';
import 'package:firabase_multimedia/features/auth/presentation/stores/auth_store.dart';

class _FakeAuthRepository implements IAuthRepository {
  @override
  Future<String?> signIn() async => 'test-user';

  @override
  Future<void> signOut() async {}

  @override
  String? getCurrentUserId() => null;
}

void main() {
  testWidgets('muestra el acceso con Google', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthStore>(
        create: (_) => AuthStore(_FakeAuthRepository()),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
