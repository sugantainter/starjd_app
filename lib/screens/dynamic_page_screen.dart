import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../env/env.dart';

class DynamicPageScreen extends StatefulWidget {
  final String title;
  final String slug;

  const DynamicPageScreen({super.key, required this.title, required this.slug});

  @override
  State<DynamicPageScreen> createState() => _DynamicPageScreenState();
}

class _DynamicPageScreenState extends State<DynamicPageScreen> {
  String? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPageContent();
  }

  Future<void> _fetchPageContent() async {
    try {
      final response = await http.get(Uri.parse('${Env.apiUrl}/api/pages/${widget.slug}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _content = data['content'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load content';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Html(
                    data: _content ?? '',
                    style: {
                      "body": Style(
                        fontSize: FontSize(16),
                        lineHeight: LineHeight.em(1.5),
                        color: Colors.black87,
                      ),
                    },
                  ),
                ),
    );
  }
}
