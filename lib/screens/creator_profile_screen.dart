import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/creator.dart';
import '../services/creator_service.dart';
import '../services/auth_service.dart';
import '../services/collaboration_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorSlug;

  const CreatorProfileScreen({super.key, required this.creatorSlug});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen>
    with SingleTickerProviderStateMixin {
  Creator? _creator;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isFavorited = false;
  bool _isLoggedIn = false;
  String? _userRole;
  int? _userId;
  SocialAccount? _selectedAnalyticsAccount;
  int _activeMetricIndex = 3;
  String _activeMetricLabel = 'Views';
  String _activeMetricTabId = 'views';

  final Map<String, List<Map<String, dynamic>>> _platformTabs = {
    'youtube': [
      {'id': 'views', 'name': 'Views', 'index': 3},
      {'id': 'subscribers', 'name': 'Subscribers', 'index': 1},
      {'id': 'likes', 'name': 'Likes', 'index': 4},
    ],
    'facebook': [
      {'id': 'views', 'name': 'Reach', 'index': 3},
      {'id': 'engagement', 'name': 'Engagement', 'index': 1},
    ],
    'linkedin': [
      {'id': 'engagement', 'name': 'Engagement', 'index': 3},
      {'id': 'likes', 'name': 'Likes', 'index': 1},
      {'id': 'comments', 'name': 'Comments', 'index': 2},
    ],
    'instagram': [
      {'id': 'reach', 'name': 'Reach', 'index': 3},
      {'id': 'impressions', 'name': 'Impressions', 'index': 2},
    ],
    'pinterest': [
      {'id': 'impressions', 'name': 'Impressions', 'index': 1},
      {'id': 'saves', 'name': 'Saves', 'index': 2},
      {'id': 'clicks', 'name': 'Clicks', 'index': 3},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCreator();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final status = await AuthService.checkAuthStatus();
    if (status) {
       final user = await AuthService.getUser();
       if (mounted) setState(() { 
         _isLoggedIn = true;
         _userRole = user?['role'];
         _userId = user?['id'];
       });
    } else {
       if (mounted) setState(() => _isLoggedIn = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCreator() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      final c = await CreatorService.fetchCreatorDetail(widget.creatorSlug);
      if (mounted) setState(() { _creator = c; _isLoading = false; });
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
    if (_isLoading) return _loadingScreen();
    if (_error != null) return _errorScreen();
    return _buildProfile(_creator!);
  }

  // ── Loading / Error screens ───────────────────────────────────────────
  Widget _loadingScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            height: 300,
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFE63946), strokeWidth: 2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sh(160, 24), const SizedBox(height: 10),
                _sh(100, 14), const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _sh(double.infinity, 48)),
                  const SizedBox(width: 10),
                  Expanded(child: _sh(double.infinity, 48)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sh(double w, double h) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(8)));
  }

  Widget _errorScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined,
                  size: 56, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
              const SizedBox(height: 16),
              Text('Could not load creator',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchCreator,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main Profile ──────────────────────────────────────────────────────
  Widget _buildProfile(Creator creator) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Hero
          _buildHero(creator),
          // Info card
          _buildInfoCard(creator),
          // Tabs
          Container(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFE63946),
              unselectedLabelColor: theme.brightness == Brightness.dark ? Colors.white30 : const Color(0xFF6B7280),
              indicatorColor: const Color(0xFFE63946),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Packages'),
                Tab(text: 'Portfolio'),
              ],
            ),
          ),
          Divider(height: 1, color: theme.brightness == Brightness.dark ? Colors.white10 : const Color(0xFFE5E7EB)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _aboutTab(creator),
                _packagesTab(creator),
                _portfolioTab(creator),
              ],
            ),
          ),
          // CTA bar
          _ctaBar(creator),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────
  Widget _buildHero(Creator creator) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: creator.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: creator.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _heroBg(creator))
              : _heroBg(creator),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                begin: const Alignment(0, 0.2),
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _circleBtn(Icons.arrow_back_ios_new,
                      () => Navigator.pop(context)),
                  const Spacer(),
                  _circleBtn(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    () => setState(() => _isFavorited = !_isFavorited),
                    color: _isFavorited
                        ? const Color(0xFFE63946)
                        : const Color(0xFF1A1A1A),
                  ),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.share_outlined, () {}),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16, left: 16, right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (creator.isFeatured)
                    _heroBadge('Featured', Colors.purple.shade600,
                        icon: Icons.star_rounded),
                  if (creator.isFeatured) const SizedBox(width: 8),
                  if (creator.category != null)
                    _heroBadge(creator.category!, Colors.black54),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(creator.displayName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 26,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
                  ),
                  if (creator.isVerified)
                    const Icon(Icons.verified, color: Color(0xFF60A5FA), size: 22),
                ],
              ),
              if (creator.location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(creator.location!,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroBg(Creator creator) => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(creator.initials,
            style: const TextStyle(
                fontSize: 64, fontWeight: FontWeight.bold,
                color: Colors.white38)),
      ));

  // ── Info card ─────────────────────────────────────────────────────────
  Widget _buildInfoCard(Creator creator) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          _statPill(Icons.star_rounded,
              creator.averageRating?.toStringAsFixed(1) ?? '—',
              'Rating', const Color(0xFFFBBF24)),
          const SizedBox(width: 10),
          if (creator.formattedFollowers.isNotEmpty)...[
            _statPill(Icons.people_outline,
                creator.formattedFollowers, 'Followers',
                const Color(0xFF10B981)),
            const SizedBox(width: 10),
          ],
          _statPill(Icons.inventory_2_outlined,
              '${creator.packagesCount}', 'Packages',
              const Color(0xFF6366F1)),
        ],
      ),
    );
  }

  // ── ABOUT TAB ─────────────────────────────────────────────────────────
  Widget _aboutTab(Creator creator) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (creator.bio != null && creator.bio!.isNotEmpty) ...[
            _sectionTitle('About'),
            const SizedBox(height: 8),
            Text(creator.bio!,
                style: TextStyle(
                    fontSize: 14, color: isDark ? Colors.white60 : const Color(0xFF4B5563), height: 1.6)),
            const SizedBox(height: 24),
          ],

          // Tags row
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              if (creator.category != null)
                _infoChip(Icons.category_outlined, creator.category!),
              if (creator.language != null)
                _infoChip(Icons.language_outlined, creator.language!),
              if (creator.gender != null)
                _infoChip(Icons.person_outline, creator.gender!),
              if (creator.engagementRate != null)
                _infoChip(Icons.trending_up,
                    '${creator.engagementRate!.toStringAsFixed(1)}% Engagement'),
            ],
          ),
          const SizedBox(height: 24),

          // Social platforms
          if (creator.socialAccounts.isNotEmpty) ...[
            _sectionTitle('Social Platforms'),
            const SizedBox(height: 12),
            ...creator.socialAccounts.map(_platformCard),
          ],

          if (creator.socialAccounts.any((s) => s.analyticsData != null)) ...[
            const SizedBox(height: 24),
            _channelInsights(creator),
          ],
        ],
      ),
    );
  }

  Widget _channelInsights(Creator creator) {
    final accounts = creator.socialAccounts.where((s) => s.analyticsData != null).toList();
    if (accounts.isEmpty) return const SizedBox.shrink();

    _selectedAnalyticsAccount ??= accounts.first;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE63946).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, color: Color(0xFFE63946), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Channel Insights'),
                  Text('Audience performance & demographics',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : const Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Platform Tabs
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = accounts[i];
                final isSelected = _selectedAnalyticsAccount?.platform == s.platform;
                final Map<String, Color> colors = {
                  'instagram': const Color(0xFFE1306C),
                  'youtube': const Color(0xFFFF0000),
                  'tiktok': isDark ? Colors.white : const Color(0xFF010101),
                  'twitter': const Color(0xFF1DA1F2),
                  'x': isDark ? Colors.white : const Color(0xFF000000),
                  'facebook': const Color(0xFF1877F2),
                  'linkedin': const Color(0xFF0A66C2),
                  'pinterest': const Color(0xFFE60023),
                };
                final color = colors[s.platform.toLowerCase()] ?? const Color(0xFF6B7280);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnalyticsAccount = s;
                      final tabs = _platformTabs[s.platform.toLowerCase()] ?? [{'id': 'views', 'name': 'Views', 'index': 3}];
                      _activeMetricTabId = tabs[0]['id'];
                      _activeMetricIndex = tabs[0]['index'];
                      _activeMetricLabel = tabs[0]['name'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(s.platformIcon,
                            style: TextStyle(
                              color: isSelected ? (isDark ? Colors.black : Colors.white) : color,
                              fontSize: 11, fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(width: 8),
                        Text(s.platform[0].toUpperCase() + s.platform.substring(1),
                            style: TextStyle(
                              color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isLoggedIn && _selectedAnalyticsAccount != null) ...[
            // Metric Switcher Tabs
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (_platformTabs[_selectedAnalyticsAccount!.platform.toLowerCase()] ?? []).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tabs = _platformTabs[_selectedAnalyticsAccount!.platform.toLowerCase()]!;
                  final tab = tabs[index];
                  final isSelected = _activeMetricTabId == tab['id'];
                  
                  return InkWell(
                    onTap: () => setState(() {
                      _activeMetricTabId = tab['id'];
                      _activeMetricIndex = tab['index'];
                      _activeMetricLabel = tab['name'];
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : const Color(0xFFE5E7EB))),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tab['name'].toString().toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white30 : const Color(0xFF64748B)),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          _isLoggedIn ? _buildAnalyticsContent(_selectedAnalyticsAccount!, creator) : _buildLockOverlay(creator),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(SocialAccount account, Creator creator) {
    return Column(
      children: [
        _analyticsOverview(account),
        const SizedBox(height: 32),
        _growthChart(account),
        const SizedBox(height: 32),
        _topContent(account),
        const SizedBox(height: 32),
        _audienceDemographics(account),
      ],
    );
  }

  Widget _buildLockOverlay(Creator creator) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_rounded, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Analytics Locked',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            'Join our community to unlock real-time history, historical trends, and demographics for ${creator.displayName}.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Connect to StarJD',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsOverview(SocialAccount account) {
    final totalViews = _toDouble(account.analyticsData?['total_views']);
    final hasTotalViews = totalViews > 0;
    
    return Row(
      children: [
        Expanded(
          child: _analPill('Reach', NumberFormat.compact().format(_toDouble(account.followersCount)), Icons.people_outline, const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 12),
        if (hasTotalViews) ...[
          Expanded(
            child: _analPill('Total Views', NumberFormat.compact().format(totalViews), Icons.remove_red_eye_outlined, const Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _analPill('Platform', account.platform.toUpperCase(), Icons.language_outlined, const Color(0xFF8B5CF6)),
        ),
      ],
    );
  }

  Widget _analPill(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 14),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : const Color(0xFFA1A1AA), letterSpacing: 1.0)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5))),
        ],
      ),
    );
  }

  Widget _growthChart(SocialAccount account) {
    final history = (account.analyticsData?['history'] as List<dynamic>?) ?? [];
    if (history.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Safely parse history data
    final points = <FlSpot>[];
    final dateLabels = <String>[];
    for (var i = 0; i < history.length; i++) {
        final row = history[i];
        if (row is List && row.length > _activeMetricIndex) {
           final val = _toDouble(row[_activeMetricIndex]);
           points.add(FlSpot(i.toDouble(), val));
           
           try {
             final date = DateTime.parse(row[0].toString());
             dateLabels.add(DateFormat('d MMM').format(date));
           } catch (_) {
             dateLabels.add('');
           }
        }
    }
    if (points.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_activeMetricLabel.toUpperCase()} GROWTH (LAST 30 DAYS)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : const Color(0xFF94A3B8), letterSpacing: 0.5)),
            if (points.isNotEmpty)
              Text('AVG: ${NumberFormat.compact().format(points.map((p) => p.y).reduce((a, b) => a + b) / points.length)}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF3B82F6))),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (points.length / 5).clamp(1.0, 30.0),
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < dateLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(dateLabels[idx],
                              style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w500)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1000, // Reasonable interval
                    reservedSize: 30,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Text(NumberFormat.compact().format(val),
                          textAlign: TextAlign.left,
                          style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF94A3B8), fontSize: 9));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 12,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      final dateStr = (idx >= 0 && idx < dateLabels.length) ? dateLabels[idx] : '';
                      return LineTooltipItem(
                        '${spot.y.toInt()} ${_activeMetricLabel.toLowerCase()}\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        children: [
                          TextSpan(
                            text: dateStr,
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w400, fontSize: 10),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: points,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: const Color(0xFF3B82F6),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: const Color(0xFF3B82F6),
                      strokeWidth: 2,
                      strokeColor: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.15),
                        const Color(0xFF3B82F6).withOpacity(0.01),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topContent(SocialAccount account) {
    final videos = (account.analyticsData?['top_videos'] as List<dynamic>?) ?? [];
    if (videos.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOP CONTENT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : const Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ...videos.map((v) {
          final title = v['title'] ?? 'No Title';
          final views = v['views'] ?? 0;
          final thumb = v['thumbnail'] ?? '';
          
          String formatViews(dynamic n) {
            final x = _toDouble(n);
            if (x >= 1000000) return '${(x / 1000000).toStringAsFixed(1)}M';
            if (x >= 1000) return '${(x / 1000).toStringAsFixed(1)}K';
            return x.toInt().toString();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
              boxShadow: [
                if (!isDark)
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: thumb,
                    width: 90, height: 50,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                    errorWidget: (_, __, ___) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6), child: const Icon(Icons.video_library_outlined, size: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 12, color: isDark ? Colors.white30 : const Color(0xFFA1A1AA)),
                          const SizedBox(width: 4),
                          Text('${formatViews(views)} views',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _audienceDemographics(SocialAccount account) {
    final rawDemo = (account.analyticsData?['demographics'] as List<dynamic>?) ?? [];
    if (rawDemo.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final genderMap = <String, double>{};
    final ageMap = <String, double>{};
    
    for (final row in rawDemo) {
      if (row is List && row.length >= 3) {
        final age = row[0]?.toString() ?? 'Unknown';
        final gender = row[1]?.toString() ?? 'Other';
        final count = _toDouble(row[2]);
        
        genderMap[gender] = (genderMap[gender] ?? 0) + count;
        ageMap[age] = (ageMap[age] ?? 0) + count;
      }
    }

    final sortedAge = ageMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AUDIENCE DEMOGRAPHICS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : const Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('GENDER SPLIT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : const Color(0xFFA1A1AA), letterSpacing: 0.5)),
                        const SizedBox(height: 24),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 140,
                              child: PieChart(
                                PieChartData(
                                  sections: genderMap.entries.map((e) {
                                    final isMale = e.key.toLowerCase().contains('male') && !e.key.toLowerCase().contains('female');
                                    final isFemale = e.key.toLowerCase().contains('female');
                                    return PieChartSectionData(
                                      value: e.value,
                                      title: '',
                                      radius: 24,
                                      color: isFemale ? const Color(0xFFEC4899) : (isMale ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8)),
                                    );
                                  }).toList(),
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 46,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${genderMap.values.isNotEmpty ? NumberFormat.compact().format(genderMap.values.reduce((a, b) => a + b)) : 0}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Total', style: TextStyle(fontSize: 9, color: isDark ? Colors.white24 : const Color(0xFFA1A1AA))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _indicatorBox(const Color(0xFF3B82F6), 'Male'),
                            const SizedBox(width: 16),
                            _indicatorBox(const Color(0xFFEC4899), 'Female'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 230, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), margin: const EdgeInsets.symmetric(horizontal: 16)),
                  Expanded(
                    child: Column(
                      children: [
                        Text('AGE DISTRIBUTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : const Color(0xFFA1A1AA), letterSpacing: 0.5)),
                        const SizedBox(height: 24),
                        ...sortedAge.take(5).map((e) {
                          final total = ageMap.values.isNotEmpty ? ageMap.values.reduce((a, b) => a + b) : 1;
                          final percent = e.value / total;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
                                    Text('${(percent * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearPercentIndicator(
                                  lineHeight: 6,
                                  percent: percent.clamp(0.0, 1.0),
                                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                                  progressColor: const Color(0xFF3B82F6),
                                  barRadius: const Radius.circular(3),
                                  padding: EdgeInsets.zero,
                                  animation: true,
                                ),
                              ],
                            ),
                          );
                        }),
                        if (sortedAge.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text('No age data', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : const Color(0xFFA1A1AA))),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _indicatorBox(Color c, String label) => Row(
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
    ],
  );

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Widget _dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));


  Widget _platformCard(SocialAccount s) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Map<String, Color> colors = {
      'instagram': const Color(0xFFE1306C),
      'youtube': const Color(0xFFFF0000),
      'tiktok': isDark ? Colors.white : const Color(0xFF010101),
      'twitter': const Color(0xFF1DA1F2),
      'x': isDark ? Colors.white : const Color(0xFF000000),
      'facebook': const Color(0xFF1877F2),
      'linkedin': const Color(0xFF0A66C2),
    };
    final color = colors[s.platform.toLowerCase()] ??
        const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(
              child: Text(s.platformIcon,
                  style: TextStyle(
                      color: color, fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.platform.toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.titleSmall?.color)),
                if (s.username != null)
                  Text('@${s.username}',
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
              ],
            ),
          ),
          if (s.formattedFollowers.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(s.formattedFollowers,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15,
                        color: color)),
                Text('followers',
                    style: TextStyle(
                        fontSize: 10, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
              ],
            ),
        ],
      ),
    );
  }

  // ── PACKAGES TAB ──────────────────────────────────────────────────────
  Widget _packagesTab(Creator creator) {
    if (creator.packages.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 48, color: isDark ? Colors.white10 : const Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text('No packages available',
                  style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF6B7280))),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: creator.packages.length,
      itemBuilder: (_, i) => _packageCard(creator.packages[i]),
    );
  }

  Widget _packageCard(CreatorPackage p) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.titleSmall?.color)),
              ),
              Text('₹${p.price.toInt()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFFE63946))),
            ],
          ),
          if (p.category != null) ...[
            const SizedBox(height: 4),
            Text(p.category!,
                style: TextStyle(
                    fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
          ],
          if (p.description != null && p.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.description!,
                style: TextStyle(
                    fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF4B5563))),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                 if (!_isLoggedIn) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to collaborate')));
                   return;
                 }
                 if (_userRole != 'brand') {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only brand accounts can start collaborations')));
                   return;
                 }
                 _showCollaborationSheet(package: p);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE63946),
                side: const BorderSide(color: Color(0xFFE63946)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Select Package',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── PORTFOLIO TAB ─────────────────────────────────────────────────────
  Widget _portfolioTab(Creator creator) {
    if (creator.portfolio.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 48, color: isDark ? Colors.white10 : const Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text('No portfolio items yet',
                  style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF6B7280))),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: creator.portfolio.length,
      itemBuilder: (_, i) {
        final item = creator.portfolio[i];
        final url = item.image != null
            ? (item.image!.startsWith('http')
                ? item.image!
                : 'https://www.starjd.com${item.image}')
            : null;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url != null
              ? CachedNetworkImage(
                  imageUrl: url, 
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                      color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                      child: Icon(Icons.image_outlined,
                          color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))))
              : Container(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  child: Icon(Icons.image_outlined,
                      color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
        );
      },
    );
  }

  // ── CTA bar ───────────────────────────────────────────────────────────
  Widget _ctaBar(Creator creator) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Starting at',
                    style: TextStyle(
                        fontSize: 11, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
                Text(creator.displayPrice,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE63946))),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                   if (!_isLoggedIn) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to collaborate')));
                     return;
                   }
                   if (_userRole == 'brand') {
                     _showCollaborationSheet();
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are already a Creator/Admin')));
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_userRole == 'brand' ? 'Start Collaboration' : 'Contact Creator',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _circleBtn(IconData icon, VoidCallback onTap,
      {Color color = const Color(0xFF1A1A1A)}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1),
                blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 18, color: isDark && color == const Color(0xFF1A1A1A) ? Colors.white : color),
      ),
    );
  }

  Widget _heroBadge(String label, Color bg, {IconData? icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 11),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _statPill(IconData icon, String value, String label, Color col) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: col.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Icon(icon, color: col, size: 18),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: col)),
            Text(label,
                style: TextStyle(
                    fontSize: 9, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white24 : const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF374151))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    final theme = Theme.of(context);
    return Text(text,
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.titleMedium?.color));
  }

  void _showCollaborationSheet({CreatorPackage? package}) {
     if (_creator == null) return;
     final notesController = TextEditingController();
     bool localLoading = false;

     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       backgroundColor: Colors.transparent,
       builder: (ctx) => StatefulBuilder(
         builder: (ctx, setLocalState) => Container(
           padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
           decoration: BoxDecoration(
             color: Theme.of(ctx).scaffoldBackgroundColor,
             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
           ),
           child: SingleChildScrollView(
             padding: const EdgeInsets.all(24),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('Start Collaboration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                     IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                   ],
                 ),
                 const SizedBox(height: 16),
                 if (package != null) ...[
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: const Color(0xFFE63946).withOpacity(0.05),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: const Color(0xFFE63946).withOpacity(0.2)),
                     ),
                     child: Row(
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(package.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                               Text('Price: ₹${package.price.toInt()}', style: const TextStyle(fontSize: 12, color: Color(0xFFE63946))),
                             ],
                           ),
                         ),
                         const Icon(Icons.inventory_2_outlined, color: Color(0xFFE63946)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 20),
                 ],
                 const Text('Project Brief / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                 const SizedBox(height: 8),
                 TextField(
                   controller: notesController,
                   maxLines: 4,
                   decoration: InputDecoration(
                     hintText: 'Describe what you need...',
                     filled: true,
                     fillColor: Colors.black.withOpacity(0.04),
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                   ),
                 ),
                 const SizedBox(height: 24),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: localLoading ? null : () async {
                        if (_creator?.userId == null) return;
                        setLocalState(() => localLoading = true);
                        
                        final result = await CollaborationService.createCollaboration({
                          'creator_id': _creator!.userId,
                          'package_id': package?.id,
                          'amount': package?.price ?? _creator!.minPrice ?? _creator!.minRate ?? 0,
                          'brand_notes': notesController.text,
                        });

                        setLocalState(() => localLoading = false);
                        if (result['success']) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collaboration request sent!'), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error sending request')));
                        }
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFFE63946),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       elevation: 0,
                     ),
                     child: localLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm & Start Project', style: TextStyle(fontWeight: FontWeight.bold)),
                   ),
                 ),
                 const SizedBox(height: 12),
               ],
             ),
           ),
         ),
       ),
     );
  }
}
