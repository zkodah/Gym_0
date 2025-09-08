import 'package:flutter/material.dart';
import 'dart:async';

class RutinaScreen extends StatefulWidget {
  final Map<String, dynamic> rutina;
  const RutinaScreen({super.key, required this.rutina});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {
  bool running = false;
  int seconds = 0;
  Timer? timer;
  late List<bool> completados;

  @override
  void initState() {
    super.initState();
    completados = List<bool>.filled(widget.rutina['rutina'].length, false);
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
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rutina = widget.rutina;
    return Scaffold(
      appBar: AppBar(title: Text(rutina['dia'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: toggleTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: running ? const Color.fromARGB(255, 183, 189, 180) : const Color.fromARGB(255, 0, 0, 0), // Cambia color si está corriendo
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                running
                    ? "⏱ ${formatTime(seconds)} (Detener)"
                    : "⏱ Iniciar Cronómetro",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Lista de ejercicios
            Expanded(
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Ejercicios",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: rutina['rutina'].length,
                          itemBuilder: (context, i) {
                            return CheckboxListTile(
                              title: Text(rutina['rutina'][i]),
                              value: completados[i],
                              onChanged: (val) {
                                setState(() {
                                  completados[i] = val ?? false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Desafío extra
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Desafío",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("• Burpees x 20"),
                    Text("• Plancha 1 min"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
