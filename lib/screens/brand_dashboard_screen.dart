import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import 'brand_campaigns_screen.dart';
import 'brand_create_campaign_screen.dart';
import 'brand_campaign_detail_screen.dart';

class BrandDashboardScreen extends StatefulWidget {
  const BrandDashboardScreen({super.key});

  @override
  State<BrandDashboardScreen> createState() => _BrandDashboardScreenState();
}

class _BrandDashboardScreenState extends State<BrandDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final result = await BrandDashboardService.getDashboardData();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _dashboardData = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Brand Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: const Color(0xFFE63946),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentCampaigns(),
                    const SizedBox(height: 24),
                    _buildCollaborationSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${_dashboardData?['user']?['name'] ?? 'Brand Owner'}!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your campaigns and connect with creators.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _dashboardData?['campaign_stats'] ?? {};
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Active Campaigns',
          '${stats['open'] ?? 0}',
          Icons.campaign_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Apps',
          '${stats['total_applications'] ?? 0}',
          Icons.group_outlined,
          Colors.green,
        ),
        _buildStatCard(
          'Pending Apps',
          '${stats['pending_applications'] ?? 0}',
          Icons.pending_actions_outlined,
          Colors.orange,
        ),
        _buildStatCard(
          'Completed',
          '${stats['completed'] ?? 0}',
          Icons.task_alt_outlined,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Launch a Campaign',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Find the perfect creators for your brand',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandCreateCampaignScreen()));
              if (result == true) _fetchDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCampaigns() {
    final campaigns = (_dashboardData?['campaigns'] as List<dynamic>?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Active Campaigns'),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandCampaignsScreen())),
              child: const Text('See All', style: TextStyle(color: Color(0xFFE63946))),
            ),
          ],
        ),
        if (campaigns.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No campaigns yet.', style: TextStyle(color: Colors.grey))),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: campaigns.take(3).length,
            itemBuilder: (context, index) {
              final c = campaigns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF3F4F6),
                    child: Icon(_getCampaignIcon(c['campaign_type']), color: const Color(0xFF4B5563)),
                  ),
                  title: Text(c['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c['applications_count']} applications • Status: ${c['status']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => BrandCampaignDetailScreen(campaignId: c['id']))
                    );
                    if (result == true) _fetchDashboardData();
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCollaborationSection() {
    final collaborations = (_dashboardData?['collaborations'] as List<dynamic>?) ?? [];
    if (collaborations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Recent Collaborations'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: collaborations.take(3).length,
          itemBuilder: (context, index) {
            final col = collaborations[index];
            final creator = col['creator'] ?? {};
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(creator['name'] ?? 'Creator', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(col['package']?['name'] ?? 'Custom Deal'),
                trailing: Text('₹${col['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE63946))),
              ),
            );
          },
        ),
      ],
    );
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
