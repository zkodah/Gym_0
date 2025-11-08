import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://wger.de/api/v2";

  // Busca por nombre intentando varios idiomas (ES=4, EN=2, DE=1)
  static Future<List<dynamic>> buscarEjercicios(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // Idiomas: ES=4, EN=2 (rápido)
    final languages = [4, 2];
    for (final lang in languages) {
      final url = Uri.parse(
          "$baseUrl/exercise/?language=$lang&status=2&limit=15&name__icontains=$q");
      try {
        final res = await http.get(url);
        if (res.statusCode != 200) continue;
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = data["results"];
        if (list is List && list.isNotEmpty) return list;
      } catch (_) {}
    }
    return [];
  }

  // Obtiene imágenes del ejercicio (si existen)
  static Future<List<String>> obtenerImagenes(int exerciseId) async {
    final url =
        Uri.parse("$baseUrl/exerciseimage/?exercise=$exerciseId&limit=6");
    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return [];
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data["results"];
      if (list is! List) return [];
      return list
          .where((e) => e is Map && e["image"] is String)
          .map<String>((e) => e["image"] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
