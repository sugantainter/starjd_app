import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../services/studio_service.dart';
import '../services/ai_suggest_service.dart';
import '../widgets/ai_suggest_button.dart';


class EditStudioScreen extends StatefulWidget {
  final int? studioId;
  const EditStudioScreen({super.key, this.studioId});

  @override
  State<EditStudioScreen> createState() => _EditStudioScreenState();
}

class _EditStudioScreenState extends State<EditStudioScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  quill.QuillController _descriptionQuillController = quill.QuillController.basic();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _pricePerHourController = TextEditingController();
  final TextEditingController _pricePerDayController = TextEditingController();

  List<dynamic> _categories = [];
  List<dynamic> _amenities = [];
  List<int> _selectedAmenityIds = [];
  List<dynamic> _existingImages = [];
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  int? _selectedCategoryId;
  String _selectedCancellationPolicy = 'moderate';
  String _selectedStatus = 'draft';
  bool _isAiLoading = false;


  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    
    // Fetch categories & amenities
    final categoriesResult = await StudioService.fetchCategories();
    _categories = categoriesResult.map((c) => {'id': c.id, 'name': c.name}).toList();

    try {
      final c = await AuthService.client;
      final amenitiesRes = await c.get('/api/amenities');
      if (amenitiesRes.statusCode == 200) {
        _amenities = amenitiesRes.data;
      }
    } catch (_) {}

    if (widget.studioId != null) {
      final studioResult = await StudioOwnerDashboardService.getStudioDetail(widget.studioId!);
      if (studioResult['success']) {
        final data = studioResult['data'];
        _nameController.text = data['name'] ?? '';
        
        // Convert HTML to Quill Delta
        if (data['description'] != null && data['description'].toString().isNotEmpty) {
          final delta = HtmlToDelta().convert(data['description']);
          _descriptionQuillController = quill.QuillController(
            document: quill.Document.fromDelta(delta),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }

        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _stateController.text = data['state'] ?? '';
        _pincodeController.text = data['pincode']?.toString() ?? '';
        _pricePerHourController.text = data['price_per_hour']?.toString() ?? '';
        _pricePerDayController.text = data['price_per_day']?.toString() ?? '';
        _selectedCategoryId = data['category_id'];
        _selectedCancellationPolicy = data['cancellation_policy'] ?? 'moderate';
        _selectedStatus = data['status'] ?? 'draft';
        _selectedAmenityIds = List<int>.from(data['amenity_ids'] ?? []);
        _existingImages = data['images'] ?? [];
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveStudio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isSaving = true);

    final deltaJson = _descriptionQuillController.document.toDelta().toJson();
    final converter = QuillDeltaToHtmlConverter(List<Map<String, dynamic>>.from(deltaJson));
    final htmlOutput = converter.convert();

    final data = {
      'name': _nameController.text,
      'description': htmlOutput,
      'address': _addressController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
      'price_per_hour': _pricePerHourController.text,
      'price_per_day': _pricePerDayController.text,
      'category_id': _selectedCategoryId,
      'cancellation_policy': _selectedCancellationPolicy,
      'status': _selectedStatus,
      'amenity_ids': _selectedAmenityIds.join(','), // Convert to comma string for FormData support
    };

    final List<File> imageFiles = _newImages.map((x) => File(x.path)).toList();
    final result = await StudioOwnerDashboardService.saveStudio(data, id: widget.studioId, images: imageFiles);

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Studio saved successfully!')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.studioId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Studio' : 'Add Studio', style: const TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveStudio,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE63946)))
                  : const Text('Save', style: TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(_nameController, 'Studio Name', required: true),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Category',
                      _selectedCategoryId,
                      _categories.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                      (val) => setState(() => _selectedCategoryId = val),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle(
                      'Description',
                      trailing: AiSuggestButton(
                        onPressed: () => _suggestAiDescription(),
                        isLoading: _isAiLoading,
                        isSmall: true,
                      ),
                    ),
                    _buildQuillEditor(),

                    const SizedBox(height: 24),
                    _buildSectionTitle('Location'),
                    _buildTextField(_addressController, 'Building Name / Street'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_cityController, 'City')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_stateController, 'State')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_pincodeController, 'Pincode', keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Amenities'),
                    _amenities.isEmpty 
                      ? const Text('Loading amenities...', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _amenities.map((amenity) {
                            final isSelected = _selectedAmenityIds.contains(amenity['id']);
                            return FilterChip(
                              label: Text(amenity['name']),
                              selected: isSelected,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedAmenityIds.add(amenity['id']);
                                  } else {
                                    _selectedAmenityIds.remove(amenity['id']);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFFE63946).withValues(alpha: 0.1),
                              checkmarkColor: const Color(0xFFE63946),
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFFE63946) : const Color(0xFF4B5563),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: const Color(0xFFF3F4F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            );
                          }).toList(),
                        ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Pricing & Policies'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_pricePerHourController, 'Price / Hour (₹)', keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_pricePerDayController, 'Price / Day (₹)', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Cancellation Policy',
                      _selectedCancellationPolicy,
                      const [
                        DropdownMenuItem(value: 'flexible', child: Text('Flexible')),
                        DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                        DropdownMenuItem(value: 'strict', child: Text('Strict')),
                      ],
                      (val) => setState(() => _selectedCancellationPolicy = val!),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Studio Images'),
                    // Preview existing and new images
                    if (_existingImages.isEmpty && _newImages.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, color: Colors.grey.shade400, size: 40),
                            const SizedBox(height: 8),
                            const Text('No images yet.', style: TextStyle(color: Color(0xFF6B7280))),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._existingImages.map((img) => _buildImageThumbnail(img['image'], true)),
                            ..._newImages.map((img) => _buildImageThumbnail(img.path, false)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Add Images'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_newImages.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => setState(() => _newImages.clear()),
                            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                            tooltip: 'Clear selection',
                          ),
                        ]
                      ],
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Visibility Status'),
                      _buildDropdown(
                        'Status',
                        _selectedStatus,
                        const [
                          DropdownMenuItem(value: 'draft', child: Text('Draft')),
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        ],
                        (val) => setState(() => _selectedStatus = val!),
                      ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveStudio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE63946),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isSaving ? 'Saving...' : 'Save Studio', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildQuillEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toolbar
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: quill.QuillSimpleToolbar(
                  controller: _descriptionQuillController,
                  config: const quill.QuillSimpleToolbarConfig(
                    showFontFamily: false,
                    showFontSize: false,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showListBullets: true,
                    showListNumbers: false,
                    showQuote: false,
                    showCodeBlock: false,
                    showLink: false,
                    showUndo: false,
                    showRedo: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showAlignmentButtons: false,
                    showDirection: false,
                    multiRowsDisplay: false,
                  ),
                ),
              ),
              // Editor
              Container(
                constraints: const BoxConstraints(minHeight: 150, maxHeight: 300),
                padding: const EdgeInsets.all(12),
                child: quill.QuillEditor(
                  controller: _descriptionQuillController,
                  focusNode: FocusNode(),
                  scrollController: ScrollController(),
                  config: const quill.QuillEditorConfig(
                    placeholder: 'Enter studio details...',
                    expands: false,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(String path, bool isNetwork) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: isNetwork ? NetworkImage(path) : FileImage(File(path)) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _newImages.addAll(picked));
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1.1)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE63946))),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (val) {
            if (required && (val == null || val.isEmpty)) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    Function(T?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 1.1)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
              hint: const Text('Select Option'),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // AI Logic
  Future<void> _suggestAiDescription() async {
    setState(() => _isAiLoading = true);
    final res = await AISuggestService.suggestGeneric('studio_description', {
      'name': _nameController.text,
      'category': _categories.firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => {'name': 'Photography'})['name'],
    });
    setState(() => _isAiLoading = false);
    if (res['success']) {
      final text = res['suggestion'];
      // Convert text to Delta and update editor
      setState(() {
        _descriptionQuillController.document = quill.Document()..insert(0, text);
        _descriptionQuillController.updateSelection(const TextSelection.collapsed(offset: 0), quill.ChangeSource.local);
      });
    }
  }
}
