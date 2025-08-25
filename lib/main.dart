import 'package:flutter/material.dart';
import 'screen/inicio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Ejercicio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const InicioScreen(),
    );
  }
}
