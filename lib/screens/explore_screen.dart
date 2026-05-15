import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/creator.dart';
import '../services/creator_service.dart';
import '../screens/creator_profile_screen.dart';
import '../services/analytics_service.dart';
import 'notifications_screen.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_wrapper.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialQuery;

  const ExploreScreen({super.key, this.initialQuery});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // ── State ─────────────────────────────────────────────────────────────
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  CreatorFilters _filters = const CreatorFilters();
  String? _selectedCategory;
  String? _selectedPlatform;
  String _sort = 'newest';

  List<Creator> _creators = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // ── Init ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _loadFilters();
    _loadCreators(refresh: true);
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

  Future<void> _loadFilters() async {
    final f = await CreatorService.fetchFilters();
    if (mounted) setState(() => _filters = f);
  }

  Future<void> _loadCreators({bool refresh = false}) async {
    if (refresh) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMore = true;
          _creators = [];
        });
      }
    }
    try {
      final result = await CreatorService.fetchCreators(
        category: _selectedCategory,
        platform: _selectedPlatform,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sort: _sort,
        page: _currentPage,
      );

      if (_searchController.text.trim().isNotEmpty) {
        AnalyticsService.logEvent(
          name: 'search',
          parameters: {'search_string': _searchController.text.trim()},
        );
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _creators = result.creators;
          } else {
            _creators.addAll(result.creators);
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
      final result = await CreatorService.fetchCreators(
        category: _selectedCategory,
        platform: _selectedPlatform,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        sort: _sort,
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _creators.addAll(result.creators);
          _hasMore = result.currentPage < result.lastPage;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _showSortSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final options = [
      ('newest', 'Newest First'),
      ('followers', 'Most Followers'),
      ('rating', 'Top Rated'),
      ('price', 'Price: Low to High'),
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
                    color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Text('Sort Creators',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 10),
            ...options.map((o) => ListTile(
                  title: Text(o.$2, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  trailing: _sort == o.$1
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFFE63946))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _sort = o.$1);
                    _loadCreators(refresh: true);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String? tempCategory = _selectedCategory;
    String? tempPlatform = _selectedPlatform;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, sc) => SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Filter Creators',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setSheet(() {
                          tempCategory = null;
                          tempPlatform = null;
                        });
                      },
                      child: const Text('Clear all',
                          style: TextStyle(color: Color(0xFFE63946))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Categories
                if (_filters.categories.isNotEmpty) ...[
                  Text('Category',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.titleMedium?.color)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filters.categories.map((c) {
                      final sel = tempCategory == c;
                      return GestureDetector(
                        onTap: () => setSheet(
                            () => tempCategory = sel ? null : c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFE63946)
                                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFE63946)
                                  : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: sel
                                      ? Colors.white
                                      : theme.textTheme.bodyMedium?.color)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
                // Platforms
                if (_filters.platforms.isNotEmpty)...[
                  Text('Platform',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.titleMedium?.color)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filters.platforms.map((p) {
                      final sel = tempPlatform == p.toLowerCase();
                      return GestureDetector(
                        onTap: () => setSheet(() =>
                            tempPlatform =
                                sel ? null : p.toLowerCase()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF6366F1)
                                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: sel
                                      ? Colors.white
                                      : theme.textTheme.bodyMedium?.color)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedCategory = tempCategory;
                        _selectedPlatform = tempPlatform;
                      });
                      _loadCreators(refresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE63946),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasFilters =
        _selectedCategory != null || _selectedPlatform != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveWrapper(
        child: SafeArea(
          child: Column(
          children: [
            // Header
            Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      if (Navigator.canPop(context)) const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Creators',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleLarge?.color)),
                            Text('Find your perfect influencer',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, child) {
                          final count = notificationProvider.unreadCount;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                                  Future.delayed(const Duration(seconds: 2), () => notificationProvider.refreshCount());
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.notifications_none_rounded, size: 20, color: theme.iconTheme.color),
                                ),
                              ),
                              if (count > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE63946),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                    child: Text(
                                      count > 9 ? '9+' : count.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _loadCreators(refresh: true),
                          textInputAction: TextInputAction.search,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                                color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), fontSize: 14),
                            prefixIcon: Icon(Icons.search,
                                color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      _loadCreators(refresh: true);
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sort button
                      GestureDetector(
                        onTap: _showSortSheet,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.sort_rounded, size: 20, color: theme.iconTheme.color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter button
                      GestureDetector(
                        onTap: _showFilterSheet,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: hasFilters
                                    ? const Color(0xFFE63946)
                                    : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 20,
                                color: hasFilters ? Colors.white : theme.iconTheme.color,
                              ),
                            ),
                            if (hasFilters)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE63946),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                  ),
                                  child: Text(
                                    '${(_selectedCategory != null ? 1 : 0) + (_selectedPlatform != null ? 1 : 0)}',
                                    style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active filters summary row
            if (hasFilters)
              Container(
                color: theme.scaffoldBackgroundColor,
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded,
                        size: 14, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    if (_selectedCategory != null)
                      _activeFilterChip(_selectedCategory!, () {
                        setState(() => _selectedCategory = null);
                        _loadCreators(refresh: true);
                      }),
                    if (_selectedPlatform != null)
                      _activeFilterChip(_selectedPlatform!, () {
                        setState(() => _selectedPlatform = null);
                        _loadCreators(refresh: true);
                      }),
                  ],
                ),
              ),

            Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),

            // Body
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE63946).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFE63946).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE63946),
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: Color(0xFFE63946)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    if (_isLoading) return _buildSkeletonGrid();
    if (_isLoading) return _buildSkeletonGrid();
    if (_error != null) return _buildError();
    if (_creators.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: const Color(0xFFE63946),
      onRefresh: () => _loadCreators(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _creators.length + (_isLoadingMore ? 2 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: isTablet ? 0.75 : 0.62,
        ),
        itemBuilder: (context, i) {
          if (i >= _creators.length) return _skeletonCard();
          return _buildCreatorCard(_creators[i]);
        },
      ),
    );
  }

  // ── Creator Card ──────────────────────────────────────────────────────
  Widget _buildCreatorCard(Creator creator) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                CreatorProfileScreen(creatorSlug: creator.slug)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
           border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Avatar
                  creator.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: creator.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _skeletonCard(),
                          errorWidget: (context, url, error) => _avatarFallback(creator),
                        )
                      : _avatarFallback(creator),

                  // Featured badge
                  if (creator.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 10),
                            SizedBox(width: 3),
                            Text('Featured',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  // Verified badge
                  if (creator.isVerified)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.verified,
                          color: Color(0xFF3B82F6), size: 18),
                    ),

                  // Platform icons at bottom
                  if (creator.socialAccounts.isNotEmpty)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Row(
                        children: creator.socialAccounts.take(3).map((s) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(s.platformIcon,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          creator.displayName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.textTheme.titleMedium?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (creator.averageRating != null) ...[
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFBBF24), size: 13),
                        Text(
                          creator.averageRating!.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ],
                  ),
                  if (creator.formattedFollowers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${creator.formattedFollowers} followers',
                        style: TextStyle(
                            color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 10),
                      ),
                    ),
                  if (creator.tagline != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      creator.tagline!,
                      style: TextStyle(
                          color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (creator.category != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(creator.category!,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    creator.displayPrice,
                    style: const TextStyle(
                        color: Color(0xFFE63946),
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(Creator creator) {
    return Container(
      color: const Color(0xFF6366F1).withOpacity(0.15),
      child: Center(
        child: Text(
          creator.initials,
          style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1)),
        ),
      ),
    );
  }

  // ── Skeletons ─────────────────────────────────────────────────────────
  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (_, _) => _skeletonCard(),
    );
  }

  Widget _skeletonCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 64, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Text(
              'No creators found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters to find what you\'re looking for.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = null;
                  _selectedPlatform = null;
                  _sort = 'newest';
                });
                _loadCreators(refresh: true);
              },
              child: const Text('Clear all filters',
                  style: TextStyle(
                      color: Color(0xFFE63946), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error / Empty ─────────────────────────────────────────────────────
  Widget _buildError() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
             Text('Could not load creators',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: theme.brightness == Brightness.dark ? Colors.white30 : const Color(0xFF6B7280))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadCreators(refresh: true),
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
}
