import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main_shell.dart';
import 'sign_in_screen.dart';

/// Listens to FirebaseAuth state and routes to SignInScreen or MainShell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF85)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }
        return const SignInScreen();
      },
    );
  }
}
