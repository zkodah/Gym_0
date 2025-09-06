import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.100.42:8080";

  static Future<List<dynamic>> getEjercicios() async {
    final response = await http.get(Uri.parse("$baseUrl/ejercicios"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar ejercicios");
    }
  }

  static Future<Map<String, dynamic>> getUsuario() async {
    final response = await http.get(Uri.parse("$baseUrl/usuario"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al obtener usuario");
    }
  }

  static Future<void> saveUsuario(Map<String, dynamic> usuario) async {
    final response = await http.post(
      Uri.parse("$baseUrl/usuario"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(usuario),
    );
    if (response.statusCode != 200) {
      throw Exception("Error al guardar usuario");
    }
  }
}