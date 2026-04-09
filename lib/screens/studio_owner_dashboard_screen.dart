import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import 'manage_studios_screen.dart';
import 'edit_studio_screen.dart';
import 'studio_bookings_screen.dart';

class StudioOwnerDashboardScreen extends StatefulWidget {
  const StudioOwnerDashboardScreen({super.key});

  @override
  State<StudioOwnerDashboardScreen> createState() => _StudioOwnerDashboardScreenState();
}

class _StudioOwnerDashboardScreenState extends State<StudioOwnerDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    final result = await StudioOwnerDashboardService.getDashboardData();
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Studio Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
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
                    _buildRecentBookings(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Management'),
                    _buildManagementOption(
                      icon: Icons.storefront_outlined,
                      title: 'Manage Studios',
                      subtitle: 'List, edit, and update your studios',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStudiosScreen())),
                    ),
                    _buildManagementOption(
                      icon: Icons.calendar_today_outlined,
                      title: 'Bookings',
                      subtitle: 'View and manage studio bookings',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioBookingsScreen())),
                    ),
                    _buildManagementOption(
                      icon: Icons.access_time_outlined,
                      title: 'Availability',
                      subtitle: 'Set open hours and slots',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStudiosScreen())),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${_dashboardData?['user']?['name'] ?? 'Studio Owner'}!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your studio listings and bookings here.',
          style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _dashboardData?['stats'] ?? {};
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active',
            '${stats['active_studios'] ?? 0}',
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Bookings',
            '${stats['total_bookings'] ?? 0}',
            Icons.bookmark_border,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Earnings',
            '₹${stats['total_earnings'] ?? 0}',
            Icons.payments_outlined,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookings() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final list = (_dashboardData?['recent_bookings'] as List<dynamic>?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionTitle('Recent Activity'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final b = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: theme.cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isDark ? const BorderSide(color: Colors.white10) : BorderSide.none),
              child: ListTile(
                title: Text(b['customer'] ?? 'Unknown Customer', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                subtitle: Text('${b['studio']} • ${b['date']}', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey)),
                trailing: Text('₹${b['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE63946))),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white24 : const Color(0xFF9CA3AF),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE63946),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE63946).withValues(alpha: 0.3),
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
                  'List Your Studio',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Attract more creators to your space',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStudioScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE63946),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: isDark ? Colors.white30 : const Color(0xFF4B5563)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF6B7280))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
