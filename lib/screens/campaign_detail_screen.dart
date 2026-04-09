import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/campaign_service.dart';
import '../env/env.dart';
import '../services/analytics_service.dart';

class CampaignDetailScreen extends StatefulWidget {
  final String slug;
  const CampaignDetailScreen({super.key, required this.slug});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _campaign;
  Map<String, dynamic>? _userData;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _userData = jsonDecode(userJson);
    }

    try {
      final data = await CampaignService.fetchCampaignDetail(widget.slug);
      if (mounted) {
        setState(() {
          _campaign = data;
          _isLoading = false;
        });
        
        AnalyticsService.logEvent(
          name: 'view_content',
          parameters: {
            'content_id': data['id'].toString(),
            'content_type': 'campaign',
            'content_name': data['title'],
          },
        );
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

  void _showApplyDialog() {
    final messageController = TextEditingController();
    final quoteController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply to Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Cover Message',
                  hintText: 'Tell the brand why you are a good fit...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quoteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quoted Amount (₹)',
                  hintText: 'e.g. 5000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final msg = messageController.text.trim();
              final quote = double.tryParse(quoteController.text) ?? 1.0;
              Navigator.pop(context);
              _submitApplication(msg, quote);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), foregroundColor: Colors.white),
            child: const Text('Send Application'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication(String msg, double quote) async {
    setState(() => _isApplying = true);
    final res = await CampaignService.applyToCampaign(
      campaignId: _campaign!['id'],
      coverMessage: msg,
      quotedAmount: quote,
    );
    if (mounted) {
      setState(() => _isApplying = false);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application sent successfully!')));
        
        AnalyticsService.logEvent(
          name: 'apply_to_campaign',
          parameters: {
            'campaign_id': _campaign!['id'].toString(),
            'quoted_amount': quote,
            'campaign_title': _campaign!['title'],
          },
        );
        
        _loadAll(); // Reload to update applications count
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator(color: Color(0xFFE63946))));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAll, child: const Text('Try Again')),
            ],
          ),
        ),
      );
    }

    if (_campaign == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Campaign not found')));
    }

    final c = _campaign!;
    final targeting = c['targeting'] as Map<String, dynamic>? ?? {};
    final isCreator = _userData?['role'] == 'creator' || _userData?['role'] == 'professional';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.campaign_outlined, size: 80, color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'OPEN',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                      Text(
                        'Posted: ${c['created_at'].toString().split('T')[0]}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(c['title'] ?? 'Untitled', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(c['brand']?['name'] ?? 'Unknown Brand', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      Icon(_getCampaignIcon(c['campaign_type']), size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(c['campaign_type']?.toUpperCase() ?? 'GENERAL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 40),
                  _buildSectionTitle('Description'),
                  Text(c['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),
                  if (c['deliverables'] != null) ...[
                    _buildSectionTitle('Deliverables'),
                    Text(c['deliverables'], style: const TextStyle(fontSize: 14, height: 1.5)),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionTitle('Targeting & Details'),
                  _buildInfoRow(Icons.payments_outlined, 'Budget', '₹${c['budget'] ?? 0}'),
                  _buildInfoRow(Icons.people_outline, 'Applications Limit', '${c['max_applications'] ?? 'Unlimited'} influencers'),
                  _buildInfoRow(Icons.category_outlined, 'Niches', (targeting['niches'] as List?)?.join(', ') ?? 'Any'),
                  _buildInfoRow(Icons.location_on_outlined, 'Locations', (targeting['countries'] as List?)?.join(', ') ?? 'Anywhere'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCreator
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: ElevatedButton(
                onPressed: _isApplying ? null : _showApplyDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isApplying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('APPLY NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  IconData _getCampaignIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'instagram': return Icons.camera_alt_outlined;
      case 'youtube': return Icons.play_circle_outline;
      case 'tiktok': return Icons.music_note_outlined;
      default: return Icons.campaign_outlined;
    }
  }
}
