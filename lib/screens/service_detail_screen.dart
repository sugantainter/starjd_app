import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/app_service.dart';
import '../services/app_service_api.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String slug;

  const ServiceDetailScreen({super.key, required this.slug});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  AppServiceDetail? _service;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    try {
      final svc = await AppServiceApi.fetchService(widget.slug);
      if (mounted) {
        setState(() {
          _service = svc;
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
    if (_service == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_service!.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_service!.bannerImageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(_service!.bannerImageUrl, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_service!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (_service!.shortDescription != null) ...[
                    const SizedBox(height: 8),
                    Text(_service!.shortDescription!, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                  ],
                  const SizedBox(height: 24),
                  if (_service!.body != null)
                    Html(
                      data: _service!.body!,
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
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Contact Us for this Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
