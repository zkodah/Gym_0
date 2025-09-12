import 'package:flutter/material.dart';
import '../screen/inicio.dart';
import '../screen/detalles.dart';
import '../screen/perfil.dart';

class GymNavbar extends StatelessWidget {
  final int currentIndex;

  const GymNavbar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Evita recargar la misma pantalla

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const DetallesScreen();
        break;
      case 1:
        nextScreen = const InicioScreen();
        break;
      case 2:
        nextScreen = const PerfilScreen();
        break;
      default:
        nextScreen = const InicioScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: "Ejercicios",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Inicio",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Perfil",
        ),
      ],
    );
  }
}
