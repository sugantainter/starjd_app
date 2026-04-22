import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/creator_card.dart';
import '../widgets/category_card.dart';
import 'studio_listing_screen.dart';
import 'explore_screen.dart';
import 'blog_listing_screen.dart';
import 'service_listing_screen.dart';
import '../models/home_sections.dart';
import '../models/creator.dart';
import '../models/app_service.dart';
import '../models/blog.dart';
import '../models/app_video.dart';
import '../env/env.dart';
import '../services/sections_service.dart';
import '../services/creator_service.dart';
import '../services/blog_service.dart';
import '../services/app_service_api.dart';
import '../services/video_service.dart';
import 'campaign_listing_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/starjd_loader.dart';

import 'blog_detail_screen.dart';
import 'service_detail_screen.dart';
import 'video_listing_screen.dart';
import 'video_player_screen.dart';
import 'notifications_screen.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';

import 'professional/professional_listing_screen.dart';
import 'dynamic_page_screen.dart';
import 'plan_selection_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeSections _sections = const HomeSections();
  List<Creator> _featuredCreators = [];
  List<AppService> _services = [];
  List<BlogPost> _blogs = [];
  List<AppVideo> _videos = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (mounted && userJson != null) {
      setState(() {
        _userData = jsonDecode(userJson);
      });
    }
  }


  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        SectionsService.fetchSections(),
        CreatorService.fetchCreators(sort: 'rating', perPage: 8),
        BlogService.fetchPosts(page: 1),
        AppServiceApi.fetchServices(),
        VideoService.fetchVideos(),
      ]);
      
      if (mounted) {
        setState(() {
          _sections = futures[0] as HomeSections;
          _featuredCreators = (futures[1] as CreatorPagination).creators;
          _blogs = (futures[2] as BlogPagination).posts;
          _services = futures[3] as List<AppService>;
          _videos = futures[4] as List<AppVideo>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    if (hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExploreScreen(initialQuery: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const StarJDLoader(),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png', 
          height: 40,
          color: isDark ? Colors.white : null,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final count = notificationProvider.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                   IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      // Optionally refresh count after returning
                      Future.delayed(const Duration(seconds: 2), () => notificationProvider.refreshCount());
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE63946),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.appBarTheme.backgroundColor ?? Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // Premium Profile Header
            Builder(
              builder: (context) {
                final profile = _userData?['creator_profile'] ?? {};
                final brandProfile = _userData?['brand_profile'] ?? {};
                dynamic urlRaw = profile['avatar_url'] ?? brandProfile['logo_url'] ?? _userData?['avatar'] ?? _userData?['profile_photo_url'] ?? _userData?['avatar_url'];
                
                String? url;
                if (urlRaw != null) {
                  url = urlRaw.toString();
                  if (url.isNotEmpty && !url.startsWith('http')) {
                    url = '${Env.apiUrl}/$url'.replaceAll('//', '/').replaceFirst(':/', '://');
                  }
                }
                
                final hasImage = url != null && url.isNotEmpty;
                final email = _userData?['email'] ?? '';
                final name = _userData?['name'] ?? 'StarJD User';
                final roleName = (_userData?['primary_role']?['name'] ?? 'Member').toString().toUpperCase();

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 24,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: hasImage ? url! : '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.white10),
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email.toLowerCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Professional Menu Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_search_outlined,
                    title: 'Discover Creators',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.work_outline,
                    title: 'Hire Professionals',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalListingScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Studios',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioListingScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.campaign_outlined,
                    title: 'Campaigns',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CampaignListingScreen()));
                    },
                  ),
                   _buildDrawerItem(
                    icon: Icons.business_center_outlined,
                    title: 'Our Services',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListingScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.article_outlined,
                    title: 'Blogs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogListingScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.paid_outlined,
                    title: 'Pricing',
                    onTap: () {
                      Navigator.pop(context);
                      final role = _userData?['primary_role']?['name']?.toString().toLowerCase() ?? 'customer';
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PlanSelectionScreen(role: role)));
                    },
                  ),
                  Divider(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB), indent: 16, endIndent: 16),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Log Out',
                    color: const Color(0xFFE63946),
                    onTap: () async {
                      Navigator.pop(context);
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),

            // App version footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'StarJD v1.0.0',
                style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFFE63946),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFAF9),
                ),
                child: Column(
                  children: [
                    if (_userData != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Builder(
                            builder: (context) {
                              final profile = _userData!['creator_profile'] ?? {};
                              final brandProfile = _userData!['brand_profile'] ?? {};
                              dynamic urlRaw = profile['avatar_url'] ?? brandProfile['logo_url'] ?? _userData!['avatar'] ?? _userData!['profile_photo_url'] ?? _userData!['avatar_url'];
                              
                              String? url;
                              if (urlRaw != null) {
                                url = urlRaw.toString();
                                if (url.isNotEmpty && !url.startsWith('http')) {
                                  url = '${Env.apiUrl}/$url'.replaceAll('//', '/').replaceFirst(':/', '://');
                                }
                              }
                              
                              final hasImage = url != null && url.isNotEmpty;
                              
                              return CircleAvatar(
                                radius: 22,
                                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                backgroundImage: hasImage ? CachedNetworkImageProvider(url!) : null,
                                child: !hasImage ? Icon(Icons.person, size: 22, color: isDark ? Colors.white30 : Colors.grey.shade400) : null,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${_userData!['name']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: theme.textTheme.titleLarge?.color,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Text(
                              '${_userData!['primary_role']?['name'] ?? 'Guest'}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeroButton(
                          context,
                          label: 'Creator',
                          icon: Icons.person_outline,
                          color: Colors.green.shade600,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen())),
                        ),
                        const SizedBox(width: 6),
                        _buildHeroButton(
                          context,
                          label: 'Brand',
                          icon: Icons.campaign_outlined,
                          color: const Color(0xFFE63946),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CampaignListingScreen())),
                        ),
                        const SizedBox(width: 6),
                        _buildHeroButton(
                          context,
                          label: 'Studio',
                          icon: Icons.camera_alt_outlined,
                          color: const Color(0xFF6366F1),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioListingScreen())),
                        ),
                        const SizedBox(width: 6),
                        _buildHeroButton(
                          context,
                          label: 'Pro',
                          icon: Icons.work_outline,
                          color: Colors.amber.shade800,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalListingScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Filter
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.search, color: isDark ? Colors.white30 : Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _handleSearch(),
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Niches, categories...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white24 : Colors.grey),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: isDark ? theme.primaryColor : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          onPressed: _handleSearch,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildProfessionalHireGrid(),

              // Banner Slider
              if (_sections.banners.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildBannerSlider(),
              ],

              const SizedBox(height: 40),
              // Categories Grid
              if (_sections.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore by Category',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find creators in your niche.',
                        style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _sections.categories.length,
                        itemBuilder: (context, index) {
                          final c = _sections.categories[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryScreen(category: {
                                    'name': c.name,
                                    'image': c.image,
                                  }),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: c.image.toString().startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: c.image,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            c.image,
                                            fit: BoxFit.cover,
                                          ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  c.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textTheme.titleMedium?.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // Featured Creators horizontal list
              if (_featuredCreators.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Top Rating Creators',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color),
                              ),
                              Text(
                                'Hire top influencers',
                                style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 14),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ExploreScreen()),
                              );
                            },
                            child: Text(
                              'See All',
                              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 310,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _featuredCreators.length,
                        itemBuilder: (context, index) {
                          final creator = _featuredCreators[index];
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
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: SizedBox(
                              width: 200,
                              child: CreatorCard(creator: mapCreator),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              if (_videos.isNotEmpty) ...[
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trending Videos',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoListingScreen()));
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _videos.take(5).length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(videoId: video.videoId, title: video.title),
                            ),
                          );
                        },
                        child: Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CachedNetworkImage(
                                  imageUrl: video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFF1F2937)),
                                  errorWidget: (context, url, error) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFF1F2937)),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Text(
                                  video.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (_services.isNotEmpty) ...[
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Our Services',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListingScreen()));
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _services.take(5).length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(slug: service.slug)));
                        },
                        child: Container(
                          width: 260,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color ?? Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (service.imageUrl.isNotEmpty)
                                Expanded(
                                  child: CachedNetworkImage(
                                    imageUrl: service.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                                    errorWidget: (_, __, ___) => Container(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6)),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  service.name,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: theme.textTheme.titleMedium?.color),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (_blogs.isNotEmpty) ...[
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Blogs',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogListingScreen()));
                        },
                        child: Text(
                          'See All',
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 340,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _blogs.take(5).length,
                    itemBuilder: (context, index) {
                      final blog = _blogs[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => BlogDetailScreen(slug: blog.slug)));
                        },
                        child: Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color ?? Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (blog.imageUrl.isNotEmpty)
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: CachedNetworkImage(
                                    imageUrl: blog.imageUrl,
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
                                    if (blog.category != null)
                                      Text(
                                        blog.category!.toUpperCase(),
                                        style: TextStyle(fontSize: 10, color: theme.primaryColor, fontWeight: FontWeight.w800),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      blog.title,
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: theme.textTheme.titleMedium?.color),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                                        const SizedBox(width: 4),
                                        Text(blog.date ?? '', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
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
                ),
              const SizedBox(height: 48),
            ],
          ],
        ),
      ),
    ),
  );
}

  Future<void> _handleBannerClick(HomeBanner banner) async {
    final link = banner.link;
    if (link == null || link.isEmpty) return;

    if (link.startsWith('http')) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Internal navigation
    final route = link.toLowerCase();
    Widget? screen;

    if (route.contains('/explore')) {
      screen = const ExploreScreen();
    } else if (route.contains('/studios')) {
      screen = const StudioListingScreen();
    } else if (route.contains('/campaigns')) {
      screen = const CampaignListingScreen();
    } else if (route.contains('/professionals')) {
      screen = const ProfessionalListingScreen();
    } else if (route.contains('/blogs')) {
      screen = const BlogListingScreen();
    } else if (route.contains('/videos')) {
      screen = const VideoListingScreen();
    } else if (route.contains('/services')) {
      screen = const ServiceListingScreen();
    } else if (route.contains('/login')) {
      screen = const LoginScreen();
    }

    if (screen != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  Widget _buildBannerSlider() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_sections.banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: _sections.banners.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          final banner = _sections.banners[index];
          return GestureDetector(
            onTap: () => _handleBannerClick(banner),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : theme.primaryColor).withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: banner.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banner.title != null)
                          Text(
                            banner.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Learn More',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildDrawerItem({required IconData icon, required String title, VoidCallback? onTap, Color? color}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemColor = color ?? (isDark ? Colors.white : const Color(0xFF1A1A1A));
    
    return ListTile(
      leading: Icon(icon, color: itemColor.withOpacity(0.8), size: 22),
      title: Text(
        title,
        style: TextStyle(color: itemColor, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildHeroButton(BuildContext context, {required String label, required Color color, IconData? icon, required VoidCallback onPressed}) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalHireGrid() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final proCategories = [
      {'name': 'Graphic & Video Editors', 'image': 'assets/images/pro_categories/graphic_editor.png', 'slug': 'graphic-video-editors'},
      {'name': 'Photographers & Videographers', 'image': 'assets/images/pro_categories/photographer.png', 'slug': 'photographers-videographers'},
      {'name': 'Social Media Managers', 'image': 'assets/images/pro_categories/social_media_manager.png', 'slug': 'social-media-managers'},
      {'name': 'Script/ Content writers', 'image': 'assets/images/pro_categories/script_writer.png', 'slug': 'script-content-writers'},
      {'name': 'Marketing/ Advertising Agencies', 'image': 'assets/images/pro_categories/marketing_agency.png', 'slug': 'marketing-advertising-agencies'},
      {'name': 'Anchors', 'image': 'assets/images/pro_categories/anchor.png', 'slug': 'anchors'},
      {'name': 'Makeup Artists', 'image': 'assets/images/pro_categories/makeup_artist.png', 'slug': 'makeup-artists'},
      {'name': 'Wedding Planners', 'image': 'assets/images/pro_categories/wedding_planner.png', 'slug': 'wedding-planners'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hire Top Professionals',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color),
                  ),
                  Text(
                    'Get work done with experts',
                    style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: proCategories.length,
            itemBuilder: (context, index) {
              final cat = proCategories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalListingScreen()));
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          cat['image']!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name']!.split(' ')[0],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.titleMedium?.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


