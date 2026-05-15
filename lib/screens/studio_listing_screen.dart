import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/studio.dart';
import '../services/studio_service.dart';
import 'studio_detail_screen.dart';
import '../widgets/responsive_wrapper.dart';

class StudioListingScreen extends StatefulWidget {
  const StudioListingScreen({super.key});

  @override
  State<StudioListingScreen> createState() => _StudioListingScreenState();
}

class _StudioListingScreenState extends State<StudioListingScreen> {
  // ── State ─────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<StudioCategory> _categories = [];
  String? _selectedCategory; // slug or null = All

  List<Studio> _studios = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  bool _hasMore = true;

  String _sort = 'newest';

  // ── Init ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadStudios(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await StudioService.fetchCategories();
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _loadStudios({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
        _studios = [];
      });
    }

    try {
      final result = await StudioService.fetchStudios(
        category: _selectedCategory,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sort: _sort,
        page: _currentPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _studios = result.studios;
          } else {
            _studios.addAll(result.studios);
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
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    try {
      final result = await StudioService.fetchStudios(
        category: _selectedCategory,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sort: _sort,
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _studios.addAll(result.studios);
          _hasMore = result.currentPage < result.lastPage;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // ── Filters ───────────────────────────────────────────────────────────
  void _onCategoryTap(String? slug) {
    setState(() => _selectedCategory = slug);
    _loadStudios(refresh: true);
  }

  void _onSearch(String _) => _loadStudios(refresh: true);

  void _showSortSheet() {
    final theme = Theme.of(context);
    final options = [
      ('newest', 'Newest First'),
      ('rating', 'Top Rated'),
      ('price_low', 'Price: Low to High'),
      ('price_high', 'Price: High to Low'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Sort By',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
            const SizedBox(height: 12),
            ...options.map((opt) => ListTile(
                  title: Text(opt.$2, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  trailing: _sort == opt.$1
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFFE63946))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _sort = opt.$1);
                    _loadStudios(refresh: true);
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveWrapper(
        child: SafeArea(
          child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(),
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
            Expanded(
              child: isTablet 
                ? GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _studios.length,
                    itemBuilder: (_, i) => _buildStudioCard(_studios[i]),
                  )
                : _buildBody(),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.appBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 16, color: theme.iconTheme.color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Studios',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color)),
                Text('Find & book creative spaces',
                    style: TextStyle(
                        fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort_rounded, size: 16, color: isDark ? Colors.white70 : const Color(0xFF374151)),
                  const SizedBox(width: 4),
                  Text('Sort',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF374151))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.appBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onSubmitted: _onSearch,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by city or studio name...',
          hintStyle:
              TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon:
              Icon(Icons.search, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: theme.iconTheme.color),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  })
              : null,
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        onChanged: (v) {
          setState(() {});
          if (v.isEmpty) _onSearch('');
        },
      ),
    );
  }

  // ── Category chips ───────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.appBarTheme.backgroundColor,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length + 1, // +1 for All
        itemBuilder: (context, i) {
          final isAll = i == 0;
          final slug = isAll ? null : _categories[i - 1].slug;
          final label =
              isAll ? 'All' : _categories[i - 1].name;
          final isSelected = _selectedCategory == slug;

          return GestureDetector(
            onTap: () => _onCategoryTap(slug),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor
                      : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Body: loading / error / empty / list ─────────────────────────────
  Widget _buildBody() {
    if (_isLoading) return _buildSkeletonList();
    if (_error != null) return _buildError();
    if (_studios.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: const Color(0xFFE63946),
      onRefresh: () => _loadStudios(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _studios.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _studios.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFE63946), strokeWidth: 2)),
            );
          }
          return _buildStudioCard(_studios[i]);
        },
      ),
    );
  }

  // ── Skeleton loading ─────────────────────────────────────────────────
  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, _) => _buildSkeleton(),
    );
  }

  Widget _buildSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 300,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 180,
              decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(140, 16),
                const SizedBox(height: 8),
                _shimmerBox(100, 12),
                const SizedBox(height: 16),
                Row(children: [
                  _shimmerBox(60, 12),
                  const SizedBox(width: 8),
                  _shimmerBox(80, 12),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double w, double h) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: w, height: h, decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6)));
  }

  // ── Error state ───────────────────────────────────────────────────────
  Widget _buildError() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text('Could not load studios',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadStudios(refresh: true),
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
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 56, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text('No studios found',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 8),
            Text('Try a different category or search term.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedCategory = null);
                _loadStudios(refresh: true);
              },
              child: const Text('Clear filters',
                  style: TextStyle(color: Color(0xFFE63946))),
            ),
          ],
        ),
      ),
    );
  }

  // ── Studio Card ───────────────────────────────────────────────────────
  Widget _buildStudioCard(Studio studio) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StudioDetailScreen(studioId: studio.slug)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: studio.mainImage != null
                      ? CachedNetworkImage(
                          imageUrl: _baseUrl(studio.mainImage!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imageError(height: 180),
                          errorWidget: (_, __, ___) => _imageError(height: 180),
                        )
                      : _imageError(height: 180),
                ),
                // Top badges
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (studio.featured)
                        _imgBadge('Top Studio',
                            icon: Icons.workspace_premium_rounded,
                            bg: const Color(0xFFE63946)),
                      const Spacer(),
                      if (studio.ratingAvg != null)
                        _imgBadge(
                            studio.ratingAvg!.toStringAsFixed(1),
                            icon: Icons.star_rounded,
                            bg: Colors.black54,
                            iconColor: const Color(0xFFFBBF24)),
                    ],
                  ),
                ),
                // Type bottom left
                if (studio.category != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(studio.category!.name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF374151))),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(studio.name,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color)),
                  const SizedBox(height: 5),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(studio.locationDisplay,
                            style: TextStyle(
                                fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF6B7280)),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Footer: price + CTA
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studio.displayPrice,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE63946)),
                          ),
                          Text('${studio.reviewsCount} reviews',
                              style: TextStyle(
                                  fontSize: 11, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => StudioDetailScreen(
                                  studioId: studio.slug)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE63946),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  String _baseUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'https://www.starjd.com$path';
  }

  Widget _imageError({double height = 180}) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: height == 180
              ? const BorderRadius.vertical(top: Radius.circular(20))
              : null,
        ),
        child: Center(
          child: Icon(Icons.camera_alt_outlined,
              size: height * 0.3, color: Colors.white54),
        ),
      );

  Widget _imgBadge(String label,
      {IconData? icon,
      required Color bg,
      Color iconColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 12),
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
}
