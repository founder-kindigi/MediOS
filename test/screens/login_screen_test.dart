import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/features/auth/screens/login_screen.dart';
import '../../lib/features/auth/services/auth_service.dart';
import 'widget_test_helper.dart';

Widget buildApp(MockAuthService mockAuth) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>.value(value: mockAuth),
    ],
    child: MaterialApp(
      home: const LoginScreen(),
      routes: {'/dashboard': (_) => const Scaffold(body: Text('Dashboard'))},
    ),
  );
}

void main() {
  late MockAuthService mockAuth;

  setUp(() {
    setupWidgetTestLocator();
    mockAuth = MockAuthService();
  });

  testWidgets('renders login form with all elements', (tester) async {
    await tester.pumpWidget(buildApp(mockAuth));

    expect(find.text('MediOS'), findsOneWidget);
    expect(find.text('Pharmacy Management System'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(buildApp(mockAuth));

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter username'), findsOneWidget);
    expect(find.text('Enter password'), findsOneWidget);
  });

  testWidgets('calls auth service on valid form submission', (tester) async {
    await tester.pumpWidget(buildApp(mockAuth));

    await tester.enterText(find.byType(TextFormField).first, 'admin');
    await tester.enterText(find.byType(TextFormField).last, 'admin123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(mockAuth.lastLoginUsername, 'admin');
    expect(mockAuth.lastLoginPassword, 'admin123');
  });

  testWidgets('shows error message on failed login', (tester) async {
    mockAuth.setLoginResult(false);
    await tester.pumpWidget(buildApp(mockAuth));

    await tester.enterText(find.byType(TextFormField).first, 'admin');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid username or password'), findsOneWidget);
  });

  testWidgets('shows loading indicator while logging in', (tester) async {
    await tester.pumpWidget(buildApp(mockAuth));

    await tester.enterText(find.byType(TextFormField).first, 'admin');
    await tester.enterText(find.byType(TextFormField).last, 'admin123');
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
