import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../widgets/ai_suggest_button.dart';
import '../../services/ai_suggest_service.dart';
import '../../services/professional_dashboard_service.dart';

class ProfessionalProfileEditScreen extends StatefulWidget {
  const ProfessionalProfileEditScreen({super.key});

  @override
  State<ProfessionalProfileEditScreen> createState() => _ProfessionalProfileEditScreenState();
}

class _ProfessionalProfileEditScreenState extends State<ProfessionalProfileEditScreen> {
  final _bioController = TextEditingController();
  final _taglineController = TextEditingController();
  
  double _completionPercent = 0.85;
  bool _isAiLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save', style: TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCompletionHeader(),
            const SizedBox(height: 32),
            _buildSection(
              'Basic Info',
              [
                _buildLabel('Professional Tagline'),
                TextField(
                  controller: _taglineController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Expert Logo Designer & Brand Strategist',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Color(0xFFE63946)),
                      onPressed: () => _suggestTagline(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Bio'),
                    AiSuggestButton(
                      onPressed: () => _suggestBio(),
                      isLoading: _isAiLoading,
                      isSmall: true,
                    ),
                  ],
                ),
                TextField(
                  controller: _bioController,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Tell clients about your journey...'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Skills & Expertise',
              [
                Wrap(
                  spacing: 8,
                  children: [
                    _buildSkillChip('Graphic Design'),
                    _buildSkillChip('Logo Design'),
                    _buildSkillChip('Branding'),
                    ActionChip(
                      label: const Icon(Icons.add, size: 16),
                      onPressed: () {},
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSection(
              'Education & Certificates',
              [
                _buildListItem('B.A. in Visual Arts', 'University of Creative Arts'),
                _buildListItem('Google UX Design Professional', 'Coursera (2023)'),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add New Certification'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFE63946)),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Live Preview Profile'),
        ),
      ),
    );
  }

  Widget _buildCompletionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE63946).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE63946).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 35.0,
            lineWidth: 6.0,
            percent: _completionPercent,
            center: Text(
              '${(_completionPercent * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE63946)),
            ),
            progressColor: const Color(0xFFE63946),
            backgroundColor: const Color(0xFFE63946).withValues(alpha: 0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile 85% Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Add certifications to reach 100% and get noticed!', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
    );
  }

  Widget _buildSkillChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildListItem(String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.more_vert_rounded, size: 20),
    );
  }

  // AI Logic
  Future<void> _suggestTagline() async {
    setState(() => _isAiLoading = true);
    final res = await AISuggestService.suggestGeneric('professional_tagline', {
      'role': 'Graphic Designer',
      'skills': 'Logo, Branding',
    });
    setState(() => _isAiLoading = false);
    if (res['success']) {
      setState(() => _taglineController.text = res['suggestion']);
    }
  }

  Future<void> _suggestBio() async {
    setState(() => _isAiLoading = true);
    final res = await AISuggestService.suggestGeneric('professional_bio', {
      'tagline': _taglineController.text,
      'role': 'Graphic Designer',
    });
    setState(() => _isAiLoading = false);
    if (res['success']) {
      setState(() => _bioController.text = res['suggestion']);
    }
  }
}
