import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'role_selection_screen.dart';
import 'creator_onboarding_screen.dart';
import 'brand_onboarding_screen.dart';
import '../services/analytics_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() { _isLoading = true; });

    final res = await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (res['success']) {
        AnalyticsService.logEvent(
          name: 'registration',
          parameters: {'method': 'email'},
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleSelectionScreen(isNewUser: true),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'])));
      }
    }
  }

  Future<void> _handleSocialSignup(String provider) async {
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
          if (mounted) setState(() { _isLoading = false; });
          return; 
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        token = googleAuth.accessToken; 
        
      } else if (provider == 'facebook') {
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['public_profile', 'email']
        );
        
        if (result.status == LoginStatus.success) {
          token = result.accessToken?.tokenString;
        } else {
          if (mounted) setState(() { _isLoading = false; });
          return; 
        }
      }
      
      if (token != null) {
        final res = await AuthService.socialLogin(provider, token);
        
        if (mounted) {
          setState(() { _isLoading = false; });
          if (res['success']) {
            final user = res['data']['user'];
            final isNew = res['data']['is_new_user'] == true;
            final primaryRole = user['primary_role']?['slug'];
            final creatorProfile = user['creator_profile'];
            final brandProfile = user['brand_profile'];

            AnalyticsService.logEvent(
              name: 'registration',
              parameters: {'method': provider},
            );
            
            // 1. Force Role Selection if completely new or no role is assigned
            if (isNew || primaryRole == null || primaryRole.isEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen(isNewUser: true)),
              );
            } else {
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
              } else {
                // 3. Fully authenticated and onboarded!
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainLayout()),
                );
              }
            }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create an account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join thousands of creators and brands today.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white30 : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 48),

              const SizedBox(height: 8),
              
              // Name Field
              Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
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
                  hintText: 'Create a password',
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
              
              const SizedBox(height: 32),
              
              // Sign Up Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
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
                    : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 32),
              
              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB), thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or sign up with',
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
                      onPressed: () => _handleSocialSignup('google'),
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
                      onPressed: () => _handleSocialSignup('facebook'),
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
              
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(color: isDark ? Colors.white24 : const Color(0xFF6B7280), fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Log in',
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
    );
  }
}
