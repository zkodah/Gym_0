import 'package:flutter/material.dart';
import '../screen/inicio.dart';
import '../screen/youtube_busqueda.dart';
import '../screen/perfil.dart';

const _kAccent = Color(0xFFFF6D00);

class GymNavbar extends StatefulWidget {
  final int currentIndex;
  const GymNavbar({super.key, required this.currentIndex});

  @override
  State<GymNavbar> createState() => _GymNavbarState();
}

class _GymNavbarState extends State<GymNavbar> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.currentIndex;
  }

  void _navigate(int index) {
    if (index == _current) return;
    setState(() => _current = index);

    final Widget next;
    switch (index) {
      case 0:
        next = const YoutubeSearchScreen();
        break;
      case 1:
        next = const InicioScreen();
        break;
      case 2:
        next = const PerfilScreen();
        break;
      default:
        next = const InicioScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      onDestinationSelected: _navigate,
      selectedIndex: _current,
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      indicatorColor: _kAccent.withOpacity(0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        _dest(
          icon: Icons.play_circle_outline_rounded,
          activeIcon: Icons.play_circle_rounded,
          label: 'Ejercicios',
          index: 0,
        ),
        _dest(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Inicio',
          index: 1,
        ),
        _dest(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Perfil',
          index: 2,
        ),
      ],
    );
  }

  NavigationDestination _dest({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final active = _current == index;
    return NavigationDestination(
      icon: Icon(icon, color: active ? _kAccent : const Color(0xFF9E9E9E)),
      selectedIcon: Icon(activeIcon, color: _kAccent),
      label: label,
    );
  }
}
