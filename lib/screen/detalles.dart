import 'package:flutter/material.dart';

class DetallesScreen extends StatelessWidget {
  const DetallesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalles")),
      body: const Center(child: Text("Detalles del ejercicio")),
    );
  }
}
