import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/api_service.dart';
import '../widget/navbar.dart';
import 'ejercicios.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
    // Calcular promedio de progreso
    double total = ejercicios.isEmpty
        ? 0
        : ejercicios
            .map((d) => (d["progreso"] ?? 0).toDouble())
            .reduce((a, b) => a + b);
    double promedio = ejercicios.isEmpty ? 0 : total / ejercicios.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gymkoda"),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
        actions: [
          IconButton(
            icon : const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Lista de días
                Expanded(
                  child: ListView.builder(
                    itemCount: ejercicios.length,
                    itemBuilder: (context, index) {
                      final e = ejercicios[index];
                      final progreso =
                          (e["progreso"] ?? 0).toDouble(); // 0.0 → 1.0

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            e['dia'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          trailing: CircularPercentIndicator(
                            radius: 25.0,
                            lineWidth: 6.0,
                            percent: progreso,
                            center: Text(
                              "${(progreso * 100).toInt()}%",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            progressColor:
                                progreso == 1.0 ? Colors.green : Colors.orange,
                            backgroundColor: Colors.grey[300]!,
                          ),
                          onTap: () async {
                            final progreso = await Navigator.push (
                              context,
                              MaterialPageRoute(
                                builder: (_) => RutinaScreen(rutina: e),
                              ),
                            );
                            if (progreso != null) {
                              setState(() {
                                ejercicios[index]['progreso'] = progreso;
                              });
                            }
                          }
                        ),
                      );
                    },
                  ),
                ),

                // Promedio total con círculo estilizado
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
                      percent: promedio,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${(promedio * 100).toInt()}%",
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Promedio Total",
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
      bottomNavigationBar: const GymNavbar(currentIndex: 1),
    );
  }
}
