import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smartpantri/generated/l10n.dart';
import 'package:smartpantri/services/auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'auth_service_test.mocks.dart';

// Mockok generálása
@GenerateMocks([FirebaseAuth, UserCredential, User])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    fakeFirestore = FakeFirebaseFirestore(); // Új FakeFirebaseFirestore
    authService = AuthService(auth: mockFirebaseAuth, firestore: fakeFirestore);
  });

  // Segédfüggvény a lokalizáció mockolásához
  Future<T> withLocalization<T>(
      WidgetTester tester, Future<T> Function(BuildContext) callback) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    return await callback(capturedContext);
  }

  // Mock BuildContext és AppLocalizations beállítása a loginhoz
  Future<Map<String, dynamic>> loginWithContext(
      WidgetTester tester, String email, String password) async {
    return await withLocalization(tester, (context) async {
      return await authService.login(
        context: context,
        email: email,
        password: password,
      );
    });
  }

  // Mock BuildContext és AppLocalizations beállítása a registerhez
  Future<Map<String, dynamic>> registerWithContext(
      WidgetTester tester, String firstName, String lastName, String email,
      String password, String confirmPassword, DateTime? birthDate) async {
    return await withLocalization(tester, (context) async {
      return await authService.register(
        context: context,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        birthDate: birthDate,
      );
    });
  }

  // Teszt 1: Üres email vagy jelszó esetén hibaüzenet (login)
  testWidgets('login returns error when email or password is empty',
          (WidgetTester tester) async {
        final result = await loginWithContext(tester, '', 'password123');

        expect(result['success'], false);
        expect(result['error'], 'Please fill in both fields!');
      });

  // Teszt 2: Sikeres bejelentkezés, email hitelesített (login)
  testWidgets('login returns success when email is verified',
          (WidgetTester tester) async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.emailVerified).thenReturn(true);

        final result = await loginWithContext(tester, 'test@example.com', 'password123');

        expect(result['success'], true);
        expect(result['user'], mockUser);
      });

  // Teszt 3: Email nincs hitelesítve (login)
  testWidgets('login returns error when email is not verified',
          (WidgetTester tester) async {
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.emailVerified).thenReturn(false);

        final result = await loginWithContext(tester, 'test@example.com', 'password123');

        expect(result['success'], false);
        expect(result['error'], 'Please verify your email to log in.');
      });

  // Teszt 4: Hiba esetén (pl. rossz jelszó) (login)
  testWidgets('login returns error on wrong password', (WidgetTester tester) async {
    when(mockFirebaseAuth.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    final result = await loginWithContext(tester, 'test@example.com', 'password123');

    expect(result['success'], false);
    expect(result['error'], 'Invalid password.');
  });

  // Teszt 5: Üres mezők esetén hibaüzenet (register)
  testWidgets('register returns error when fields are empty',
          (WidgetTester tester) async {
        final result = await registerWithContext(
            tester, '', '', 'test@example.com', 'password123', 'password123', null);

        expect(result['success'], false);
        expect(result['error'], 'Please fill in both fields!');
      });

  // Teszt 6: Jelszavak nem egyeznek (register)
  testWidgets('register returns error when passwords do not match',
          (WidgetTester tester) async {
        final result = await registerWithContext(
            tester, 'John', 'Doe', 'test@example.com', 'password123', 'pass123', null);

        expect(result['success'], false);
        expect(result['error'], 'Passwords do not match.');
      });

  // Teszt 7: Gyenge jelszó (register)
  testWidgets('register returns error when password is too short',
          (WidgetTester tester) async {
        final result = await registerWithContext(
            tester, 'John', 'Doe', 'test@example.com', 'pass', 'pass', null);

        expect(result['success'], false);
        expect(result['error'], 'Password must be at least 6 characters.');
      });

  // Teszt 8: Érvénytelen email (register)
  testWidgets('register returns error when email is invalid',
          (WidgetTester tester) async {
        final result = await registerWithContext(
            tester, 'John', 'Doe', 'invalid-email', 'password123', 'password123', null);

        expect(result['success'], false);
        expect(result['error'], 'Invalid email address.');
      });

  // Teszt 9: Sikeres regisztráció
  testWidgets('register returns success when registration is successful',
          (WidgetTester tester) async {
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('test-uid');

        // Példa adat hozzáadása a Firestore-hoz a register teszteléséhez
        await fakeFirestore.collection('users').doc('test-uid').set({
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'newuser@example.com',
        });

        final result = await registerWithContext(
            tester, 'John', 'Doe', 'newuser@example.com', 'password123', 'password123',
            DateTime(1990, 5, 15));

        expect(result['success'], true);
        expect(result['user'], mockUser);

        // Ellenőrizd az adatokat a fake Firestore-ban
        final snapshot = await fakeFirestore.collection('users').doc('test-uid').get();
        expect(snapshot.data()?['firstName'], 'John');
      });

  // Teszt 10: Email már használatban (register)
  testWidgets('register returns error when email is already in use',
          (WidgetTester tester) async {
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'existing@example.com',
          password: 'password123',
        )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        final result = await registerWithContext(
            tester, 'John', 'Doe', 'existing@example.com', 'password123', 'password123',
            null);

        expect(result['success'], false);
        expect(result['error'], 'This email is already in use.');
      });
}