import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/campaign_service.dart';
import 'campaign_detail_screen.dart';
import '../env/env.dart';
import '../widgets/starjd_loader.dart';
import '../widgets/responsive_wrapper.dart';

class CampaignListingScreen extends StatefulWidget {
  const CampaignListingScreen({super.key});

  @override
  State<CampaignListingScreen> createState() => _CampaignListingScreenState();
}

class _CampaignListingScreenState extends State<CampaignListingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _campaigns = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadCampaigns({bool refresh = false}) async {
    if (refresh) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMore = true;
          _campaigns = [];
        });
      }
    }

    try {
      final result = await CampaignService.fetchCampaigns(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _campaigns = result.campaigns;
          } else {
            _campaigns.addAll(result.campaigns);
          }
          _hasMore = result.currentPage < result.lastPage;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
    }
    try {
      final result = await CampaignService.fetchCampaigns(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _campaigns.addAll(result.campaigns);
          _hasMore = result.currentPage < result.lastPage;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveWrapper(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadCampaigns(refresh: true),
              decoration: InputDecoration(
                hintText: 'Search campaigns...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const StarJDLoader();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCampaigns(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_campaigns.isEmpty) {
      return const Center(child: Text('No campaigns found.'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadCampaigns(refresh: true),
      color: const Color(0xFFE63946),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _campaigns.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _campaigns.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final campaign = _campaigns[index];
          return _buildCampaignCard(campaign);
        },
      ),
    );
  }

  Widget _buildCampaignCard(dynamic c) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String type = (c['campaign_type'] ?? 'General').toString().toUpperCase();

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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampaignDetailScreen(slug: c['slug'] ?? c['id'].toString()),
            ),
          );
        },
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
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'OPEN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
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
                c['title'] ?? 'Campaign Title',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business_outlined, size: 14, color: isDark ? Colors.white30 : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    c['brand']?['name'] ?? 'Unknown Brand',
                    style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.campaign_outlined, size: 14, color: isDark ? Colors.white30 : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    type,
                    style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
              if (c['description'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  c['description'],
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black87, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(Icons.people_outline, 'Applied', '${c['applications_count'] ?? 0}'),
                  _buildStat(Icons.payments_outlined, 'Budget', '₹${c['budget'] ?? 0}'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
