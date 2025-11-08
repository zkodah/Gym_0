import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_youtube.dart';
import 'package:flutter_application_1/screen/videos.dart';

class YoutubeSearchScreen extends StatefulWidget {
  const YoutubeSearchScreen({super.key});

  @override
  State<YoutubeSearchScreen> createState() => _YoutubeSearchScreenState();
}

class _YoutubeSearchScreenState extends State<YoutubeSearchScreen> {
  List<Map<String, String>> resultados = [];
  bool cargando = false;
  String? error;
  Timer? _debounce;

  void _buscar(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final query = q.trim();
      if (query.isEmpty) {
        setState(() {
          resultados = [];
          error = null;
        });
        return;
      }

      setState(() {
        cargando = true;
        error = null;
      });

      try {
        final data = await YoutubeApiService.buscarVideos(query);
        setState(() {
          resultados = data;
          cargando = false;
          if (data.isEmpty) error = 'Sin resultados.';
        });
      } catch (e) {
        setState(() {
          cargando = false;
          error = 'Error: $e';
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
      appBar: AppBar(title: const Text('Buscar ejercicios en YouTube')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ej: ejercicios de espalda...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              ),
              onChanged: _buscar,
            ),
          ),
          if (cargando) const LinearProgressIndicator(),
          if (error != null && resultados.isEmpty && !cargando)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          Expanded(
            child: resultados.isEmpty && !cargando
                ? const Center(child: Text('No hay videos para mostrar.'))
                : ListView.builder(
                    itemCount: resultados.length,
                    itemBuilder: (context, i) {
                      final v = resultados[i];
                      return ListTile(
                        leading: v['thumbnail']!.isNotEmpty
                            ? Image.network(v['thumbnail']!, width: 90, fit: BoxFit.cover)
                            : const Icon(Icons.video_library),
                        title: Text(v['title'] ?? ''),
                        subtitle: Text(v['channel'] ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(videoId: v['id']!),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
