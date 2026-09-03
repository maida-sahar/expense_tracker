// lib/views/auth_gate.dart
//
// Decides whether to show the login flow or the main app, and binds the
// signed-in user's uid into TransactionNotifier so every Firestore query is
// scoped to that user's own data.

import 'package:expense_tracker/Notifier/auth_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/views/auth/login_view.dart';
import 'package:expense_tracker/views/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    if (auth.initializing) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final gradient = isDark ? AppColors.heroGradientDark : AppColors.heroGradientLight;
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginView();
    }

    // Bind the transaction stream to the current user as soon as we know it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionNotifier>().bindUser(auth.user!.uid);
    });

    return const MainShell();
  }
}
