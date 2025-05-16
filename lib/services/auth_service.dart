import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../generated/l10n.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.pleaseFillInBothFields,
      };
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user != null && user.emailVerified) {
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'error': AppLocalizations.of(context)!.pleaseVerifyYourEmail,
        };
      }
    } on FirebaseAuthException catch (e) {
      String error;
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
        'error': AppLocalizations.of(context)!.pleaseFillInBothFields,
      };
    }
    if (password != confirmPassword) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.passwordsDoNotMatch,
      };
    }
    if (password.length < 6) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.passwordTooShort,
      };
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return {
        'success': false,
        'error': AppLocalizations.of(context)!.invalidEmail,
      };
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred.user;
      if (user == null) {
        return {
          'success': false,
          'error': AppLocalizations.of(context)!.registrationFailed,
        };
      }

      await _firestore.collection('users').doc(user.uid).set({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'birthDate': birthDate != null ? DateFormat('yyyy-MM-dd').format(birthDate) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'isDarkMode': true,
        'primaryColor': Theme.of(context).colorScheme.primary.value,
      });

      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      String error;
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