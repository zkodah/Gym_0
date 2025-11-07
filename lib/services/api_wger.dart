import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://wger.de/api/v2";

  static Future<List<dynamic>> buscarEjercicios(String query) async {
    final url = Uri.parse("$baseUrl/exercise/?language=2&limit=15&name__icontains=$query");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception("Error al buscar ejercicios");
    }
  }
}
