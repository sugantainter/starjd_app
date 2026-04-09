import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final String slug;

  const BlogDetailScreen({super.key, required this.slug});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogPostDetail? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final post = await BlogService.fetchPost(widget.slug);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));
    if (_post == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Blog'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_post!.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(_post!.imageUrl, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_post!.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_post!.category!, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  Text(_post!.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(_post!.author ?? 'Admin', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text(_post!.date ?? '', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text('${_post!.viewCount}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 40, color: Color(0xFFE5E7EB)),
                  if (_post!.body != null)
                    Html(
                      data: _post!.body!,
                      style: {
                        "body": Style(fontSize: FontSize(15), lineHeight: LineHeight(1.6), color: const Color(0xFF374151)),
                        "h1": Style(fontSize: FontSize(22), fontWeight: FontWeight.bold),
                        "h2": Style(fontSize: FontSize(20), fontWeight: FontWeight.bold),
                        "h3": Style(fontSize: FontSize(18), fontWeight: FontWeight.bold),
                        "img": Style(width: Width.auto(), height: Height.auto()),
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
