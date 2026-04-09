import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env/env.dart';
import '../models/app_video.dart';

class VideoService {
  static String get _base => Env.apiUrl;

  static const Map<String, String> _h = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<List<AppVideo>> fetchVideos() async {
    final uri = Uri.parse('$_base/api/videos');
    final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final data = json['videos'] as List<dynamic>? ?? [];
      return data.map((v) => AppVideo.fromJson(v)).toList();
    }
    throw Exception('Failed to load videos: ${res.statusCode}');
  }
}
