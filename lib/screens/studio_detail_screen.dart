import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/studio.dart';
import '../services/studio_service.dart';
import '../services/analytics_service.dart';

class StudioDetailScreen extends StatefulWidget {
  /// Pass either a slug (e.g. "lensbox-studio") or a numeric id as string.
  final String studioId;

  const StudioDetailScreen({super.key, required this.studioId});

  @override
  State<StudioDetailScreen> createState() => _StudioDetailScreenState();
}

class _StudioDetailScreenState extends State<StudioDetailScreen>
    with SingleTickerProviderStateMixin {
  // ── API State ─────────────────────────────────────────────────────────
  Studio? _studio;
  bool _isLoading = true;
  String? _error;

  // ── UI State ──────────────────────────────────────────────────────────
  late TabController _tabController;
  int _selectedHours = 2;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final studio =
          await StudioService.fetchStudioDetail(widget.studioId);
      if (mounted) {
        setState(() {
          _studio = studio;
          _isLoading = false;
        });
        
        AnalyticsService.logEvent(
          name: 'view_content',
          parameters: {
            'content_id': studio.id.toString(),
            'content_type': 'studio',
            'content_name': studio.name,
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

  // ── Computed helpers ──────────────────────────────────────────────────
  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_selectedDate.day} ${months[_selectedDate.month - 1]}, ${_selectedDate.year}';
  }

  int get _totalPrice =>
      (_studio?.pricePerHourInt ?? 0) * _selectedHours;

  String _imageUrl(String? path) {
    if (path == null) return '';
    if (path.startsWith('http')) return path;
    return 'https://www.starjd.com$path';
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScreen();
    if (_error != null) return _buildErrorScreen();
    return _buildDetail(_studio!);
  }

  // ── Loading screen ────────────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            height: 260,
            width: double.infinity,
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            child: const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFE63946), strokeWidth: 2),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(200, 24),
                  const SizedBox(height: 10),
                  _shimmer(130, 14),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: _shimmer(double.infinity, 60)),
                    const SizedBox(width: 10),
                    Expanded(child: _shimmer(double.infinity, 60)),
                    const SizedBox(width: 10),
                    Expanded(child: _shimmer(double.infinity, 60)),
                  ]),
                  const SizedBox(height: 24),
                  _shimmer(double.infinity, 14),
                  const SizedBox(height: 8),
                  _shimmer(double.infinity, 14),
                  const SizedBox(height: 8),
                  _shimmer(180, 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(double w, double h) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(8)));
  }

  // ── Error screen ──────────────────────────────────────────────────────
  Widget _buildErrorScreen() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 56, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
              const SizedBox(height: 16),
              Text('Failed to load studio',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchDetail,
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

  // ── Main detail layout ────────────────────────────────────────────────
  Widget _buildDetail(Studio studio) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHero(studio),
          _buildInfoCard(studio),
          _buildTabBar(),
          Divider(height: 1, color: theme.brightness == Brightness.dark ? Colors.white10 : const Color(0xFFE5E7EB)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _overviewTab(studio),
                _amenitiesTab(studio.amenities),
                _reviewsTab(studio),
              ],
            ),
          ),
          _bookingBar(studio),
        ],
      ),
    );
  }

  // ── Hero Image ────────────────────────────────────────────────────────
  Widget _buildHero(Studio studio) {
    final imageUrl = _imageUrl(studio.mainImage);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _heroPlaceholder(),
                  placeholder: (context, url) => _heroPlaceholder(),
                )
              : _heroPlaceholder(),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, (isDark ? Colors.black : Colors.black54)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _circleBtn(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  _circleBtn(
                    icon: _isFavorited
                        ? Icons.favorite
                        : Icons.favorite_border,
                    iconColor: _isFavorited
                        ? const Color(0xFFE63946)
                        : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                    onTap: () =>
                        setState(() => _isFavorited = !_isFavorited),
                  ),
                  const SizedBox(width: 8),
                  _circleBtn(icon: Icons.share_outlined, onTap: () {}),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: Row(
            children: [
              if (studio.featured)
                _heroBadge('Top Studio',
                    icon: Icons.workspace_premium_rounded,
                    bg: const Color(0xFFE63946)),
              if (studio.featured) const SizedBox(width: 8),
              if (studio.category != null)
                _heroBadge(studio.category!.name, bg: Colors.black54),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.camera_alt_outlined,
              size: 80, color: Colors.white38),
        ),
      );

  // ── Info Card ─────────────────────────────────────────────────────────
  Widget _buildInfoCard(Studio studio) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(studio.name,
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                        letterSpacing: -0.3)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
              const SizedBox(width: 3),
              Expanded(
                child: Text(studio.locationDisplay,
                    style: TextStyle(
                        fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip(Icons.star_rounded,
                  studio.ratingAvg != null
                      ? studio.ratingAvg!.toStringAsFixed(1)
                      : '—',
                  '${studio.reviewsCount} reviews',
                  const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              if (studio.pricePerHour != null)
                _statChip(Icons.access_time,
                    '₹${studio.pricePerHourInt}', 'per hour',
                    const Color(0xFFE63946)),
              if (studio.pricePerHour != null) const SizedBox(width: 8),
              if (studio.pricePerDay != null)
                _statChip(Icons.calendar_today_outlined,
                    '₹${studio.pricePerDay!.toInt()}', 'per day',
                    const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── TabBar ────────────────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE63946),
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : const Color(0xFF6B7280),
          indicatorColor: const Color(0xFFE63946),
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Amenities'),
            Tab(text: 'Reviews'),
          ],
        ),
      );

  // ────────────────────────────────────────────────────────────────────────
  // OVERVIEW TAB
  // ────────────────────────────────────────────────────────────────────────
  Widget _overviewTab(Studio studio) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (studio.description != null && studio.description!.isNotEmpty) ...[
            _sectionTitle('About This Studio'),
            const SizedBox(height: 8),
            Html(
              data: studio.description!,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(14.0),
                  color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                  lineHeight: const LineHeight(1.6),
                ),
              },
            ),
            const SizedBox(height: 24),
          ],

          // Address
          if (studio.address != null) ...[
            _sectionTitle('Address'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Color(0xFFE63946)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      studio.address,
                      studio.city,
                      studio.state,
                      if (studio.pincode != null) studio.pincode
                    ].where((v) => v != null && v.isNotEmpty).join(', '),
                    style: TextStyle(
                        fontSize: 14, color: isDark ? Colors.white60 : const Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Date picker
          _sectionTitle('Choose Date'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate:
                    DateTime.now().add(const Duration(days: 90)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: Color(0xFFE63946))),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFFE63946), size: 20),
                  const SizedBox(width: 12),
                  Text(_formattedDate,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color)),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),

          if (studio.pricePerHour != null) ...[
            const SizedBox(height: 24),
            _sectionTitle('Duration (hours)'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [1, 2, 3, 4, 6, 8].map((h) {
                  final sel = _selectedHours == h;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedHours = h),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFFE63946)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${h}h',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: sel
                                    ? Colors.white
                                    : (isDark ? Colors.white30 : const Color(0xFF6B7280)))),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Price Breakdown'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _priceRow(
                      '₹${studio.pricePerHourInt}/hr × ${_selectedHours}h',
                      '₹$_totalPrice'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                        height: 1, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                  ),
                  _priceRow('Service fee (10%)',
                      '₹${(_totalPrice * 0.1).toInt()}'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                        height: 1, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                  ),
                  Row(
                    children: [
                      Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.textTheme.titleSmall?.color)),
                      const Spacer(),
                      Text(
                        '₹${(_totalPrice * 1.1).toInt()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE63946)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // AMENITIES TAB
  // ────────────────────────────────────────────────────────────────────────
  Widget _amenitiesTab(List<StudioAmenity> amenities) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (amenities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: isDark ? Colors.white10 : const Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text('No amenities listed',
                  style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
            ],
          ),
        ),
      );
    }

    final Map<String, IconData> iconMap = {
      'wifi': Icons.wifi,
      'parking': Icons.local_parking,
      'ac': Icons.ac_unit,
      'air': Icons.ac_unit,
      'catering': Icons.restaurant_menu_outlined,
      'makeup': Icons.face_retouching_natural,
      'dressing': Icons.checkroom_outlined,
      'changing': Icons.checkroom_outlined,
      'lounge': Icons.weekend_outlined,
      'led': Icons.light_mode_outlined,
      'cyclorama': Icons.panorama_outlined,
      'sprung': Icons.grid_on_outlined,
      'mirror': Icons.crop_portrait_outlined,
      'sound': Icons.speaker_outlined,
      'recording': Icons.mic_outlined,
      'mixing': Icons.tune,
      'instrument': Icons.piano_outlined,
      'stream': Icons.videocam_outlined,
      'green': Icons.crop_free,
      'podcast': Icons.mic_none_outlined,
      'acoustic': Icons.layers_outlined,
      'set': Icons.view_module_outlined,
      'natural': Icons.wb_sunny_outlined,
      'props': Icons.category_outlined,
      'teleprompter': Icons.text_fields,
      'drone': Icons.airplanemode_active,
      'control': Icons.computer_outlined,
      '4k': Icons.videocam_outlined,
      'video': Icons.videocam_outlined,
      'camera': Icons.camera_alt_outlined,
    };

    IconData iconFor(String name) {
      final lower = name.toLowerCase();
      for (final entry in iconMap.entries) {
        if (lower.contains(entry.key)) return entry.value;
      }
      return Icons.check_circle_outline;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("What's Included"),
          const SizedBox(height: 4),
          Text('${amenities.length} amenities available',
              style: TextStyle(
                  color: isDark ? Colors.white24 : const Color(0xFF6B7280), fontSize: 13)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.0,
            children: amenities.map((a) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(iconFor(a.name),
                        color: const Color(0xFFE63946), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : const Color(0xFF374151)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Studio Rules'),
          const SizedBox(height: 14),
          ...[
            'No smoking or alcohol on premises',
            'Arrive 10 minutes before your slot',
            'Food & beverages in designated areas only',
            'Equipment must be returned in original condition',
            'Cancellations must be made 24 hours in advance',
          ].map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 15, color: isDark ? Colors.white24 : const Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(rule,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF4B5563))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // REVIEWS TAB
  // ────────────────────────────────────────────────────────────────────────
  Widget _reviewsTab(Studio studio) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      studio.ratingAvg != null
                          ? studio.ratingAvg!.toStringAsFixed(1)
                          : '—',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color),
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(Icons.star_rounded,
                              size: 16,
                              color: studio.ratingAvg != null &&
                                      i < studio.ratingAvg!.floor()
                                  ? const Color(0xFFFBBF24)
                                  : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)))),
                    ),
                    const SizedBox(height: 4),
                    Text('${studio.reviewsCount} reviews',
                        style: TextStyle(
                            fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((stars) {
                      final pct = stars == 5
                          ? 0.72
                          : stars == 4
                               ? 0.18
                                : 0.04;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('$stars',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white24 : const Color(0xFF6B7280))),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded,
                                size: 11, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor:
                                      isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                                  color: const Color(0xFFFBBF24),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (studio.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Text('No reviews yet',
                      style: TextStyle(color: isDark ? Colors.white10 : const Color(0xFF9CA3AF)))),
            )
          else ...[
            _sectionTitle('Recent Reviews'),
            const SizedBox(height: 14),
            ...studio.reviews.map(_reviewCard),
          ],
        ],
      ),
    );
  }

  Widget _reviewCard(StudioReview r) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initials =
        (r.userName ?? 'U').trim().split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE63946),
                child: Text(initials.isNotEmpty ? initials : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.userName ?? 'Anonymous',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.titleSmall?.color)),
                    Text(r.timeAgo,
                        style: TextStyle(
                            fontSize: 11, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 3),
                    Text(r.rating.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFFBBF24) : Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.comment!,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                    height: 1.5)),
          ],
        ],
      ),
    );
  }

  // ── Booking Bar ───────────────────────────────────────────────────────
  Widget _bookingBar(Studio studio) {
    final theme = Theme.of(context);
    if (studio.pricePerHour == null && studio.pricePerDay == null) {
      return Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Contact Studio',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (studio.pricePerHour != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹$_totalPrice',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE63946))),
                      Text(' total',
                          style: TextStyle(
                              fontSize: 12, color: theme.brightness == Brightness.dark ? Colors.white24 : const Color(0xFF9CA3AF))),
                    ],
                  ),
                  Text('$_selectedHours hr · $_formattedDate',
                      style: TextStyle(
                          fontSize: 11, color: theme.brightness == Brightness.dark ? Colors.white24 : const Color(0xFF9CA3AF))),
                ],
              ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showConfirmation(studio),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Book Now',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmation(Studio studio) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 16),
            Text('Booking Confirmed!',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 8),
            Text('${studio.name}\n$_selectedHours hrs · $_formattedDate',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 14)),
            const SizedBox(height: 6),
            Text('Total: ₹${(_totalPrice * 1.1).toInt()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFE63946))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  AnalyticsService.logEvent(
                    name: 'book_studio',
                    parameters: {
                      'studio_id': studio.id.toString(),
                      'amount': (_totalPrice * 1.1).toInt(),
                      'studio_name': studio.name,
                    },
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _circleBtn(
      {required IconData icon,
      required VoidCallback onTap,
      Color? iconColor}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor ?? theme.iconTheme.color),
      ),
    );
  }

  Widget _heroBadge(String label,
      {IconData? icon, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statChip(
      IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleLarge?.color));

  Widget _priceRow(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF4B5563))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleSmall?.color)),
      ],
    );
  }
}
