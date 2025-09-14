import 'package:flutter/material.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';

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

  double calcularProgreso() {
    final total = completados.length;
    if (total == 0) return 0;
    final hechos = completados.where((c) => c).length;
    return hechos / total;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rutina = widget.rutina;

    return WillPopScope(
      onWillPop: () async {
        // Al volver atrás, mandamos el progreso calculado
        Navigator.pop(context, calcularProgreso());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(rutina['dia']),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, calcularProgreso());
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: toggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: running
                      ? const Color.fromARGB(255, 183, 189, 180)
                      : const Color.fromARGB(255, 0, 0, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  running
                      ? "⏱ ${formatTime(seconds)} (Detener)"
                      : "⏱ Iniciar Cronómetro",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Lista de ejercicios
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

              // Progreso total con círculo estilizado
              Container(
                height: 200,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: CircularPercentIndicator(
                    radius: 80.0,
                    lineWidth: 15.0,
                    percent: calcularProgreso(),
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${(calcularProgreso() * 100).toInt()}%",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Progreso Total",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    progressColor: Colors.blueAccent,
                    backgroundColor: Colors.grey[200]!,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
