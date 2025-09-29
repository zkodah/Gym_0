import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/widget/navbar.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  void cargarPerfil() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          userData = doc.data();
          loading = false;
        });
      } else if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }
      print("Error al cargar el perfil: $e");
    }
  }

  IconData _getObjectiveIcon(String objetivo) {
    switch (objetivo) {
      case "Bienestar/Salud":
        return Icons.favorite;
      case "Resistencia/Cardio":
        return Icons.monitor_heart;
      case "Hipertrofia":
        return Icons.fitness_center_rounded;
      default:
        return Icons.help_outline; // Ícono por defecto si no coincide
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: Colors.blueGrey,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("No se pudo cargar el perfil"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueGrey,
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.cake, color: Colors.blueGrey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Edad: ${userData!["edad"]}",
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.height, color: Colors.blueGrey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Altura: ${userData!["altura"]} m",
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.monitor_weight, color: Colors.blueGrey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Peso: ${userData!["peso"]} kg",
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getObjectiveIcon(userData!["objetivo"]),
                                  size: 40,
                                  color: const Color.fromARGB(255, 78, 98, 134),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Objetivo",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userData!["objetivo"],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: const GymNavbar(currentIndex: 2),
    );
  }
}
