import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: const Center(child: Text("Detalles del perfil")),
      bottomNavigationBar: const GymNavbar(currentIndex: 2),
    );
  }
}
