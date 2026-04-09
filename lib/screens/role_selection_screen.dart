import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'creator_onboarding_screen.dart';
import 'brand_onboarding_screen.dart';
import 'professional_onboarding_screen.dart';

class RoleSelectionScreen extends StatefulWidget {

  /// Pass true when this is a brand-new user so we call setRole API first.
  final bool isNewUser;
  const RoleSelectionScreen({super.key, this.isNewUser = false});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  final List<_RoleOption> _roles = [
    _RoleOption(
      slug: 'customer',
      title: 'Customer',
      subtitle: 'Browse creators, book studios & discover campaigns',
      icon: Icons.person_search_outlined,
      color: const Color(0xFF6366F1),
    ),
    _RoleOption(
      slug: 'creator',
      title: 'Creator',
      subtitle: 'Showcase your talent and work with top brands',
      icon: Icons.star_outline_rounded,
      color: const Color(0xFFE63946),
    ),
    _RoleOption(
      slug: 'brand',
      title: 'Brand',
      subtitle: 'Find creators and run marketing campaigns',
      icon: Icons.business_center_outlined,
      color: const Color(0xFF10B981),
    ),
    _RoleOption(
      slug: 'professional',
      title: 'Professional',
      subtitle: 'Offer your services in the marketplace',
      icon: Icons.work_outline_rounded,
      color: const Color(0xFF0EA5E9),
    ),
    _RoleOption(
      slug: 'studio_owner',
      title: 'Studio Owner',
      subtitle: 'List your studio and manage bookings',
      icon: Icons.camera_indoor_outlined,
      color: const Color(0xFFF59E0B),
    ),

  ];

  Future<void> _handleContinue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Always call setRole — works for both new and existing users
    try {
      await AuthService.setRole(_selectedRole!);
    } catch (_) {}

    // Mark onboarding as complete in local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('role_selected', true);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (_selectedRole == 'creator') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CreatorOnboardingScreen()),
      );
    } else if (_selectedRole == 'brand') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BrandOnboardingScreen()),
      );
    } else if (_selectedRole == 'professional') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfessionalOnboardingScreen()),
      );
    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/images/logo.png', height: 40),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose your role',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select how you want to use StarJD.\nYou can change this later in settings.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Role cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: _roles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  final isSelected = _selectedRole == role.slug;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRole = role.slug),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? role.color.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? role.color : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: role.color.withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: role.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(role.icon, color: role.color, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? role.color
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role.subtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? role.color : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                              color: isSelected ? role.color : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE63946),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

class _RoleOption {
  final String slug;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _RoleOption({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
