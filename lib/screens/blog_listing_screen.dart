import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';
import 'blog_detail_screen.dart';

class BlogListingScreen extends StatefulWidget {
  const BlogListingScreen({super.key});

  @override
  State<BlogListingScreen> createState() => _BlogListingScreenState();
}

class _BlogListingScreenState extends State<BlogListingScreen> {
  final ScrollController _scrollController = ScrollController();
  List<BlogPost> _posts = [];
  List<BlogCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final futures = await Future.wait([
        BlogService.fetchCategories(),
        BlogService.fetchPosts(category: _selectedCategory, page: _currentPage),
      ]);
      if (mounted) {
        setState(() {
          _categories = futures[0] as List<BlogCategory>;
          final paginator = futures[1] as BlogPagination;
          _posts = paginator.posts;
          _hasMore = paginator.currentPage < paginator.lastPage;
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
    setState(() => _isLoadingMore = true);
    _currentPage++;
    try {
      final paginator = await BlogService.fetchPosts(category: _selectedCategory, page: _currentPage);
      if (mounted) {
        setState(() {
          _posts.addAll(paginator.posts);
          _hasMore = paginator.currentPage < paginator.lastPage;
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Blogs', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: _categories.isNotEmpty ? _buildCategoryTabs() : null,
      ),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildCategoryTabs() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _catChip('All', null),
            ..._categories.map((c) => _catChip(c.label, c.slug)),
          ],
        ),
      ),
    );
  }

  Widget _catChip(String label, String? slug) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isSelected = _selectedCategory == slug;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = slug;
            _posts.clear();
          });
          _loadData(refresh: true);
        },
        selectedColor: theme.primaryColor.withOpacity(0.1),
        backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? theme.primaryColor : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? theme.primaryColor : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
    }
    if (_posts.isEmpty) {
      return Center(child: Text('No posts found.', style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(refresh: true),
      color: const Color(0xFFE63946),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFFE63946)),
              ),
            );
          }
          final post = _posts[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BlogDetailScreen(slug: post.slug)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.imageUrl.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                        errorWidget: (_, __, ___) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(post.category!,
                                style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : const Color(0xFF374151), fontWeight: FontWeight.bold)),
                          ),
                        Text(
                          post.title,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (post.excerpt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            post.excerpt!,
                            style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(post.date ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
