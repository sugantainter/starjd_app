import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class BrandCampaignDetailScreen extends StatefulWidget {
  final int campaignId;
  const BrandCampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<BrandCampaignDetailScreen> createState() => _BrandCampaignDetailScreenState();
}

class _BrandCampaignDetailScreenState extends State<BrandCampaignDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _campaign;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final result = await BrandDashboardService.getCampaignDetail(widget.campaignId);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _campaign = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleStatusUpdate(int appId, String status) async {
    setState(() => _isProcessing = true);
    final result = await BrandDashboardService.updateApplicationStatus(appId, status);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $status successfully.')),
        );
        _fetchDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Campaign Detail', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // TODO: Edit Campaign
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
          : RefreshIndicator(
              onRefresh: _fetchDetail,
              color: const Color(0xFFE63946),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCampaignHeader(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Applications'),
                    _buildApplicationsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCampaignHeader() {
    final c = _campaign ?? {};
    final targeting = c['targeting'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(c['status']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (c['status'] ?? 'Draft').toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(c['status'])),
                ),
              ),
              Text(
                'Created: ${c['created_at'] != null ? c['created_at'].toString().split('T')[0] : ''}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            c['title'] ?? 'Untitled',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_getCampaignIcon(c['campaign_type']), size: 16, color: const Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                (c['campaign_type'] ?? 'General').toString().toUpperCase(),
                style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow('Budget', '₹${c['budget'] ?? 0}'),
          _buildInfoRow('Limit', '${c['max_applications'] ?? 0} Influencers'),
          _buildInfoRow('Niches', (targeting['niches'] as List<dynamic>? ?? []).join(', ').isEmpty ? 'None' : (targeting['niches'] as List).join(', ')),
          _buildInfoRow('Location', (targeting['countries'] as List<dynamic>? ?? []).join(', ').isEmpty ? 'Anywhere' : (targeting['countries'] as List).join(', ')),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    final apps = (_campaign?['applications'] as List<dynamic>?) ?? [];
    if (apps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.group_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No applications yet.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final creator = app['creator'] ?? {};
        final status = app['status'] ?? 'pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(creator['name'] ?? 'Creator', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(app['cover_message'] ?? 'No message provided.', maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Quote: ₹${app['quoted_amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
                trailing: _getStatusChip(status),
              ),
              if (status == 'pending')
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : () => _handleStatusUpdate(app['id'], 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _handleStatusUpdate(app['id'], 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _getStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      case 'pending': color = Colors.orange; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open': return Colors.green;
      case 'draft': return Colors.grey;
      case 'completed': return Colors.purple;
      case 'in_progress': return Colors.blue;
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9CA3AF),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
