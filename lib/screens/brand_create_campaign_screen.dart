import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../services/ai_suggest_service.dart';
import '../widgets/ai_suggest_button.dart';

class BrandCreateCampaignScreen extends StatefulWidget {
  const BrandCreateCampaignScreen({super.key});

  @override
  State<BrandCreateCampaignScreen> createState() => _BrandCreateCampaignScreenState();
}

class _BrandCreateCampaignScreenState extends State<BrandCreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  String _selectedType = 'instagram';
  int _influencerCount = 10;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAiLoading = false;
  
  // Targeting
  final List<String> _niches = [];
  final List<String> _countries = [];
  final TextEditingController _nicheController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final List<Map<String, String>> _types = [
    {'id': 'instagram', 'name': 'Instagram', 'icon': 'camera_alt_outlined'},
    {'id': 'tiktok', 'name': 'TikTok', 'icon': 'music_note_outlined'},
    {'id': 'ugc', 'name': 'UGC', 'icon': 'video_collection_outlined'},
    {'id': 'youtube', 'name': 'YouTube', 'icon': 'play_circle_outline'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Instagram Campaign';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    _nicheController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final Map<String, dynamic> data = {
      'campaign_type': _selectedType,
      'influencer_count': _influencerCount,
      'title': _titleController.text,
      'budget': double.tryParse(_budgetController.text) ?? 5000,
      'description': _descriptionController.text.trim(),
      'niches': _niches,
      'countries': _countries,
    };

    final result = await BrandDashboardService.saveCampaign(data);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create campaign')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Start New Campaign', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Select Platform'),
              _buildTypeSelector(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('Basic Info'),
              _buildTextField(_titleController, 'Campaign Title', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _budgetController, 
                      'Total Budget (₹)', 
                      keyboardType: TextInputType.number,
                      hint: 'e.g. 5000'
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberField('Creator Count', _influencerCount, (val) {
                      setState(() => _influencerCount = val);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Campaign Description'),
                  AiSuggestButton(
                    onPressed: () => _suggestAiDescription(),
                    isLoading: _isAiLoading,
                    isSmall: true,
                  ),
                ],
              ),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what you need from creators...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Targeting (Optional)'),
              _buildModernChipField(_nicheController, 'Target Niches', _niches, 'Add Niche (e.g. Fashion)'),
              const SizedBox(height: 16),
              _buildModernChipField(_countryController, 'Target Countries', _countries, 'Add Country (e.g. India)'),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Launch Campaign', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _types.map((t) {
          final isSelected = _selectedType == t['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = t['id']!;
                  _titleController.text = '${t['name']} Campaign';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      _getCampaignIcon(t['id']), 
                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['name']!, 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280)
                      )
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hint, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => value > 1 ? onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline, size: 20)),
              Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline, size: 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernChipField(TextEditingController controller, String label, List<String> items, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              setState(() {
                items.add(val.trim());
                controller.clear();
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            prefixIcon: const Icon(Icons.add, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFFE63946).withValues(alpha: 0.05),
              side: BorderSide(color: const Color(0xFFE63946).withValues(alpha: 0.1)),
              onDeleted: () => setState(() => items.remove(tag)),
              deleteIcon: const Icon(Icons.close, size: 14),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  IconData _getCampaignIcon(String? type) {
    switch (type) {
      case 'instagram': return Icons.camera_alt_outlined;
      case 'youtube': return Icons.play_circle_outline;
      case 'tiktok': return Icons.music_note_outlined;
      case 'ugc': return Icons.video_collection_outlined;
      default: return Icons.campaign_outlined;
    }
  }

  // AI Suggest Logic
  Future<void> _suggestAiDescription() async {
    setState(() => _isAiLoading = true);
    final res = await AISuggestService.suggestGeneric('campaign_description', {
      'company_name': 'My Brand', // Ideally fetch from user data
      'campaign_type': _selectedType,
    });
    setState(() => _isAiLoading = false);
    if (res['success']) {
      setState(() => _descriptionController.text = res['suggestion']);
    }
  }
}
