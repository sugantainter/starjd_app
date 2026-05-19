import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'faq_screen.dart';
import 'contact_us_screen.dart';
import 'help_desk_screen.dart';
import 'dynamic_page_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _appVersion = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      final appDir = await getApplicationSupportDirectory();
      if (appDir.existsSync()) {
        // Optional: Be careful what you delete here
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear cache: $e')),
        );
      }
    }
  }

  Future<void> _rateApp() async {
    final Uri url = Uri.parse(
      Platform.isAndroid
          ? 'https://play.google.com/store/apps/details?id=com.starjd.app' // Replace with your actual ID
          : 'https://apps.apple.com/app/id6446213073', // Replace with your actual ID
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch store')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('HELP & SUPPORT'),
            _buildSettingOption(
              icon: Icons.help_outline,
              title: 'Help Desk',
              subtitle: 'Raise a complaint or register issues',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpDeskScreen())),
            ),
            _buildSettingOption(
              icon: Icons.contact_support_outlined,
              title: 'Contact Us',
              subtitle: 'Reach out to our team',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen())),
            ),
            _buildSettingOption(
              icon: Icons.question_answer_outlined,
              title: 'FAQs',
              subtitle: 'Frequently asked questions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen())),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('LEGAL'),
            _buildSettingOption(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms of service',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DynamicPageScreen(title: 'Terms & Conditions', slug: 'terms'))),

            ),
            _buildSettingOption(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DynamicPageScreen(title: 'Privacy Policy', slug: 'privacy'))),

            ),
            _buildSettingOption(
              icon: Icons.cookie_outlined,
              title: 'Cookie Policy',
              subtitle: 'Our use of cookies',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DynamicPageScreen(title: 'Cookie Policy', slug: 'cookie-policy'))),
            ),


            const SizedBox(height: 24),
            _buildSectionTitle('APPEARANCE'),
            _buildSettingOption(
              icon: Icons.notifications_none_outlined,
              title: 'Push Notifications',
              subtitle: 'Manage your alert preferences',
              trailing: Switch.adaptive(
                value: _notificationsEnabled,
                activeColor: const Color(0xFFE63946),
                onChanged: (value) => setState(() => _notificationsEnabled = value),
              ),
            ),
            _buildSettingOption(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Change app appearance',
              trailing: Switch.adaptive(
                value: isDark,
                activeColor: const Color(0xFFE63946),
                onChanged: (value) => themeProvider.toggleTheme(value),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('ACCOUNT'),
            _buildSettingOption(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account security',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            _buildSettingOption(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: const Color(0xFFE63946),
              onTap: () => _showDeleteAccountDialog(context),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('SYSTEM'),
            _buildSettingOption(
              icon: Icons.cached_outlined,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: _clearCache,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('ABOUT APP'),
            _buildSettingOption(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: _appVersion,
              trailing: const SizedBox.shrink(),
              onTap: null,
            ),
            _buildSettingOption(
              icon: Icons.star_border,
              title: 'Rate App',
              subtitle: 'Share your feedback on the store',
              onTap: _rateApp,
            ),

            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.stars, color: Color(0xFFE63946), size: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 StarJD. Made with ❤️ for Creators.',
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white24 : const Color(0xFF9CA3AF),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? color,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? Colors.white70 : const Color(0xFF1A1A1A));
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white30 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        content: Text(
          'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _handleDeleteAccount(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    final result = await AuthService.deleteAccount();
    
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Pop loading dialog
      
      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to delete account')),
        );
      }
    }
  }
}

