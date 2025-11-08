import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YoutubeApiService {
  static final String apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  static const String baseUrl = 'https://www.googleapis.com/youtube/v3/search';

  static Future<List<Map<String, String>>> buscarVideos(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      '$baseUrl?part=snippet&type=video&maxResults=15&q=$query&key=$apiKey',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      print('Error YouTube: ${res.statusCode} - ${res.body}');
      return [];
    }

    final data = jsonDecode(res.body);
    final items = data['items'] as List<dynamic>? ?? [];

    return items.map<Map<String, String>>((item) {
      final snippet = item['snippet'] ?? {};
      final id = item['id']?['videoId'] ?? '';
      return {
        'id': id,
        'title': snippet['title'] ?? '',
        'thumbnail': snippet['thumbnails']?['high']?['url'] ?? '',
        'channel': snippet['channelTitle'] ?? '',
      };
    }).toList();
  }
}
