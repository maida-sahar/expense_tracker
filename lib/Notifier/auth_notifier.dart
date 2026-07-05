// lib/Notifier/auth_notifier.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _initializing = true;
  String? _error;

  AuthNotifier() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      _initializing = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get initializing => _initializing;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    _error = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      notifyListeners();
      return false;
    }
  }

 Future<void> signOut() async {
  try {
    await _googleSignIn.signOut();
  } catch (_) {
    // Ignore
  }
  await _auth.signOut();
}

  /// Signs in with Google. Returns true on success, false if the user
  /// cancelled the picker or an error occurred (check `error` for the reason).
  Future<bool> signInWithGoogle() async {
    _error = null;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User closed the account picker without choosing one — not an error.
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Google sign-in failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Sends a Firebase password-reset email. Returns true if the request was
  /// accepted (Firebase always accepts it even for unknown emails, to avoid
  /// leaking which emails are registered — so this being true just means the
  /// request went through, not necessarily that an account exists).
  Future<bool> sendPasswordResetEmail(String email) async {
    _error = null;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      notifyListeners();
      return false;
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled for this project yet. '
            'Enable it in Firebase Console → Authentication → Sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}