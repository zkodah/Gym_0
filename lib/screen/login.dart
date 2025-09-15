import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


import 'inicio.dart';

class LoginScreen extends StatelessWidget {
  static final Logger _logger = Logger();

  const LoginScreen({super.key});

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Paso 1: iniciar flujo de autenticación
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null; // canceló login

      // Paso 2: obtener detalles de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Paso 3: crear credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Paso 4: iniciar sesión en Firebase
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      _logger.e("Error en Google Sign-In: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gymkoda")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Inicio de sesión',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            Center(
              child: Icon(
                Icons.fitness_center,
                size: 100,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () async {
                final result = await signInWithGoogle();
                if (result != null) {
                  _logger.i("Login exitoso: ${result.user?.displayName}");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const InicioScreen()),
                  );
                } else {
                  _logger.e("Error al iniciar sesión");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al iniciar sesión")),
                  );
                }
              },
              icon: const Icon(Icons.g_mobiledata, color: Colors.white),
              label: const Text("Iniciar con Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
