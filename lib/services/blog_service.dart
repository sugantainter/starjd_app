import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env/env.dart';
import '../models/blog.dart';

class BlogService {
  static String get _base => Env.apiUrl;

  static const Map<String, String> _h = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<BlogPagination> fetchPosts({String? category, int page = 1}) async {
    final Map<String, String> queryParams = {'page': page.toString()};
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('$_base/api/posts').replace(queryParameters: queryParams);
    
    final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return BlogPagination.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load posts: ${res.statusCode}');
  }

  static Future<List<BlogCategory>> fetchCategories() async {
    final uri = Uri.parse('$_base/api/posts/categories');
    try {
      final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final cats = json['categories'] as List<dynamic>? ?? [];
        return cats.map((c) => BlogCategory.fromJson(c)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<BlogPostDetail> fetchPost(String slug) async {
    final uri = Uri.parse('$_base/api/posts/$slug');
    final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return BlogPostDetail.fromJson(jsonDecode(res.body));
    }
    if (res.statusCode == 404) throw Exception('Post not found');
    throw Exception('Failed to load post: ${res.statusCode}');
  }
}
