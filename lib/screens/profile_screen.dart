import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../env/env.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'creator_packages_screen.dart';
import 'creator_gallery_screen.dart';
import 'creator_social_accounts_screen.dart';
import 'studio_owner_dashboard_screen.dart';
import 'manage_studios_screen.dart';
import 'studio_bookings_screen.dart';
import 'brand_dashboard_screen.dart';
import 'brand_campaigns_screen.dart';
import 'settings_screen.dart';
import 'professional/professional_dashboard_screen.dart';
import 'professional/gig_wizard_screen.dart';
import 'professional/manage_gigs_screen.dart';
import 'professional/professional_listing_screen.dart';
import 'collaborations_screen.dart';
import 'bank_accounts_screen.dart';
import '../widgets/starjd_loader.dart';
import '../widgets/responsive_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    await AuthService.checkAuthStatus();
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (mounted) {
      setState(() {
        if (userJson != null) _userData = jsonDecode(userJson);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    setState(() => _isLoggingOut = true);
    await AuthService.logout();
    if (mounted) {
      setState(() => _isLoggingOut = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _updateProfilePic() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    setState(() => _isUploading = true);
    final result = await AuthService.updateProfile({'avatar_file': File(image.path)});
    if (mounted) {
      setState(() => _isUploading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
        _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to update profile picture')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoggingOut || _isLoading || _isUploading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: StarJDLoader(
          message: _isUploading ? 'Uploading picture...' : (_isLoggingOut ? 'Logging out...' : 'Please wait...'),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
              const SizedBox(height: 16),
              Text(
                'Log in to view your profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Log In / Register', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final role = _userData?['role'] ?? 'customer';
    final name = _userData?['name'] ?? 'User';
    final primaryRoleData = _userData?['primary_role'];
    final roleName = primaryRoleData != null ? primaryRoleData['name'] : role.toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveWrapper(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: const Color(0xFFE63946),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
                centerTitle: true,
                elevation: 0,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      color: theme.scaffoldBackgroundColor,
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildProfileHeader(context, name, roleName),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Profile Data'),
                          _buildProfileOption(
                            context,
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () async {
                              if (_userData != null) {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditProfileScreen(userData: _userData!)),
                                );
                                if (updated == true) _loadUserData();
                              }
                            },
                          ),
                          if (role == 'creator' || role == 'brand' || role == 'studio_owner' || role == 'professional') ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle('Dashboard Overview'),
                            _buildDashboardMetrics(context, role),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Professional Info'),
                            _buildProfessionalInfoCard(context, role),
                          ],
                          if (role == 'studio_owner') ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle('Management Hub'),
                            _buildProfileOption(context, icon: Icons.dashboard_outlined, title: 'Studio Owner Dashboard', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioOwnerDashboardScreen()))),
                            _buildProfileOption(context, icon: Icons.storefront_outlined, title: 'Manage My Studios', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStudiosScreen()))),
                            _buildProfileOption(context, icon: Icons.bookmark_border, title: 'Studio Bookings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudioBookingsScreen()))),
                          ],
                          if (role == 'professional') ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle('Professional Hub'),
                            _buildProfileOption(context, icon: Icons.dashboard_outlined, title: 'Professional Dashboard', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalDashboardScreen()))),
                            _buildProfileOption(context, icon: Icons.add_circle_outline, title: 'Create New Gig', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GigWizardScreen()))),
                            _buildProfileOption(context, icon: Icons.handshake_outlined, title: 'My Gigs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageGigsScreen()))),
                          ],
                          if (role == 'creator') ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle('Creator Hub'),
                            _buildProfileOption(context, icon: Icons.share_outlined, title: 'Social Accounts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatorSocialAccountsScreen()))),
                            _buildProfileOption(context, icon: Icons.inventory_2_outlined, title: 'My Packages', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatorPackagesScreen()))),
                            _buildProfileOption(context, icon: Icons.photo_library_outlined, title: 'Portfolio Gallery', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatorGalleryScreen()))),
                          ],
                          if (role == 'creator' || role == 'brand') ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle('Collaborations'),
                            _buildProfileOption(context, icon: Icons.handshake_outlined, title: 'My Projects', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollaborationsScreen()))),
                          ],
                          if (role == 'brand') ...[
                            _buildProfileOption(context, icon: Icons.dashboard_outlined, title: 'Brand Dashboard', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandDashboardScreen()))),
                            _buildProfileOption(context, icon: Icons.campaign_outlined, title: 'My Campaigns', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandCampaignsScreen()))),
                            _buildProfileOption(context, icon: Icons.favorite_border, title: 'Shortlisted Creators', onTap: () {}),
                          ],
                          Divider(height: 32, color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                          _buildSectionTitle('Account'),
                          _buildProfileOption(context, icon: Icons.account_balance_outlined, title: 'Settlement Accounts', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BankAccountsScreen()))),
                          _buildProfileOption(context, icon: Icons.settings_outlined, title: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
                          _buildProfileOption(context, icon: Icons.logout, title: 'Log Out', color: const Color(0xFFE63946), onTap: _handleLogout),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String roleName) {
    String? avatar;
    final role = _userData?['role'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (role == 'brand') avatar = _userData?['brand_profile']?['logo_url'];
    else if (role == 'creator') avatar = _userData?['creator_profile']?['avatar_url'];
    avatar ??= _userData?['avatar_url'];
    if (avatar != null && !avatar.startsWith('http')) avatar = '${Env.apiUrl}$avatar';

    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white10 : Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6),
                backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar == null || avatar.isEmpty ? Icon(Icons.person, size: 48, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)) : null,
              ),
            ),
            Positioned(bottom: 0, right: 0, child: InkWell(onTap: _updateProfilePic, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 18)))),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
          child: Text(roleName, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoCard(BuildContext context, String role) {
    final Map<String, dynamic>? profile = role == 'creator' ? (_userData?['creator_profile'] as Map<String, dynamic>?) : (_userData?['brand_profile'] as Map<String, dynamic>?);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (profile == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          if (role == 'creator') ...[
            _buildInfoRow(context, Icons.star_outline, 'Category', profile['category'] ?? 'Not set'),
            _buildInfoRow(context, Icons.location_on_outlined, 'Location', profile['location'] ?? 'Not set'),
            _buildInfoRow(context, Icons.language_outlined, 'Language', profile['language'] ?? 'Not set'),
            _buildInfoRow(context, Icons.payments_outlined, 'Min Rate', '₹${profile['min_rate'] ?? 0}'),
          ] else if (role == 'brand') ...[
            _buildInfoRow(context, Icons.business_outlined, 'Company', profile['company_name'] ?? 'Not set'),
            _buildInfoRow(context, Icons.language_outlined, 'Website', profile['website'] ?? 'Not set'),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardMetrics(BuildContext context, String role) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard(context, (role == 'creator' || role == 'professional') ? 'Earning' : 'Spent', '₹0', Icons.account_balance_wallet_outlined, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(context, (role == 'creator' || role == 'professional') ? 'Gigs' : 'Campaigns', '0', (role == 'creator' || role == 'professional') ? Icons.handshake_outlined : Icons.campaign_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(context, 'Rating', 'N/A', Icons.star_outline, Colors.orange)),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB))),
      child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF6B7280)))]),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark ? Colors.white30 : const Color(0xFF6B7280);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [Icon(icon, size: 18, color: secondaryColor), const SizedBox(width: 12), Text('$label:', style: TextStyle(color: secondaryColor, fontSize: 14)), const SizedBox(width: 8), Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textTheme.bodyLarge?.color), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis))]),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF), letterSpacing: 1.2)),
    );
  }

  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, Color? color, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemColor = color ?? (isDark ? Colors.white70 : const Color(0xFF1A1A1A));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB))),
          child: Row(children: [Icon(icon, color: itemColor), const SizedBox(width: 16), Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: itemColor))), Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.grey.shade400)]),
        ),
      ),
    );
  }
}
