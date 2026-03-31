import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screen/inicio.dart';

class AuthService {
  static Future<void> handleLogin(BuildContext context, User user) async {
    final usuariosRef = FirebaseFirestore.instance.collection('usuarios');
    final userDoc = await usuariosRef.doc(user.uid).get();
    if (!userDoc.exists) {
      await usuariosRef.doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const InicioScreen()),
    );
  }
}