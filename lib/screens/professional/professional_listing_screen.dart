import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/professional_gig.dart';
import '../../services/professional_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'gig_detail_screen.dart';

class ProfessionalListingScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategorySlug;

  const ProfessionalListingScreen({super.key, this.initialQuery, this.initialCategorySlug});

  @override
  State<ProfessionalListingScreen> createState() => _ProfessionalListingScreenState();
}

class _ProfessionalListingScreenState extends State<ProfessionalListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;
  
  List<ProfessionalGig> _gigs = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedServiceId;
  String _sortOrder = 'newest';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _loadCategories();
    _loadGigs(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadCategories() async {
    final List<Map<String, dynamic>> cats = await ProfessionalService.fetchMarketplaceFilters();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (widget.initialCategorySlug != null) {
          final found = cats.where((c) => c['slug'] == widget.initialCategorySlug).firstOrNull;
          if (found != null) {
            _selectedServiceId = int.tryParse(found['id'].toString());
            // Need to reload gigs now that we have the proper ID if it's the first load
            _loadGigs(refresh: true);
          }
        }
      });
    }
  }

  Future<void> _loadGigs({bool refresh = false}) async {
    if (refresh) {
      if (mounted) setState(() {
        _isLoading = true;
        _currentPage = 1;
        _gigs = [];
        _error = null;
      });
    }

    try {
      final result = await ProfessionalService.fetchMarketplaceGigs(
        serviceId: _selectedServiceId,
        search: _searchController.text.trim(),
        sort: _sortOrder,
        page: _currentPage,
      );

      if (mounted) setState(() {
        if (refresh) {
          _gigs = result.gigs;
        } else {
          _gigs.addAll(result.gigs);
        }
        _hasMore = result.currentPage < result.lastPage;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (mounted) setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    _loadGigs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Professional Marketplace', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                setState(() {});
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 600), () {
                  _loadGigs(refresh: true);
                });
              },
              onSubmitted: (_) {
                _searchTimer?.cancel();
                _loadGigs(refresh: true);
              },
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        _loadGigs(refresh: true);
                      },
                    )
                  : null,
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Categories Header
          if (_categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  final String catName = index == 0 ? 'All' : (_categories[index - 1]['name']?.toString() ?? '');
                  final int? catId = index == 0 ? null : (_categories[index - 1]['id'] is int ? _categories[index - 1]['id'] as int : int.tryParse(_categories[index - 1]['id']?.toString() ?? ''));
                  final isSelected = _selectedServiceId == catId;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(catName),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedServiceId = catId);
                        _loadGigs(refresh: true);
                      },
                      selectedColor: const Color(0xFFE63946),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? _buildErrorWidget()
                : _gigs.isEmpty 
                  ? _buildEmptyWidget()
                  : _buildGigsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildGigsGrid() {
    return RefreshIndicator(
      color: const Color(0xFFE63946),
      onRefresh: () => _loadGigs(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.72,
        ),
        itemCount: _gigs.length + (_isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= _gigs.length) return _buildSkeletonCard();
          return _buildGigCard(_gigs[index]);
        },
      ),
    );
  }

  Widget _buildGigCard(ProfessionalGig gig) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => GigDetailScreen(slug: gig.slug)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with Gradient Overlay
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    gig.thumbnail.isNotEmpty 
                      ? CachedNetworkImage(
                          imageUrl: gig.thumbnail, 
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, e) => Container(color: Colors.grey[300]),
                        )
                      : Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.white, size: 40)),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 9, 
                                backgroundImage: gig.sellerImage.isNotEmpty ? CachedNetworkImageProvider(gig.sellerImage) : null,
                                backgroundColor: Colors.grey[300],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  gig.sellerName,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gig.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.25),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                                  const SizedBox(width: 2),
                                  Text(
                                    gig.sellerRating, 
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'STARTING AT',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white30 : Colors.black38),
                                  ),
                                  Text(
                                    '₹${gig.price}',
                                    style: const TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOut);
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(duration: 1200.ms, color: Colors.white24);
  }

  void _showSortSheet() {
    final theme = Theme.of(context);
    final options = [
      ('newest', 'Newest First'),
      ('price_low', 'Price: Low to High'),
      ('price_high', 'Price: High to Low'),
      ('rating', 'Top Rated'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...options.map((o) => ListTile(
              title: Text(o.$2, style: TextStyle(fontWeight: _sortOrder == o.$1 ? FontWeight.bold : FontWeight.normal)),
              trailing: _sortOrder == o.$1 ? const Icon(Icons.check_circle, color: Color(0xFFE63946)) : null,
              onTap: () {
                setState(() => _sortOrder = o.$1);
                _loadGigs(refresh: true);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(child: Text('No services found matching your query.'));
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Oops! We couldn\'t connect to the Marketplace.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
              ),
              const SizedBox(height: 12),
              Text(
                'It seems the server is unreachable or your connection timed out. Please check your network and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 24),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _loadGigs(refresh: true),
                child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
    );
  }
}
