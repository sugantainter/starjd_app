import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'plan_selection_screen.dart';

class BrandOnboardingScreen extends StatefulWidget {
  const BrandOnboardingScreen({super.key});

  @override
  State<BrandOnboardingScreen> createState() => _BrandOnboardingScreenState();
}

class _BrandOnboardingScreenState extends State<BrandOnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _isSubmitting = true);
      
      final Map<String, dynamic> data = {
        'company_name': _companyNameController.text.trim(),
        'website': _websiteController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      final res = await AuthService.updateBrandProfile(data);
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['success']) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PlanSelectionScreen(role: 'brand')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to update brand profile')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Brand Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(2, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentStep 
                          ? const Color(0xFFE63946) 
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Expanded(
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentStep = idx),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _stepBasicInfo(),
                    _stepBio(),
                  ],
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.white70,
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE63946)),
                    ),
                  ),
              ],
            ),
          ),
          
          _footerControls(),
        ],
      ),
    );
  }

  Widget _stepBasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Company Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Provide basic information about your brand.', style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 32),
          
          _fieldLabel('Company Name'),
          _textField(_companyNameController, 'e.g. Acme Corp'),
          
          const SizedBox(height: 24),
          _fieldLabel('Website URL'),
          _textField(_websiteController, 'e.g. https://www.acme.com', keyboardType: TextInputType.url),
        ],
      ),
    );
  }

  Widget _stepBio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Brand Story', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Describe your brand mission and what you look for in creators.', style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 32),
          
          _fieldLabel('Bio / Mission'),
          _textField(_bioController, 'Tell us about your brand...', maxLines: 6),
        ],
      ),
    );
  }

  Widget _footerControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: const Text('Back', style: TextStyle(color: Color(0xFF1A1A1A))),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(_currentStep == 1 ? 'Finish' : 'Continue', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
