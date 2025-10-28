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
        Navigator.pop(context, calcularProgreso());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(rutina['dia']),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF654EA3),
                  Color(0xFFEAAFc8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFDFBFB),
                Color(0xFFEBEDEE),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Botón cronómetro con “falso” gradiente
                ElevatedButton(
                  onPressed: toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: running
                          ? const LinearGradient(
                              colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF141E30), Color(0xFF243B55)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      alignment: Alignment.center,
                      child: Text(
                        running
                            ? "⏱ ${formatTime(seconds)} (Detener)"
                            : "⏱ Iniciar Cronómetro",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Lista de ejercicios
                Expanded(
                  child: Card(
                    elevation: 5,
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF3F6FF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ejercicios",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
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
                ),

                const SizedBox(height: 12),

                // Progreso total con círculo estilizado
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3EADCF),
                        Color(0xFFABE9CD),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3EADCF).withOpacity(0.25),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 15.0,
                      percent: calcularProgreso().clamp(0.0, 1.0),
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${(calcularProgreso() * 100).toInt()}%",
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Progreso Total",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                      // Gradiente del progreso
                      linearGradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF512F),
                          Color(0xFFF09819),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.25),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
