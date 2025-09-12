import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widget/navbar.dart';
import 'ejercicios.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  List<dynamic> ejercicios = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarEjercicios();
  }

  void cargarEjercicios() async {
    try {
      var data = await ApiService.getEjercicios();
      setState(() {
        ejercicios = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gymkoda")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: ejercicios.length,
              itemBuilder: (context, index) {
                final e = ejercicios[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Center(
                      child: Text(
                        e['dia'],
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RutinaScreen(rutina: e),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: const GymNavbar(currentIndex: 1), // 👈 Aquí va
    );
  }
}
