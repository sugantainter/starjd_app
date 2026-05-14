import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/studio_listing_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/creator_onboarding_screen.dart';
import 'screens/brand_onboarding_screen.dart';
import 'screens/plan_selection_screen.dart';
import 'screens/professional/professional_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/chat_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
    await AnalyticsService.initialize();
    await AnalyticsService.logActivateApp();
  } catch (e) {
    // removed debugPrint
  }

  // Initialize AuthService and others if needed
  await AuthService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const StarJDApp(),
    ),
  );
}

class StarJDApp extends StatelessWidget {
  const StarJDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'StarJD',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          builder: (context, child) {
            return PopScope(
              canPop: false,
              child: UpgradeAlert(
                showIgnore: false,
                showLater: false,
                upgrader: Upgrader(
                  durationUntilAlertAgain: const Duration(seconds: 0),
                  canDismissDialog: false,
                ),
                child: child!,
              ),
            );
          },
          home: const AuthCheckScreen(),
        );
      }
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final bool isLoggedIn = await AuthService.checkAuthStatus();
    if (!mounted) return;

    if (isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      
      try {
        final String? userStr = prefs.getString('user');
        if (userStr == null) throw Exception('No user');
        
        final user = jsonDecode(userStr);
        final primaryRole = user['primary_role']?['slug'];
        final creatorProfile = user['creator_profile'];
        final brandProfile = user['brand_profile'];

        if (!mounted) return;

        if (primaryRole == null || primaryRole.isEmpty) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
          return;
        }

        bool needsOnboarding = false;
        if (primaryRole == 'creator') {
          if (creatorProfile == null || creatorProfile['tagline'] == null || creatorProfile['tagline'].toString().isEmpty) {
            needsOnboarding = true;
          }
        } else if (primaryRole == 'brand') {
          if (brandProfile == null || brandProfile['company_name'] == null || brandProfile['company_name'].toString().isEmpty) {
            needsOnboarding = true;
          }
        }

        if (needsOnboarding) {
          if (primaryRole == 'creator') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreatorOnboardingScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BrandOnboardingScreen()));
          }
          return;
        }

        bool hasPaid = user['has_paid_access'] == true;
        if (!hasPaid && (primaryRole == 'creator' || primaryRole == 'brand')) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlanSelectionScreen(role: primaryRole)));
            return;
        }

        await prefs.setBool('role_selected', true);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
          ),
        ),
        child: Stack(
          children: [
            // Subtle animated background pulse
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.01),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                        strokeWidth: 3,
                        backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Version text at bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'STARJD',
                  style: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black26,
                    letterSpacing: 8,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
    NotificationService.initialize();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final user = jsonDecode(userJson);
      setState(() {
        _role = user['primary_role']?['slug'] ?? user['role'];
      });
    }
  }

  List<Widget> get _pages {
    return [
      const HomeScreen(),
      const ExploreScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioListingScreen()));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildNavItem(Icons.search_outlined, Icons.search, 'Explore', 1),
            // Studio Label placed beneath the notch gap
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'Studio',
                style: TextStyle(color: isDark ? Colors.white30 : const Color(0xFF6B7280), fontSize: 12),
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, chat, _) => _buildNavItem(
                Icons.chat_bubble_outline, 
                Icons.chat_bubble, 
                'Messages', 
                2,
                badgeCount: chat.unreadMessageCount,
              ),
            ),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData unselectedIcon, IconData selectedIcon, String label, int index, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Theme.of(context).primaryColor : const Color(0xFF6B7280);
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(isSelected ? selectedIcon : unselectedIcon, color: color),
              if (badgeCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

