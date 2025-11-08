/*
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/widget/navbar.dart';
import '../services/api_wger.dart';
import 'detalle_ejercicio.dart';

class DetallesScreen extends StatefulWidget {
  const DetallesScreen({super.key});

  @override
  State<DetallesScreen> createState() => _DetallesScreenState();
}

class _DetallesScreenState extends State<DetallesScreen> {
  List<dynamic> resultados = [];
  bool loading = false;
  String? errorMsg;
  Timer? _debounce;

  void _buscar(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final query = q.trim();
      if (query.isEmpty) {
        if (!mounted) return;
        setState(() {
          resultados = [];
          errorMsg = null;
        });
        return;
      }
      setState(() {
        loading = true;
        errorMsg = null;
      });
      try {
        final data = await ApiService.buscarEjercicios(query);
        if (!mounted) return;
        setState(() {
          resultados = data;
          loading = false;
          if (data.isEmpty) {
            errorMsg = "Sin resultados.";
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          loading = false;
          errorMsg = "Error: $e";
          resultados = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar ejercicios")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Ej: sentadilla, pecho...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onChanged: _buscar,
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (errorMsg != null && resultados.isEmpty && !loading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                errorMsg!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: resultados.isEmpty && !loading
                ? const Center(child: Text("No hay ejercicios para mostrar."))
                : ListView.builder(
                    itemCount: resultados.length,
                    itemBuilder: (context, i) {
                      final raw = resultados[i];
                      if (raw is! Map) return const SizedBox.shrink();
                      final e = Map<String, dynamic>.from(raw);
                      final nombre = e["name"]?.toString() ?? "Sin nombre";
                      final desc = (e["description"]?.toString() ?? "")
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .trim();
                      return ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(nombre),
                        subtitle: Text(
                          desc.length > 80 ? "${desc.substring(0, 80)}…" : desc,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleEjercicioScreen(ejercicio: e),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const GymNavbar(currentIndex: 0),
    );
  }
}
*/