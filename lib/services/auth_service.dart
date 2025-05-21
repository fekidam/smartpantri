import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../generated/l10n.dart';

// Autentikációs szolgáltatás osztály
class AuthService {
  final FirebaseAuth _auth; // Firebase autentikációs példány
  final FirebaseFirestore _firestore; // Firestore adatbázis példány

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Bejelentkezés kezelése
  Future<Map<String, dynamic>> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.pleaseFillInBothFields, // Hiba, ha üres mezők vannak
      };
    }

    try {
      // Bejelentkezés email és jelszó alapján
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null && user.emailVerified) {
        return {'success': true, 'user': user}; // Sikeres bejelentkezés
      } else {
        return {
          'success': false,
          'error': AppLocalizations.of(context)!.pleaseVerifyYourEmail, // Hiba, ha az email nincs ellenőrizve
        };
      }
    } on FirebaseAuthException catch (e) {
      String error;
      // Hibaüzenetek kezelése a Firebase hibakódok alapján
      switch (e.code) {
        case 'user-not-found':
          error = AppLocalizations.of(context)!.userNotFound;
          break;
        case 'wrong-password':
          error = AppLocalizations.of(context)!.wrongPassword;
          break;
        case 'invalid-email':
          error = AppLocalizations.of(context)!.invalidEmail;
          break;
        default:
          error = '${AppLocalizations.of(context)!.loginError} ${e.message}';
      }
      return {'success': false, 'error': error};
    } catch (e) {
      return {
        'success': false,
        'error': '${AppLocalizations.of(context)!.loginError} $e',
      };
    }
  }

  // Regisztráció kezelése
  Future<Map<String, dynamic>> register({
    required BuildContext context,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    DateTime? birthDate,
  }) async {
    if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.pleaseFillInBothFields, // Hiba, ha üres mezők vannak
      };
    }
    if (password != confirmPassword) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.passwordsDoNotMatch, // Hiba, ha a jelszavak nem egyeznek
      };
    }
    if (password.length < 6) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.passwordTooShort, // Hiba, ha a jelszó túl rövid
      };
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.invalidEmail, // Hiba, ha az email formátuma érvénytelen
      };
    }

    try {
      // Felhasználó regisztrálása email és jelszó alapján
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred.user;
      if (user == null) {
        return {
          'success': false,
          'error': AppLocalizations.of(context)!.registrationFailed, // Hiba, ha a regisztráció nem sikerült
        };
      }

      // Felhasználói adatok mentése Firestore-ba
      await _firestore.collection('users').doc(user.uid).set({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'birthDate': birthDate != null ? DateFormat('yyyy-MM-dd').format(birthDate) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'isDarkMode': true,
        'primaryColor': Theme.of(context).colorScheme.primary.value,
      });

      return {'success': true, 'user': user}; // Sikeres regisztráció
    } on FirebaseAuthException catch (e) {
      String error;
      // Hibaüzenetek kezelése a Firebase hibakódok alapján
      switch (e.code) {
        case 'email-already-in-use':
          error = AppLocalizations.of(context)!.emailAlreadyInUse;
          break;
        case 'weak-password':
          error = AppLocalizations.of(context)!.weakPassword;
          break;
        case 'invalid-email':
          error = AppLocalizations.of(context)!.invalidEmail;
          break;
        default:
          error = '${AppLocalizations.of(context)!.registrationError} ${e.message}';
      }
      return {'success': false, 'error': error};
    } catch (e) {
      return {
        'success': false,
        'error': '${AppLocalizations.of(context)!.registrationError} $e',
      };
    }
  }
}