import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'inicio.dart';

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

  Future<void> _showQuestionnaire(BuildContext context) async {
    final TextEditingController edadCtrl = TextEditingController();
    final TextEditingController alturaCtrl = TextEditingController();
    final TextEditingController pesoCtrl = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Completa tu perfil"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: edadCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Edad"),
                ),
                TextField(
                  controller: alturaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Altura (m)"),
                ),
                TextField(
                  controller: pesoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Peso (kg)"),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final data = {
                    "edad": int.tryParse(edadCtrl.text) ?? 0,
                    "altura": double.tryParse(alturaCtrl.text) ?? 0.0,
                    "peso": double.tryParse(pesoCtrl.text) ?? 0.0,
                  };

                  await FirebaseFirestore.instance
                      .collection("usuarios")
                      .doc(user.uid)
                      .set(data);

                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar"),
            )
          ],
        );
      },
    );
  }

  Future<void> _handleLogin(BuildContext context, User user) async {
    final doc = await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      await _showQuestionnaire(context);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InicioScreen()),
    );
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
              await _handleLogin(context, result.user!);
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
