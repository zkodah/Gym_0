import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error en Google Sign-In: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gymkoda")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Forzar logout antes de iniciar sesión
            await GoogleSignIn().signOut();
            await FirebaseAuth.instance.signOut();

            final result = await _signInWithGoogle();
            if (result != null) {
              await AuthService.handleLogin(context, result.user!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al iniciar sesión")),
              );
            }
          },
          child: const Text("Iniciar sesión con Google"),
        ),
      ),
    );
  }
}
