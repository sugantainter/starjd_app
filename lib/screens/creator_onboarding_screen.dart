import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/creator_service.dart';
import '../services/ai_suggest_service.dart';
import '../widgets/ai_suggest_button.dart';
import 'plan_selection_screen.dart';

class CreatorOnboardingScreen extends StatefulWidget {
  const CreatorOnboardingScreen({super.key});

  @override
  State<CreatorOnboardingScreen> createState() => _CreatorOnboardingScreenState();
}

class _CreatorOnboardingScreenState extends State<CreatorOnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isAiLoading = false;

  // Step 1: Basic Bio & Tagline
  final _taglineController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedCategory;
  String? _selectedGender;

  // Step 2: Location & Language
  final _locationController = TextEditingController();
  String? _selectedLanguage;

  // Step 3: Rates
  final _minRateController = TextEditingController();

  List<String> _categories = [];
  List<String> _genders = [];
  List<String> _languages = [];
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    setState(() => _isLoadingOptions = true);
    try {
      final filters = await CreatorService.fetchFilters();
      if (mounted) {
        setState(() {
          _categories = filters.categories;
          _genders = filters.genders;
          _languages = filters.languages;
          _isLoadingOptions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  @override
  void dispose() {
    _taglineController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _minRateController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _isSubmitting = true);
      
      final Map<String, dynamic> data = {
        'tagline': _taglineController.text.trim(),
        'category': _selectedCategory,
        'gender': _selectedGender?.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_'),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'language': _selectedLanguage,
        'min_rate': double.tryParse(_minRateController.text) ?? 0,
        'is_public': true,
      };

      final res = await AuthService.updateCreatorProfile(data);
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['success']) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PlanSelectionScreen(role: 'creator')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to update profile')),
          );
        }
      }
    }
  }

  Future<void> _suggestAiBio() async {
    if (_taglineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tagline first to help generate a bio.')),
      );
      return;
    }

    setState(() => _isAiLoading = true);
    final res = await AISuggestService.suggestGeneric('creator_bio', {
      'tagline': _taglineController.text,
      'category': _selectedCategory ?? 'Entertainer',
    });
    
    if (mounted) {
      setState(() => _isAiLoading = false);
      if (res['success']) {
        setState(() => _bioController.text = res['suggestion']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to get suggestion')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
              children: List.generate(3, (index) {
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
                    _stepLocationLang(),
                    _stepRates(),
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
          const Text('Tell us about yourself', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('These details help brands find you.', style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 32),
          
          _fieldLabel('Tagline'),
          _textField(_taglineController, 'e.g. Travel & Lifestyle Creator'),
          
          const SizedBox(height: 20),
          _fieldLabel('Category'),
          _isLoadingOptions 
            ? const LinearProgressIndicator(color: Color(0xFFE63946))
            : _dropdownField(
                value: _selectedCategory,
                hint: 'Select niche',
                items: _categories,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
          
          const SizedBox(height: 20),
          _fieldLabel('Gender'),
          _isLoadingOptions 
            ? const LinearProgressIndicator(color: Color(0xFFE63946))
            : _dropdownField(
                value: _selectedGender,
                hint: 'Select gender',
                items: _genders,
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
          
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fieldLabel('Bio'),
              AiSuggestButton(
                onPressed: _suggestAiBio,
                isLoading: _isAiLoading,
                isSmall: true,
              ),
            ],
          ),
          _textField(_bioController, 'Write a short bio...', maxLines: 4),
        ],
      ),
    );
  }

  Widget _stepLocationLang() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where are you based?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          
          _fieldLabel('Location'),
          _textField(_locationController, 'e.g. Mumbai, Maharashtra'),
          
          const SizedBox(height: 24),
          _fieldLabel('Primary Language'),
          _isLoadingOptions 
            ? const LinearProgressIndicator(color: Color(0xFFE63946))
            : _dropdownField(
                value: _selectedLanguage,
                hint: 'Select language',
                items: _languages,
                onChanged: (v) => setState(() => _selectedLanguage = v),
              ),
        ],
      ),
    );
  }

  Widget _stepRates() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Setting your rates', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Provide an estimate for your services.', style: TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 32),
          
          _fieldLabel('Minimum Collaboration Rate (₹)'),
          _textField(_minRateController, 'e.g. 5000', keyboardType: TextInputType.number),
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
              child: Text(_currentStep == 2 ? 'Finish' : 'Continue', 
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

  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE63946)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      hint: Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
      isExpanded: true,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
      dropdownColor: Colors.white,
    );
  }
}
