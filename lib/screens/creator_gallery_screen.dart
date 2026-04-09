
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CreatorGalleryScreen extends StatefulWidget {
  const CreatorGalleryScreen({super.key});

  @override
  State<CreatorGalleryScreen> createState() => _CreatorGalleryScreenState();
}

class _CreatorGalleryScreenState extends State<CreatorGalleryScreen> {
  bool _isLoading = true;
  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final res = await CreatorDashboardService.getImagePosts();
    if (mounted) {
      setState(() {
        if (res['success']) {
          _images = res['data'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;
    
    if (!mounted) return;

    // Show caption dialog
    final String? caption = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Caption'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter caption...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Upload'),
            ),
          ],
        );
      }
    );

    if (!mounted) return;

    if (caption != null) {
      setState(() => _isLoading = true);
      final res = await CreatorDashboardService.uploadImagePost(File(image.path), caption);
      if (mounted) {
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded!')));
          _loadImages();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
          setState(() => _isLoading = false);
        }
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
        title: const Text('My Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
        : _images.isEmpty 
            ? _buildEmptyState()
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  final img = _images[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 5)],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      img['image_url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadImage,
        backgroundColor: const Color(0xFFE63946),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No images yet', style: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Upload your work to showcase it!', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        ],
      ),
    );
  }
}
