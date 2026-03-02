import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = "http://192.168.100.42:8080";

  // ── Helpers privados ───────────────────────────────────────────────────────

  static Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final token = await user.getIdToken();
    if (token == null) throw Exception('No se pudo obtener el token');
    return token;
  }

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── Rutinas ────────────────────────────────────────────────────────────────

  /// Devuelve el JSON completo de rutinas (sin auth, compatible con el flujo actual).
  static Future<Map<String, dynamic>> getRutinas() async {
    final response = await http.get(Uri.parse("$baseUrl/rutinas"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Error al cargar rutinas: ${response.statusCode}");
  }

  /// Devuelve la rutina personalizada del usuario autenticado.
  /// [meses] es opcional y sobreescribe el cálculo automático (útil para testing).
  static Future<List<dynamic>> getRutina({int? meses}) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '$baseUrl/rutina${meses != null ? "?meses=$meses" : ""}',
    );
    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // ── Usuario ────────────────────────────────────────────────────────────────

  /// Obtiene el perfil del usuario autenticado desde Firestore (vía backend).
  static Future<Map<String, dynamic>> getUsuario() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/usuario'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  /// Guarda o actualiza el perfil del usuario autenticado en Firestore (vía backend).
  static Future<void> guardarUsuario(Map<String, dynamic> perfil) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/usuario'),
      headers: _authHeaders(token),
      body: jsonEncode(perfil),
    );
    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  // Alias para compatibilidad con código existente
  static Future<void> saveUsuario(Map<String, dynamic> usuario) =>
      guardarUsuario(usuario);

  static Future buscarEjercicios(String query) async {}
}
