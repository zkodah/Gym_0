import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  List<dynamic> ejercicios = [];
  bool loading = true;

  // Cronómetro
  bool running = false;
  int seconds = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    cargarEjercicios();
  }

  void cargarEjercicios() async {
    try {
      var data = await ApiService.getEjercicios();

      // Detectar día actual (ejemplo: Lunes, Martes...)
      String diaHoy = _getDiaSemana();
      var rutinaHoy = data.firstWhere(
        (e) => e["dia"] == diaHoy,
        orElse: () => {"dia": diaHoy, "titulo": "Sin rutina", "rutina": []},
      );

      setState(() {
        ejercicios = [rutinaHoy];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      print("Error: $e");
    }
  }

  String _getDiaSemana() {
    final dias = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo"
    ];
    int weekday = DateTime.now().toLocal().weekday; 
    return dias[weekday - 1];
  }

  void toggleTimer() {
    if (running) {
      timer?.cancel();
    } else {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => seconds++);
      });
    }
    setState(() => running = !running);
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rutinas Inteligentes")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: running ? const Color.fromARGB(255, 0, 0, 0) : const Color.fromARGB(255, 255, 255, 255),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    running
                        ? "⏱ ${formatTime(seconds)} (Detener)"
                        : "⏱ Iniciar Cronómetro",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 20),

             
                Text(
                  ejercicios.isNotEmpty ? ejercicios[0]['dia'] : "Sin rutina",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

       
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(20),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ejercicios.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ejercicios[0]['titulo'] ?? "",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: List.generate(
                                      (ejercicios[0]['rutina'] as List).length,
                                      (i) => Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 6),
                                        child: Text(
                                            "• ${(ejercicios[0]['rutina'] as List)[i]}"),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Text("No hay ejercicios para hoy"),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
