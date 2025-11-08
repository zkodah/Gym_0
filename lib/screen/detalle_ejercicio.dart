/* import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/api_wger.dart';

class DetalleEjercicioScreen extends StatefulWidget {
  final Map<String, dynamic> ejercicio;
  const DetalleEjercicioScreen({super.key, required this.ejercicio});

  @override
  State<DetalleEjercicioScreen> createState() => _DetalleEjercicioScreenState();
}

class _DetalleEjercicioScreenState extends State<DetalleEjercicioScreen> {
  YoutubePlayerController? _controller;
  late Future<List<String>> _imagenesFuture;

  @override
  void initState() {
    super.initState();
    final desc = widget.ejercicio["description"]?.toString() ?? "";
    final videoId = _extraerYoutubeId(desc);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }
    final rawId = widget.ejercicio["id"];
    final id = (rawId is int) ? rawId : int.tryParse(rawId.toString());
    _imagenesFuture = (id != null)
        ? ApiService.obtenerImagenes(id)
        : Future.value(<String>[]);
  }

  String? _extraerYoutubeId(String text) {
    final rx = RegExp(r'(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/[^\s)]+',
        caseSensitive: false);
    final match = rx.firstMatch(text);
    if (match == null) return null;
    final url = match.group(0)!; // corregido (quitado la comilla sobrante)
    return YoutubePlayer.convertUrlToId(url);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.ejercicio["name"]?.toString() ?? "Ejercicio";
    final desc = (widget.ejercicio["description"]?.toString() ?? "")
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();

    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_controller != null)
              YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
              )
            else
              FutureBuilder<List<String>>(
                future: _imagenesFuture,
                builder: (context, snapshot) {
                  final imgs = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (imgs.isEmpty) {
                    return const Text("Sin video ni imágenes disponibles.");
                  }
                  return SizedBox(
                    height: 220,
                    child: PageView.builder(
                      itemCount: imgs.length,
                      controller: PageController(viewportFraction: 0.9),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(imgs[i], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(desc.isEmpty ? "Sin descripción." : desc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/