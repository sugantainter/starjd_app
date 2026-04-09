import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'role_selection_screen.dart';
import 'creator_onboarding_screen.dart';
import 'brand_onboarding_screen.dart';
import '../services/analytics_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Navigate based on whether user has completed role selection & onboarding.
  /// This is the SINGLE routing gate after any successful auth.
  Future<void> _navigateAfterAuth(Map<String, dynamic> user, {bool isNewUser = false}) async {
    if (!mounted) return;

    final primaryRole = user['primary_role']?['slug'];
    final creatorProfile = user['creator_profile'];
    final brandProfile = user['brand_profile'];

    // 1. Force Role Selection if completely new or no role is assigned
    if (isNewUser || primaryRole == null || primaryRole.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen(isNewUser: true)),
      );
      return;
    }

    // 2. Check if onboarding basic details are complete
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

    // 3. Fully authenticated and onboarded! Update local prefs and go to Home.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('role_selected', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() { _isLoading = true; });

    final res = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (res['success']) {
        final user = res['data']['user'];
        final isNewUser = res['data']['is_new_user'] == true;
        
        AnalyticsService.logEvent(
          name: 'login',
          parameters: {'method': 'email'},
        );
        AnalyticsService.setUserID(user['id'].toString());
        
        _navigateAfterAuth(user, isNewUser: isNewUser);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    try {
      setState(() { _isLoading = true; });
      String? token;
      
      if (provider == 'google') {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: '962027557216-333bnbm5cr28qtjn3i17fmoonuen0qru.apps.googleusercontent.com',
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          setState(() { _isLoading = false; });
          return; // The user canceled the sign-in
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        token = googleAuth.accessToken; 
        
      } else if (provider == 'facebook') {
        // Ensure any previous session is logged out first to avoid stale token issues
        await FacebookAuth.instance.logOut();
        
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['public_profile', 'email'],
        );
        
        if (result.status == LoginStatus.success) {
          token = result.accessToken?.token;
        } else if (result.status == LoginStatus.cancelled) {
          setState(() { _isLoading = false; });
          return; // User cancelled — no error needed
        } else {
          setState(() { _isLoading = false; });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Facebook login failed: ${result.message ?? 'Unknown error'}')),
            );
          }
          return;
        }
      }
      
      if (token != null) {
        final res = await AuthService.socialLogin(provider, token);
        
        if (mounted) {
          setState(() { _isLoading = false; });
          if (res['success']) {
            final user = res['data']['user'];
            final isNewUser = res['data']['is_new_user'] == true;
            
            AnalyticsService.logEvent(
              name: 'login',
              parameters: {'method': provider},
            );
            AnalyticsService.setUserID(user['id'].toString());
            
            _navigateAfterAuth(user, isNewUser: isNewUser);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
          }
        }
      } else {
         if (mounted) {
           setState(() { _isLoading = false; });
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to retrieve token from provider')));
         }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 60,
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to connect with top brands and creators',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white30 : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Email Field
                Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Password Field
                Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.white30 : const Color(0xFF6B7280),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 32),
                
                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB), thickness: 1)),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleSocialLogin('google'),
                        icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                        label: Text(
                          'Google',
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleSocialLogin('facebook'),
                        icon: const Icon(Icons.facebook, color: Colors.blue),
                        label: Text(
                          'Facebook',
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF6B7280), fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
