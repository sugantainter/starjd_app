import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/professional_service.dart';
import '../../env/env.dart';

class GigWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? listingData;
  const GigWizardScreen({Key? key, this.listingData}) : super(key: key);

  @override
  _GigWizardScreenState createState() => _GigWizardScreenState();
}

class _GigWizardScreenState extends State<GigWizardScreen> {
  int _currentStep = 1;
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _categories = [];
  
  // AI States
  bool _suggestingTitle = false;
  bool _suggestingTags = false;
  bool _suggestingPricing = false;
  bool _suggestingDescription = false;
  bool _suggestingFAQs = false;
  List<String> _titleSuggestions = [];
  bool _showTitles = false;

  final Map<String, dynamic> _form = {
    'id': null,
    'service_id': '',
    'title': '',
    'slug': '',
    'description': '',
    'pricing_tiers': [
      <String, dynamic>{'name': 'Basic', 'description': '', 'price': '', 'delivery': '', 'revisions': '', 'features': <String, dynamic>{}},
      <String, dynamic>{'name': 'Standard', 'description': '', 'price': '', 'delivery': '', 'revisions': '', 'features': <String, dynamic>{}},
      <String, dynamic>{'name': 'Premium', 'description': '', 'price': '', 'delivery': '', 'revisions': '', 'features': <String, dynamic>{}}
    ],
    'faqs': <Map<String, dynamic>>[],
    'gallery': <String>[],
    'tags': <String>[],
  };

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _newTagController = TextEditingController();
  final TextEditingController _faqQuestionController = TextEditingController();
  final TextEditingController _faqAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final cats = await ProfessionalService.fetchMarketplaceFilters();
      setState(() => _categories = cats);

