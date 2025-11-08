import 'package:flutter/material.dart';
import '../screen/inicio.dart';
import '../screen/youtube_busqueda.dart';
import '../screen/perfil.dart';

class GymNavbar extends StatefulWidget {
  final int currentIndex;

  const GymNavbar({super.key, required this.currentIndex});

  @override
  State<GymNavbar> createState() => _GymNavbarState();
}

class _GymNavbarState extends State<GymNavbar> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      onDestinationSelected: (int index) {
        setState(() {
          currentPageIndex = index;
        });

        Widget nextScreen;
        switch (index) {
          case 0:
            nextScreen = const YoutubeSearchScreen();
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
      },
      indicatorColor: Colors.amber,
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.fitness_center),
          icon: Icon(Icons.fitness_center_outlined),
          label: 'Ejercicios',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Inicio',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.person_2_outlined),
          icon: Icon(Icons.person_2_outlined),
          label: 'Perfil',
        ),
      ],
    );
  }
}
