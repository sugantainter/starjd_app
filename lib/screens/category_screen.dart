import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/creator.dart';
import '../services/creator_service.dart';
import '../widgets/creator_card.dart';
import '../widgets/starjd_loader.dart';

class CategoryScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Creator> _creators = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCreators();
  }

  Future<void> _loadCreators() async {
    try {
      final res = await CreatorService.fetchCreators(
        category: widget.category['name'],
        perPage: 20,
      );
      if (mounted) {
        setState(() {
          _creators = res.creators;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category['name'],
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.category['image'].toString().startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: widget.category['image'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                          errorWidget: (context, url, error) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                        )
                      : Image.asset(
                          widget.category['image'],
                          fit: BoxFit.cover,
                        ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLoading 
                            ? 'Loading...' 
                            : '${_creators.length} creators found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white30 : const Color(0xFF6B7280)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, size: 16, color: isDark ? Colors.white70 : const Color(0xFF1A1A1A)),
                            const SizedBox(width: 4),
                            Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF1A1A1A))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: StarJDLoader(),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(child: Text(_error!, style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
            )
          else if (_creators.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text('No creators found in this category', style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final creator = _creators[index];
                    // Convert Creator to Map to keep compatibility with old CreatorCard
                    final mapCreator = {
                      'slug': creator.slug,
                      'name': creator.displayName,
                      'tagline': creator.tagline ?? '',
                      'price': creator.displayPrice.replaceAll('₹', ''),
                      'location': creator.location ?? '',
                      'image': creator.imageUrl,
                      'rating': creator.averageRating ?? 0.0,
                      'topCreator': creator.isFeatured,
                      'ugc': creator.packages.any((p) => p.name.toLowerCase().contains('ugc')),
                      'followers': creator.formattedFollowers,
                      'category': creator.category,
                    };
                    return CreatorCard(creator: mapCreator);
                  },
                  childCount: _creators.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}
