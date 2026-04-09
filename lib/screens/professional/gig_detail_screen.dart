import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/professional_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../env/env.dart';

class GigDetailScreen extends StatefulWidget {
  final String slug;

  const GigDetailScreen({super.key, required this.slug});

  @override
  State<GigDetailScreen> createState() => _GigDetailScreenState();
}

class _GigDetailScreenState extends State<GigDetailScreen> {
  Map<String, dynamic>? _gig;
  bool _isLoading = true;
  String? _error;
  String _activePackageName = '';

  @override
  void initState() {
    super.initState();
    _loadGigDetails();
  }

  Future<void> _loadGigDetails() async {
    try {
      final data = await ProfessionalService.fetchGigDetail(widget.slug);
      if (mounted) {
        setState(() {
          _gig = data;
          _isLoading = false;
          if (data['pricing_tiers'] != null && (data['pricing_tiers'] as List).isNotEmpty) {
            _activePackageName = data['pricing_tiers'][0]['name'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic>? get _activePackage {
    if (_gig == null || _gig!['pricing_tiers'] == null) return null;
    final tiers = _gig!['pricing_tiers'] as List;
    for (var tier in tiers) {
      if (tier['name'] == _activePackageName) return tier as Map<String, dynamic>;
    }
    return tiers.isNotEmpty ? tiers[0] as Map<String, dynamic> : null;
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    try {
      final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
      return '₹${amount.toString().replaceAllMapped(formatter, (m) => ',')}';
    } catch (_) {
      return '₹$amount';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B))),
      );
    }

    if (_error != null || _gig == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load detail: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadGigDetails, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final user = _gig!['user'] ?? {};
    final prof = user['professional_profile'] ?? {};
    
    List<String> gallery = [];
    if (_gig!['gallery'] != null) {
      if (_gig!['gallery'] is String) {
        if (_gig!['gallery'].toString().trim().startsWith('[')) {
          try {
            List<dynamic> parsed = jsonDecode(_gig!['gallery']);
            gallery = parsed.map((e) => e.toString().startsWith('http') ? e.toString() : '${Env.apiUrl}${e.toString()}').toList();
          } catch (_) {}
        } else if (_gig!['gallery'].toString().trim().isNotEmpty) {
           String displayImage = _gig!['gallery'].toString();
           gallery = [displayImage.startsWith('http') ? displayImage : '${Env.apiUrl}$displayImage'];
        }
      } else if (_gig!['gallery'] is List) {
        gallery = (_gig!['gallery'] as List).map((e) => e.toString().startsWith('http') ? e.toString() : '${Env.apiUrl}${e.toString()}').toList();
      }
    }

    final faqs = (_gig!['faqs'] as List?) ?? [];
    final rating = prof['avg_rating']?.toString() ?? '5.0';
    final reviews = prof['total_reviews']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Gallery
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: gallery.isNotEmpty
                  ? PageView.builder(
                      itemCount: gallery.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: gallery[index]!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, e) => Container(color: Colors.grey[300]),
                        );
                      },
                    )
                  : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 64, color: Colors.white)),
            ),
            iconTheme: const IconThemeData(
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _gig!['title'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Seller Preview
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: user['avatar_url'] != null 
                             ? CachedNetworkImageProvider(user['avatar_url'].toString().startsWith('http') ? user['avatar_url'] : '${Env.apiUrl}${user['avatar_url']}') 
                             : null,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user['name'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('TOP RATED', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                                const SizedBox(width: 4),
                                Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 4),
                                Text('($reviews)', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 24),

                  // About Gig
                  const Text('About this gig', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    _gig!['description'] ?? '',
                    style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),

                  const SizedBox(height: 32),

                  // FAQs
                  if (faqs.isNotEmpty) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    const Text('FAQ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: faqs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final faq = faqs[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Text(faq['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              children: [
                                Text(
                                  faq['answer'] ?? '',
                                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : const Color(0xFF475569), height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // About the seller
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  const Text('About the seller', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? theme.cardColor : Colors.white,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundImage: user['avatar_url'] != null 
                                 ? CachedNetworkImageProvider(user['avatar_url'].toString().startsWith('http') ? user['avatar_url'] : '${Env.apiUrl}${user['avatar_url']}') 
                                 : null,
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    prof['tagline'] ?? '',
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                                      const SizedBox(width: 4),
                                      Text('$rating ($reviews reviews)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              side: BorderSide(color: isDark ? Colors.white : Colors.black),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Contact Me', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (prof['languages'] != null && (prof['languages'] as List).isNotEmpty)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('LANGUAGES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(
                                      (prof['languages'] as List).map((l) => l['name']).join(', '),
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AVG. RESPONSE TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    prof['response_time'] ?? '1 hour',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPricingBottomBar(theme, isDark),
    );
  }

  Widget _buildPricingBottomBar(ThemeData theme, bool isDark) {
    if (_gig == null || _activePackage == null) return const SizedBox.shrink();

    final tiers = _gig!['pricing_tiers'] as List;
    final pkg = _activePackage!;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs
            if (tiers.length > 1)
              Row(
                children: tiers.map((tier) {
                  final isActive = tier['name'] == _activePackageName;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activePackageName = tier['name']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? const Color(0xFFF59E0B) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          color: isActive ? const Color(0xFFF59E0B).withValues(alpha: 0.05) : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tier['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isActive ? const Color(0xFFF59E0B) : (isDark ? Colors.white54 : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Package Info & Action
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${pkg['name']} Package',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _formatCurrency(pkg['price']),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pkg['description'] ?? '',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${pkg['delivery']} Days Delivery', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      const Icon(Icons.sync, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${pkg['revisions'] == 20 ? 'Unlimited' : pkg['revisions']} Revisions', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Continue (${_formatCurrency(pkg['price'])})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