      if (widget.listingData != null) {
        final data = widget.listingData!;
        _form['id'] = data['id'];
        _form['service_id'] = data['service_id']?.toString() ?? '';
        _form['title'] = data['title'] ?? '';
        _titleController.text = _form['title'];
        _form['slug'] = data['slug'] ?? '';
        _form['description'] = data['description'] ?? '';
        _descController.text = _form['description'];
        
        if (data['pricing_tiers'] != null && data['pricing_tiers'] is List) {
          final tiers = List<dynamic>.from(data['pricing_tiers']);
          for (int i = 0; i < tiers.length && i < 3; i++) {
             _form['pricing_tiers'][i] = <String, dynamic>{
                'name': tiers[i]['name']?.toString() ?? _form['pricing_tiers'][i]['name'],
                'description': tiers[i]['description']?.toString() ?? '',
                'price': tiers[i]['price']?.toString() ?? '',
                'delivery': tiers[i]['delivery']?.toString() ?? '',
                'revisions': tiers[i]['revisions']?.toString() ?? '',
                'features': Map<String, dynamic>.from(tiers[i]['features'] ?? {}),
             };
          }
        }
        
        final faqsRaw = data['faqs'] ?? [];
        if (faqsRaw is List) {
           _form['faqs'] = faqsRaw.map<Map<String, dynamic>>((f) => {
             'question': f['question']?.toString() ?? '', 
             'answer': f['answer']?.toString() ?? ''
           }).toList();
        }

        final galleryRaw = data['gallery'] ?? [];
        if (galleryRaw is List) {
           _form['gallery'] = galleryRaw.map((e) {
             String url = e.toString();
             return url.startsWith('http') ? url : '${Env.apiUrl}$url';
           }).toList();
        } else if (galleryRaw is String) {
           if (galleryRaw.trim().startsWith('[')) {
             try {
               List<dynamic> parsed = jsonDecode(galleryRaw);
               _form['gallery'] = parsed.map((e) {
                 String url = e.toString();
                 return url.startsWith('http') ? url : '${Env.apiUrl}$url';
               }).toList();
             } catch (_) {}
           } else if (galleryRaw.trim().isNotEmpty) {
             String url = galleryRaw;
             _form['gallery'] = [url.startsWith('http') ? url : '${Env.apiUrl}$url'];
           }
        }

        final tagsRaw = data['tags'] ?? [];
        if (tagsRaw is List) {
           _form['tags'] = List<String>.from(tagsRaw);
        }

      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initialize: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateSlug() {
    if (_form['id'] == null) {
      String slug = _titleController.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
      slug = slug.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
      _form['slug'] = slug;
    }
  }

  Future<void> _saveListing() async {
    setState(() => _isSaving = true);
    try {
      _form['title'] = _titleController.text;
      _form['description'] = _descController.text;
      await ProfessionalService.saveProfessionalListing(_form);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ==== AI Handlers ====
  Future<void> _suggestTitle() async {
    if (_form['service_id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first')));
      return;
    }
    setState(() => _suggestingTitle = true);
    try {
      final suggestions = await ProfessionalService.suggestTitleAI(_form['service_id'].toString());
      setState(() {
        _titleSuggestions = suggestions;
        _showTitles = true;
      });
    } catch (_) {
    } finally {
      setState(() => _suggestingTitle = false);
    }
  }

  Future<void> _suggestTags() async {
    if (_form['service_id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first')));
      return;
    }
    setState(() => _suggestingTags = true);
    try {
      final suggestions = await ProfessionalService.suggestTagsAI(_form['service_id'].toString());
      final currentTags = List<String>.from(_form['tags']);
      for (var t in suggestions) {
        if (!currentTags.contains(t) && currentTags.length < 5) currentTags.add(t);
      }
      setState(() => _form['tags'] = currentTags);
    } catch (_) {
    } finally {
      setState(() => _suggestingTags = false);
    }
  }

  Future<void> _smartPricingAI() async {
    if (_form['service_id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first')));
      return;
    }
    setState(() => _suggestingPricing = true);
    try {
      final pricing = await ProfessionalService.suggestPricingAI(_form['service_id'].toString());
      setState(() {
        for (var tier in _form['pricing_tiers']) {
          final name = tier['name'];
          if (pricing.containsKey(name)) {
            tier['description'] = pricing[name]['desc'] ?? pricing[name]['description'] ?? '';
            tier['features'] = {...(tier['features'] as Map), ...(pricing[name]['features'] ?? {})};
          }
        }
      });
    } catch (_) {
    } finally {
      setState(() => _suggestingPricing = false);
    }
  }

  Future<void> _suggestDescription() async {
    if (_form['service_id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first')));
      return;
    }
    setState(() => _suggestingDescription = true);
    try {
      String desc = await ProfessionalService.suggestDescriptionAI(_form['service_id'].toString(), _titleController.text);
      if (desc.isNotEmpty) {
        // Clean AI formatting if user wants it "clean" (remove redundant markdown symbols if any)
        desc = desc.replaceAll('**', '').replaceAll('* ', '• ').replaceAll('### ', '').replaceAll('## ', '');
        setState(() => _descController.text = desc.trim());
      }
    } catch (_) {
    } finally {
      setState(() => _suggestingDescription = false);
    }
  }

  Future<void> _suggestFAQs() async {
    if (_form['service_id'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first')));
      return;
    }
    setState(() => _suggestingFAQs = true);
    try {
      final newFaqs = await ProfessionalService.suggestFAQsAI(_form['service_id'].toString());
      final currentFaqs = List<Map<String, dynamic>>.from(_form['faqs']);
      final existingQs = currentFaqs.map((e) => e['question']).toList();
      for (var f in newFaqs) {
        if (!existingQs.contains(f['question'])) {
          currentFaqs.add({'question': f['question'], 'answer': f['answer']});
        }
      }
      setState(() => _form['faqs'] = currentFaqs);
    } catch (_) {
    } finally {
      setState(() => _suggestingFAQs = false);
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    
    if ((_form['gallery'] as List).length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 4 images allowed')));
      return;
    }

    try {
      // Show upload indicator via SnackBar or Dialog
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading image...')));
      final url = await ProfessionalService.uploadGigImage(image.path);
      setState(() {
        (_form['gallery'] as List<String>).add(url);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.listingData != null ? 'Edit Service' : 'Create New Service', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: theme.cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab(1, 'Overview'),
                  _buildTab(2, 'Pricing'),
                  _buildTab(3, 'Description'),
                  _buildTab(4, 'Gallery'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStep(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentStep > 1 
                      ? TextButton(onPressed: () => setState(() => _currentStep--), child: const Text('Previous'))
                      : const SizedBox.shrink(),
                  _currentStep < 4
                      ? ElevatedButton(
                          onPressed: () => setState(() => _currentStep++), 
                          style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : Colors.black, foregroundColor: isDark ? Colors.black : Colors.white),
                          child: const Text('Next Step', style: TextStyle(fontWeight: FontWeight.bold))
                        )
                      : ElevatedButton(
                          onPressed: _isSaving ? null : _saveListing,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
                          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Publish Gig', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int step, String label) {
    final active = _currentStep == step;
    return GestureDetector(
      onTap: () => setState(() => _currentStep = step),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? const Color(0xFFF59E0B) : Colors.transparent, width: 2))
        ),
        child: Text(label, style: TextStyle(color: active ? const Color(0xFFF59E0B) : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1: return _buildOverview();
      case 2: return _buildPricing();
      case 3: return _buildDescription();
      case 4: return _buildGallery();
      default: return const SizedBox.shrink();
    }
  }

  // --- Step 1: Overview ---
  Widget _buildOverview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Gig Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
            TextButton.icon(
              onPressed: _suggestingTitle ? null : _suggestTitle,
              icon: _suggestingTitle ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_suggestingTitle ? 'Suggesting...' : 'Suggest with AI', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
            )
          ],
        ),
        TextField(
          controller: _titleController,
          onChanged: (_) => _updateSlug(),
          maxLength: 80,
          maxLines: 2,
          decoration: inputDecoration.copyWith(hintText: "I will do something I'm really good at..."),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        if (_showTitles && _titleSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('✨ AI Generated Suggestions', style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    GestureDetector(onTap: () => setState(() => _showTitles = false), child: const Icon(Icons.close, size: 16, color: Color(0xFFB45309))),
                  ],
                ),
                const SizedBox(height: 8),
                ..._titleSuggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () {
                      _titleController.text = s;
                      _updateSlug();
                      setState(() => _showTitles = false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
                      child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                    ),
                  ),
                )).toList()
              ],
            ),
          ),
        
        const SizedBox(height: 24),
        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _form['service_id'].toString().isNotEmpty ? _form['service_id'].toString() : null,
          decoration: inputDecoration,
          hint: const Text('Select a Category'),
          items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
          onChanged: (val) => setState(() => _form['service_id'] = val ?? ''),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Search Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
            TextButton.icon(
              onPressed: _suggestingTags ? null : _suggestTags,
              icon: _suggestingTags ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_suggestingTags ? 'Suggesting...' : 'Suggest Tags', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
            )
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newTagController,
                decoration: inputDecoration.copyWith(hintText: 'Add up to 5 tags'),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTag,
              style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white12 : const Color(0xFFF1F5F9), foregroundColor: isDark ? Colors.white : Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Add'),
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: (_form['tags'] as List<String>).map((t) => Chip(
            label: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => (_form['tags'] as List).remove(t)),
            backgroundColor: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
            side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
          )).toList(),
        )
      ],
    );
  }

  void _addTag() {
    final t = _newTagController.text.trim();
    if (t.isNotEmpty && !(_form['tags'] as List).contains(t) && (_form['tags'] as List).length < 5) {
      setState(() => (_form['tags'] as List<String>).add(t));
      _newTagController.clear();
    }
  }

  // --- Step 2: Pricing ---
  Widget _buildPricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Smart-Fill Packages', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                    const Text('Instantly generate high-converting details', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _suggestingPricing ? null : _smartPricingAI,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _suggestingPricing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Smart-Fill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Ensure tiers are typed cleanly when iterating
        ...List.generate(3, (index) {
          final tier = _form['pricing_tiers'][index];
          return _buildPricingTierCard(tier, index);
        }),
      ],
    );
  }

  Widget _buildPricingTierCard(Map<String, dynamic> tier, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorMapping = [Colors.blue, Colors.purple, Colors.orange];
    final tColor = colorMapping[index];

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: tColor, width: 2)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: tColor.withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              children: [
                Icon(index == 0 ? Icons.star_border : index == 1 ? Icons.star_half : Icons.star, color: tColor, size: 20),
                const SizedBox(width: 8),
                Text(tier['name'].toString().toUpperCase(), style: TextStyle(color: tColor, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: tier['price'].toString(),
                  onChanged: (v) => tier['price'] = v,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration.copyWith(prefixText: '₹ '),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  key: ValueKey('${tier['name']}_desc_${tier['description'].length}'), // Force rebuild on AI fill
                  initialValue: tier['description'].toString(),
                  onChanged: (v) => tier['description'] = v,
                  maxLines: 3,
                  decoration: inputDecoration.copyWith(hintText: "What's included?"),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: tier['delivery'].toString().isNotEmpty ? tier['delivery'].toString() : null,
                            decoration: inputDecoration,
                            items: [1,2,3,4,5,7,10,14,21,30].map((d) => DropdownMenuItem(value: d.toString(), child: Text('$d Days'))).toList(),
                            onChanged: (v) => tier['delivery'] = v ?? '',
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Revisions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: tier['revisions'].toString().isNotEmpty ? tier['revisions'].toString() : null,
                            decoration: inputDecoration,
                            items: [0,1,2,3,5,10,20].map((r) => DropdownMenuItem(value: r.toString(), child: Text(r == 20 ? 'Unlimited' : '$r'))).toList(),
                            onChanged: (v) => tier['revisions'] = v ?? '',
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Step 3: Description & FAQs ---
  Widget _buildDescription() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Detailed Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))),
            TextButton.icon(
              onPressed: _suggestingDescription ? null : _suggestDescription,
              icon: _suggestingDescription ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_suggestingDescription ? 'Generating...' : 'AI Generate', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
            )
          ],
        ),
        TextField(
          controller: _descController,
          maxLines: 12,
          decoration: inputDecoration.copyWith(hintText: "Describe what you are offering. Be as detailed as possible..."),
        ),
        
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        
        Row(
          children: [
            const Expanded(child: Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))),
            TextButton.icon(
              onPressed: _suggestingFAQs ? null : _suggestFAQs,
              icon: _suggestingFAQs ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_suggestingFAQs ? 'Adding...' : 'Suggest FAQs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFF59E0B)),
            )
          ],
        ),
        
        ...(_form['faqs'] as List<Map<String, dynamic>>).asMap().entries.map((entry) {
          int i = entry.key;
          Map<String, dynamic> faq = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(faq['question'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    GestureDetector(onTap: () => setState(() => (_form['faqs'] as List).removeAt(i)), child: const Icon(Icons.close, size: 16, color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(faq['answer'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }).toList(),
        
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.none)), // Dotted effect normally done with path_drawing but keeping it simple
          child: Column(
            children: [
              TextField(
                controller: _faqQuestionController,
                decoration: inputDecoration.copyWith(hintText: 'Add a Question (e.g. Do you provide sources?)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _faqAnswerController,
                maxLines: 3,
                decoration: inputDecoration.copyWith(hintText: 'Add an Answer'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final q = _faqQuestionController.text.trim();
                    final a = _faqAnswerController.text.trim();
                    if (q.isNotEmpty && a.isNotEmpty) {
                      setState(() {
                         (_form['faqs'] as List<Map<String, dynamic>>).add({'question': q, 'answer': a});
                         _faqQuestionController.clear();
                         _faqAnswerController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : Colors.black, foregroundColor: isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Add FAQ'),
                ),
              )
            ],
          ),
        )

      ],
    );
  }

  // --- Step 4: Gallery ---
  Widget _buildGallery() {
    final gallery = _form['gallery'] as List<String>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Portfolio Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 16/9,
          ),
          itemCount: gallery.length + (gallery.length < 4 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < gallery.length) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: gallery[index].startsWith('http') 
                        ? Image.network(gallery[index], fit: BoxFit.cover)
                        : Image.file(File(gallery[index]), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => gallery.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  )
                ],
              );
            } else {
               return GestureDetector(
                 onTap: _uploadImage,
                 child: Container(
                   decoration: BoxDecoration(
                     color: const Color(0xFFF8FAFC),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: const Color(0xFFCBD5E1), width: 2), // Should be dashed, but line works
                   ),
                   child: const Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 32),
                       SizedBox(height: 8),
                       Text('Upload Image', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
                     ],
                   ),
                 ),
               );
            }
          },
        ),
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.blue, fontSize: 12, height: 1.5),
                    children: [
                      TextSpan(text: 'Pro Tip: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'High-quality images (1280x720px) help your service stand out. You can upload up to 4 images to showcase different aspects of your work.'),
                    ]
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
