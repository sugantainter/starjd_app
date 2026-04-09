import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_service.dart';
import '../services/app_service_api.dart';
import 'service_detail_screen.dart';

class ServiceListingScreen extends StatefulWidget {
  const ServiceListingScreen({super.key});

  @override
  State<ServiceListingScreen> createState() => _ServiceListingScreenState();
}

class _ServiceListingScreenState extends State<ServiceListingScreen> {
  List<AppService> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final services = await AppServiceApi.fetchServices();
      if (mounted) {
        setState(() {
          _services = services;
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Our Services', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)));
    if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
    if (_services.isEmpty) return Center(child: Text('No services found.', style: TextStyle(color: theme.textTheme.bodyLarge?.color)));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFE63946),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final svc = _services[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ServiceDetailScreen(slug: svc.slug)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                   if (svc.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: svc.imageUrl,
                        width: 100,
                        height: 100,
                        fit: svc.imageFit == 'contain' ? BoxFit.contain : BoxFit.cover,
                        placeholder: (_, __) => Container(width: 100, height: 100, color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                        errorWidget: (_, __, ___) => Container(width: 100, height: 100, color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                      ),
                    )
                  else
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      ),
                      child: Icon(Icons.business_center, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(svc.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                          if (svc.shortDescription != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              svc.shortDescription!,
                              style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
