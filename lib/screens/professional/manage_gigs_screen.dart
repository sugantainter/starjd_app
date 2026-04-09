import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/professional_service.dart';
import '../../env/env.dart';
import 'gig_wizard_screen.dart';

class ManageGigsScreen extends StatefulWidget {
  const ManageGigsScreen({Key? key}) : super(key: key);

  @override
  _ManageGigsScreenState createState() => _ManageGigsScreenState();
}

class _ManageGigsScreenState extends State<ManageGigsScreen> {
  bool _isLoading = true;
  List<dynamic> _listings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ProfessionalService.getProfessionalListings();
      setState(() {
        _listings = res;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    final val = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('My Professional Services', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: textMuted)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadListings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                )
              : _listings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.handyman_outlined, size: 40, color: Color(0xFFF59E0B)),
                              ),
                              const SizedBox(height: 24),
                              Text('Ready to start selling?', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first professional service listing and reach thousands of clients.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: textMuted),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const GigWizardScreen()));
                                    if (res == true) _loadListings();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadListings,
                      color: const Color(0xFFF59E0B),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listings.length,
                        itemBuilder: (context, index) {
                          final listing = _listings[index];
                          
                          // Handle gallery parsing exactly as gig detail
                          List<String> galleryList = [];
                          if (listing['gallery'] != null) {
                            var g = listing['gallery'];
                            if (g is List) {
                              galleryList = g.map((e) => e.toString()).toList();
                            } else if (g is String) {
                              if (g.trim().startsWith('[')) {
                                try {
                                  List<dynamic> parsed = jsonDecode(g);
                                  galleryList = parsed.map((e) => e.toString()).toList();
                                } catch (_) {}
                              } else if (g.trim().isNotEmpty) {
                                galleryList = [g];
                              }
                            }
                          }
                          
                          String? displayImage = galleryList.isNotEmpty ? galleryList.first : null;
                          if (displayImage != null && !displayImage.startsWith('http')) {
                             displayImage = '${Env.apiUrl}$displayImage';
                          }

                          final category = listing['service_category']?['name'] ?? 'General';
                          final isActive = listing['is_active'] == 1 || listing['is_active'] == true;
                          final pricingTiers = listing['pricing_tiers'] as List? ?? [];
                          final startingPrice = pricingTiers.isNotEmpty ? pricingTiers[0]['price'] : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8FAFC),
                                    child: displayImage != null
                                        ? Image.network(displayImage, fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.image_not_supported_outlined, size: 48, color: textMuted))
                                        : Icon(Icons.image_outlined, size: 48, color: borderColor),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              category.toString().toUpperCase(),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? 'ACTIVE' : 'DRAFT',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isActive ? Colors.green[700] : Colors.red[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        listing['title'] ?? '',
                                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Starting at', style: TextStyle(color: textMuted, fontSize: 12)),
                                              Text(
                                                _formatCurrency(startingPrice),
                                                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              final res = await Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => GigWizardScreen(listingData: listing)),
                                              );
                                              if (res == true) _loadListings();
                                            },
                                            icon: Icon(Icons.edit_outlined, color: textMuted),
                                            style: IconButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: BorderSide(color: borderColor),
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _listings.isNotEmpty && !_isLoading && _errorMessage == null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const GigWizardScreen()));
                if (res == true) _loadListings();
              },
              backgroundColor: const Color(0xFFF59E0B),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create New Gig', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
