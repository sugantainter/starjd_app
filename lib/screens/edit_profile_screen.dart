import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/creator_service.dart';
import '../services/ai_suggest_service.dart';
import '../widgets/ai_suggest_button.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isSubmitting = false;
  late String _role;
  File? _imageFile;
  final _picker = ImagePicker();

  // Common fields (mostly name from user table)
  final _nameController = TextEditingController();

  // Creator specific
  final _taglineController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _minRateController = TextEditingController();
  final _slugController = TextEditingController();
  String? _selectedCategory;
  String? _selectedGender;
  String? _selectedLanguage;

  // Brand specific
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  final _hqLocationController = TextEditingController();
  final _websiteController = TextEditingController();

  List<String> _categories = [];
  List<String> _genders = [];
  List<String> _languages = [];
  
  // Location
  List<dynamic> _states = [];
  List<dynamic> _cities = [];
  int? _selectedStateId;
  int? _selectedCityId;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  bool _isLoadingOptions = false;

  bool _isPublic = true;
  final _engagementRateController = TextEditingController();
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    _role = widget.userData['role'] ?? 'customer';
    _nameController.text = widget.userData['name'] ?? '';

    if (_role == 'creator') {
      final profile = widget.userData['creator_profile'] ?? {};
      _taglineController.text = profile['tagline'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _locationController.text = profile['location'] ?? '';
      _minRateController.text = (profile['min_rate'] ?? '').toString();
      _engagementRateController.text = (profile['engagement_rate'] ?? '').toString();
      _slugController.text = profile['slug'] ?? '';
      _isPublic = profile['is_public'] ?? true;
      
      // Match category
      if (profile['category'] != null) {
        if (_categories.contains(profile['category'])) {
          _selectedCategory = profile['category'];
        }
      }
      
      // Match gender
      if (profile['gender'] != null) {
        final genderMap = {
          'male': 'Male',
          'female': 'Female',
          'non_binary': 'Non-binary',
          'prefer_not_to_say': 'Prefer not to say'
        };
        _selectedGender = genderMap[profile['gender']];
      }
      
      // Match language
      if (profile['language'] != null) {
        if (_languages.contains(profile['language'])) {
          _selectedLanguage = profile['language'];
        }
      }
    } else if (_role == 'brand') {
      final profile = widget.userData['brand_profile'] ?? {};
      _companyNameController.text = profile['company_name'] ?? '';
      _industryController.text = profile['industry'] ?? '';
      _hqLocationController.text = profile['hq_location'] ?? '';
      _websiteController.text = profile['website'] ?? '';
      _bioController.text = profile['bio'] ?? '';
    }

    if (_role == 'creator') {
      _fetchOptions();
    }
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Current user's location IDs
    _selectedStateId = widget.userData['state_id'];
    _selectedCityId = widget.userData['city_id'];
    
    await _fetchStates();
    if (_selectedStateId != null) {
      await _fetchCities(_selectedStateId!);
    }
  }

  Future<void> _fetchStates() async {
    setState(() => _isLoadingStates = true);
    final states = await AuthService.getStates();
    if (mounted) {
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
    }
  }

  Future<void> _fetchCities(int stateId) async {
    setState(() => _isLoadingCities = true);
    final cities = await AuthService.getCities(stateId);
    if (mounted) {
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    }
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
          
          // Re-validate selection after fetch
          final profile = widget.userData['creator_profile'] ?? {};
          final currentCategory = profile['category'];
          if (currentCategory != null) {
             // If currentCategory is a map (legacy/edge case), try to extract name
             String categoryName = currentCategory is Map ? (currentCategory['name'] ?? currentCategory.toString()) : currentCategory.toString();
             if (_categories.contains(categoryName)) {
               _selectedCategory = categoryName;
             }
          }

          if (profile['gender'] != null) {
             final lowerGenders = _genders.map((e) => e.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')).toList();
             final idx = lowerGenders.indexOf(profile['gender']);
             if (idx != -1) _selectedGender = _genders[idx];
          }
          if (profile['language'] != null && _languages.contains(profile['language'])) {
            _selectedLanguage = profile['language'];
          }
          
          _isLoadingOptions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _minRateController.dispose();
    _engagementRateController.dispose();
    _slugController.dispose();
    _companyNameController.dispose();
    _industryController.dispose();
    _hqLocationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);
    
    Map<String, dynamic> res;
    if (_role == 'creator') {
      final Map<String, dynamic> data = {
        'tagline': _taglineController.text.trim(),
        'category': _selectedCategory,
        'gender': _selectedGender?.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_'),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'language': _selectedLanguage,
        'min_rate': double.tryParse(_minRateController.text) ?? 0,
        'engagement_rate': double.tryParse(_engagementRateController.text) ?? 0,
        'is_public': _isPublic,
        'slug': _slugController.text.trim(),
        'state_id': _selectedStateId,
        'city_id': _selectedCityId,
      };
      if (_imageFile != null) {
        data['avatar_file'] = _imageFile;
      }
      res = await AuthService.updateCreatorProfile(data);
    } else if (_role == 'brand') {
      final Map<String, dynamic> data = {
        'company_name': _companyNameController.text.trim(),
        'industry': _industryController.text.trim(),
        'hq_location': _hqLocationController.text.trim(),
        'website': _websiteController.text.trim(),
        'bio': _bioController.text.trim(),
        'state_id': _selectedStateId,
        'city_id': _selectedCityId,
      };
      if (_imageFile != null) {
        data['logo_file'] = _imageFile;
      }
      res = await AuthService.updateBrandProfile(data);
    } else {
      // Basic customer update not implemented in AuthService yet, but could be added
      res = {'success': false, 'message': 'Role not supported for editing yet'};
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to update profile')),
        );
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
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          if (!_isSubmitting)
            TextButton(
              onPressed: _save,
              child: const Text('SAVE', style: TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isSubmitting 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(child: _buildImageSelector(context)),
                   const SizedBox(height: 32),
                  _buildSectionTitle('Basic Information'),
                  _buildTextField(context, 'Full Name', _nameController, enabled: false), // Name usually not editable here or needs separate route
                  const SizedBox(height: 24),
                  
                  if (_role == 'creator') ..._buildCreatorFields(context),
                  if (_role == 'brand') ..._buildBrandFields(context),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildCreatorFields(BuildContext context) {
    return [
      _buildSectionTitle('Professional Bio'),
      _buildTextField(
        context, 
        'Tagline', 
        _taglineController, 
        hint: 'e.g. Fashion Enthusiast & Content Creator',
        suffixIcon: IconButton(
          icon: const Icon(Icons.auto_awesome, color: Color(0xFFE63946)),
          onPressed: () => _suggestAiTagline(),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('Bio'),
          AiSuggestButton(
            onPressed: () => _suggestAiBio(),
            isLoading: _isAiLoading,
            isSmall: true,
          ),
        ],
      ),
      _buildTextField(context, '', _bioController, hint: 'Tell brands about yourself...', maxLines: 4),
      const SizedBox(height: 24),
      
      _buildSectionTitle('Categories & Details'),
      _buildTextField(context, 'Profile URL Slug', _slugController, hint: 'e.g. johndoe'),
      const SizedBox(height: 16),
      if (_isLoadingOptions)
        const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE63946))))
      else ...[
        _buildDropdown(context, 'Category', _categories, _selectedCategory, (v) => setState(() => _selectedCategory = v)),
        const SizedBox(height: 16),
        _buildDropdown(context, 'Gender', _genders, _selectedGender, (v) => setState(() => _selectedGender = v)),
        const SizedBox(height: 16),
        _buildDropdown(context, 'Primary Language', _languages, _selectedLanguage, (v) => setState(() => _selectedLanguage = v)),
      ],
      const SizedBox(height: 24),
      
      _buildSectionTitle('Location & Rates'),
      _buildDropdownWithId(
        context, 
        'State', 
        _states, 
        _selectedStateId, 
        (id) {
          setState(() {
            _selectedStateId = id;
            _selectedCityId = null;
            _cities = [];
          });
          if (id != null) _fetchCities(id);
        },
        isLoading: _isLoadingStates,
      ),
      const SizedBox(height: 16),
      _buildDropdownWithId(
        context, 
        'City', 
        _cities, 
        _selectedCityId, 
        (id) => setState(() => _selectedCityId = id),
        isLoading: _isLoadingCities,
        hint: _selectedStateId == null ? 'Select State first' : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _buildTextField(context, 'Minimum Rate (₹)', _minRateController, hint: 'e.g. 5000', keyboardType: TextInputType.number)),
          const SizedBox(width: 16),
          Expanded(child: _buildTextField(context, 'Engagement Rate (%)', _engagementRateController, hint: 'e.g. 5.5', keyboardType: TextInputType.number)),
        ],
      ),
      const SizedBox(height: 24),
      
      _buildSectionTitle('Visibility'),
      SwitchListTile(
        title: Text('Public Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
        subtitle: Text('Make your profile visible to brands', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        value: _isPublic,
        activeThumbColor: const Color(0xFFE63946),
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _isPublic = v),
      ),
    ];
  }

  List<Widget> _buildBrandFields(BuildContext context) {
    return [
      _buildSectionTitle('Company Details'),
      _buildTextField(context, 'Company Name', _companyNameController, hint: 'e.g. Acme Corp'),
      const SizedBox(height: 16),
      _buildTextField(context, 'Industry', _industryController, hint: 'e.g. Technology, Fashion'),
      const SizedBox(height: 16),
      _buildDropdownWithId(
        context, 
        'State', 
        _states, 
        _selectedStateId, 
        (id) {
          setState(() {
            _selectedStateId = id;
            _selectedCityId = null;
            _cities = [];
          });
          if (id != null) _fetchCities(id);
        },
        isLoading: _isLoadingStates,
      ),
      const SizedBox(height: 16),
      _buildDropdownWithId(
        context, 
        'City', 
        _cities, 
        _selectedCityId, 
        (id) => setState(() => _selectedCityId = id),
        isLoading: _isLoadingCities,
        hint: _selectedStateId == null ? 'Select State first' : null,
      ),
      const SizedBox(height: 16),
      _buildTextField(context, 'Website URL', _websiteController, hint: 'https://example.com', keyboardType: TextInputType.url),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSectionTitle('About Company'),
          AiSuggestButton(
            onPressed: () => _suggestAiBio(),
            isLoading: _isAiLoading,
            isSmall: true,
          ),
        ],
      ),
      _buildTextField(context, '', _bioController, hint: 'Tell creators about your brand...', maxLines: 4),
    ];
  }

  Widget _buildImageSelector(BuildContext context) {
    String? currentUrl;
    if (_role == 'creator') {
      currentUrl = widget.userData['creator_profile']?['avatar_url'];
    } else if (_role == 'brand') {
      currentUrl = widget.userData['brand_profile']?['logo_url'];
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? Colors.white10 : Colors.white, width: 4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            image: _imageFile != null 
              ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
              : (currentUrl != null 
                  ? DecorationImage(image: NetworkImage(currentUrl), fit: BoxFit.cover)
                  : null),
          ),
          child: _imageFile == null && currentUrl == null
            ? Icon(Icons.person, size: 50, color: isDark ? Colors.white24 : Colors.grey.shade400)
            : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFE63946), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9CA3AF),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, {String? hint, int maxLines = 1, bool enabled = true, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.titleMedium?.color)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
            filled: true,
            fillColor: enabled 
                ? (isDark ? Colors.white.withOpacity(0.05) : Colors.white)
                : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: Color(0xFFE63946), width: 2)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context, String label, List<String> items, String? value, void Function(String?) onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String? sanitizedValue = (value != null && items.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.titleMedium?.color)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: sanitizedValue,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 22, color: Colors.grey),
          dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
          hint: Text(
            items.isEmpty ? 'Loading $label...' : 'Select $label',
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 15),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: Color(0xFFE63946), width: 1.5)
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontWeight: FontWeight.w400)),
            );
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownWithId(BuildContext context, String label, List<dynamic> items, int? value, void Function(int?) onChanged, {bool isLoading = false, String? hint}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Check if current value exists in items
    bool valueExists = value != null && items.any((i) => i['id'] == value);
    int? sanitizedValue = valueExists ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.titleMedium?.color)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: sanitizedValue,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 22, color: Colors.grey),
          dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
          hint: Text(
            isLoading ? 'Loading...' : (hint ?? 'Select $label'),
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 15),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: Color(0xFFE63946), width: 1.5)
            ),
          ),
          items: items.map((dynamic item) {
            return DropdownMenuItem<int>(
              value: item['id'],
              child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w400)),
            );
          }).toList(),
          onChanged: isLoading ? null : onChanged,
        ),
      ],
    );
  }

  // AI Logic
  Future<void> _suggestAiTagline() async {
    setState(() => _isAiLoading = true);
    final res = await AISuggestService.suggestGeneric('creator_tagline', {
      'name': _nameController.text,
      'category': _selectedCategory ?? 'Entertainer',
    });
    setState(() => _isAiLoading = false);
    if (res['success']) {
      setState(() => _taglineController.text = res['suggestion']);
    }
  }

  Future<void> _suggestAiBio() async {
    setState(() => _isAiLoading = true);
    final Map<String, dynamic> contextData = {};
    if (_role == 'creator') {
      contextData['name'] = _nameController.text;
      contextData['tagline'] = _taglineController.text;
      contextData['category'] = _selectedCategory ?? 'Entertainer';
    } else if (_role == 'brand') {
      contextData['company_name'] = _companyNameController.text;
    }

    final res = await AISuggestService.suggestGeneric(
      _role == 'creator' ? 'creator_bio' : 'brand_bio',
      contextData,
    );
    setState(() => _isAiLoading = false);
    if (res['success']) {
      setState(() => _bioController.text = res['suggestion']);
    }
  }
}
