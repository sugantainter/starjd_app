import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import 'brand_campaign_detail_screen.dart';
import 'brand_create_campaign_screen.dart';

class BrandCampaignsScreen extends StatefulWidget {
  const BrandCampaignsScreen({super.key});

  @override
  State<BrandCampaignsScreen> createState() => _BrandCampaignsScreenState();
}

class _BrandCampaignsScreenState extends State<BrandCampaignsScreen> {
  bool _isLoading = true;
  List<dynamic> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    setState(() => _isLoading = true);
    final result = await BrandDashboardService.getCampaigns();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _campaigns = result['data']['campaigns'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Campaigns', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BrandCreateCampaignScreen()),
              );
              if (result == true) _fetchCampaigns();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
          : _campaigns.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchCampaigns,
                  color: const Color(0xFFE63946),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _campaigns.length,
                    itemBuilder: (context, index) {
                      final c = _campaigns[index];
                      return _buildCampaignCard(c);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 80, color: isDark ? Colors.white10 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No campaigns found.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : Colors.grey)),
          const SizedBox(height: 8),
          Text('Launch your first campaign to find creators!', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BrandCreateCampaignScreen()),
              );
              if (result == true) _fetchCampaigns();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create Campaign'),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(dynamic c) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String status = c['status'] ?? 'Draft';
    Color statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => BrandCampaignDetailScreen(campaignId: c['id']))
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  Text(
                     c['created_at'] != null ? c['created_at'].toString().split('T')[0] : '',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                c['title'] ?? 'Untitled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(_getCampaignIcon(c['campaign_type']), size: 14, color: isDark ? Colors.white30 : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    (c['campaign_type'] ?? 'General').toString().toUpperCase(),
                    style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
              Divider(height: 24, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat(Icons.people_outline, 'Applications', '${c['applications_count'] ?? 0}'),
                  _buildMiniStat(Icons.payments_outlined, 'Budget', '₹${c['budget'] ?? 0}'),
                  Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white30 : const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.purple;
      case 'draft': return Colors.grey;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getCampaignIcon(String? type) {
    switch (type) {
      case 'instagram': return Icons.camera_alt_outlined;
      case 'youtube': return Icons.play_circle_outline;
      case 'tiktok': return Icons.music_note_outlined;
      case 'ugc': return Icons.video_collection_outlined;
      default: return Icons.campaign_outlined;
    }
  }
}
