import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DetallesScreen extends StatelessWidget {
  const DetallesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles"),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Buscador debajo del AppBar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onChanged: (value) {
                // Lógica para manejar la búsqueda
                print("Buscando: $value");
              },
            ),
          ),
          const Expanded(
            child: Center(child: Text("Detalles del ejercicio")),
          ),

        ],
      ),
      bottomNavigationBar: const GymNavbar(currentIndex: 0),
    );
  }
}
