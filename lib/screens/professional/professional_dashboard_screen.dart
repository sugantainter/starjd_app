import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/professional_service.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({Key? key}) : super(key: key);

  @override
  _ProfessionalDashboardScreenState createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'listings_count': 0,
    'active_orders_count': 0,
    'total_earnings': 0
  };
  List<dynamic> _recentOrders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ProfessionalService.getProfessionalDashboard();
      setState(() {
        _stats = data['stats'] ?? _stats;
        _recentOrders = data['recent_orders'] ?? [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    final val = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Professional Dashboard', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: textMuted)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadDashboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: const Color(0xFFF59E0B),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text('Maximize your reach and manage your professional services.', style: TextStyle(color: textMuted, fontSize: 14)),
                      const SizedBox(height: 24),
                      
                      // Stat Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          _buildStatCard('Active Orders', _stats['active_orders_count'].toString(), cardColor, borderColor, textMuted, textColor),
                          _buildStatCard('Total Earnings', _formatCurrency(_stats['total_earnings']), cardColor, borderColor, textMuted, textColor),
                          _buildStatCard('Services Listed', _stats['listings_count'].toString(), cardColor, borderColor, textMuted, textColor),
                          _buildStatCard('Response Rate', '100%', cardColor, borderColor, textMuted, textColor),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      Text('Recent Orders', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      if (_recentOrders.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.shopping_bag_outlined, size: 32, color: textMuted),
                              ),
                              const SizedBox(height: 16),
                              Text('No recent orders', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text('Share your profile to get your first order!', style: TextStyle(color: textMuted)),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentOrders.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                            itemBuilder: (context, index) {
                              final order = _recentOrders[index];
                              final listing = order['listing'] ?? {};
                              final buyer = order['buyer'] ?? {};
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  listing['title'] ?? 'Unknown Service',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 14, color: textMuted),
                                      const SizedBox(width: 4),
                                      Text(buyer['name'] ?? 'Unknown Client', style: TextStyle(color: textMuted, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_formatCurrency(order['amount']), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.2) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (order['status']?.toString() ?? 'pending').toUpperCase(),
                                        style: const TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, Color cardColor, Color borderColor, Color textMuted, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
