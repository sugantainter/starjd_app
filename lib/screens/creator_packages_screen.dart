
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class CreatorPackagesScreen extends StatefulWidget {
  const CreatorPackagesScreen({super.key});

  @override
  State<CreatorPackagesScreen> createState() => _CreatorPackagesScreenState();
}

class _CreatorPackagesScreenState extends State<CreatorPackagesScreen> {
  bool _isLoading = true;
  List<dynamic> _packages = [];
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final res = await CreatorDashboardService.getPackages();
    final catRes = await CreatorDashboardService.getPackageCategories();
    
    if (mounted) {
      setState(() {
        if (res['success']) _packages = res['data'];
        if (catRes['success']) _categories = catRes['data'];
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePackage(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: const Text('Are you sure you want to delete this package?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final res = await CreatorDashboardService.deletePackage(id);
      if (!mounted) return; 
      if (res['success']) {
        _loadData();
      }
    }
  }

  Future<void> _showPackageDialog({Map<String, dynamic>? package}) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final nameController = TextEditingController(text: package?['name'] ?? '');
    final priceController = TextEditingController(text: package?['price']?.toString() ?? '');
    final descController = TextEditingController(text: package?['description'] ?? '');
    final deliverablesController = TextEditingController(text: package?['deliverables'] ?? '');
    
    int? selectedCategoryId = package?['package_category_id'];
    bool isActive = package?['is_active'] ?? true;
    
    List<Map<String, dynamic>> items = [];
    if (package != null && package['items'] != null) {
      items = List<Map<String, dynamic>>.from(
        (package['items'] as List).map((it) => {
          'id': it['id'],
          'name': it['name'],
          'quantity': it['quantity'],
          'unit_price': it['unit_price'],
        })
      );
    } else {
      items = [];
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(package == null ? 'Add New Package' : 'Edit Package', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildFieldLabel('General Details'),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: _inputDecoration('Package Name', hint: 'e.g. Basic UGC Video'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: _inputDecoration('Category'),
                    dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    items: _categories.map((c) => DropdownMenuItem<int>(
                      value: c['id'],
                      child: Text(c['name']),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedCategoryId = v),
                    hint: Text('Select Category', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Price', prefix: '₹'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    maxLines: 2,
                    decoration: _inputDecoration('Description', hint: 'Short summary...'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deliverablesController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    maxLines: 2,
                    decoration: _inputDecoration('Deliverables', hint: 'e.g. 1 MP4 Video, Raw footage...'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: isActive,
                    activeColor: const Color(0xFFE63946),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                  
                  const Divider(height: 32),
                  _buildFieldLabel('Package Items (Line Items)'),
                  ...items.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var it = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(hintText: 'Item Name (e.g. Video)'),
                                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                                  onChanged: (v) => it['name'] = v,
                                  controller: TextEditingController(text: it['name'])..selection = TextSelection.collapsed(offset: (it['name'] ?? '').length),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => setDialogState(() => items.removeAt(idx)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(hintText: 'Qty'),
                                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => it['quantity'] = int.tryParse(v) ?? 1,
                                  controller: TextEditingController(text: it['quantity']?.toString()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(hintText: 'Unit Price'),
                                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => it['unit_price'] = double.tryParse(v) ?? 0,
                                  controller: TextEditingController(text: it['unit_price']?.toString()),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setDialogState(() => items.add({'name': '', 'quantity': 1, 'unit_price': 0.0})),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFE63946)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                
                final data = {
                  'name': nameController.text.trim(),
                  'price': double.tryParse(priceController.text) ?? 0,
                  'description': descController.text.trim(),
                  'deliverables': deliverablesController.text.trim(),
                  'package_category_id': selectedCategoryId,
                  'is_active': isActive,
                  'items': items,
                };

                final res = await CreatorDashboardService.savePackage(data, id: package?['id']);
                if (res['success']) {
                  if (mounted) Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save Package'),
            ),
          ],
        ),
      ),
    );
    
    if (!mounted) return;

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Packages', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
        : _packages.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final p = _packages[index];
                return _buildPackageCard(p);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPackageDialog(),
        backgroundColor: const Color(0xFFE63946),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPackageCard(dynamic p) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isActive = p['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p['name'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                          const SizedBox(width: 8),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                              child: const Text('PAUSED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('₹${p['price']}', style: const TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.bold, fontSize: 18)),
                      if (p['package_category'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(p['package_category']['name'], style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _showPackageDialog(package: p)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deletePackage(p['id'])),
                  ],
                ),
              ],
            ),
          ),
          if (p['description'] != null && p['description'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(p['description'], style: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade600, fontSize: 13)),
            ),
          if (p['items'] != null && (p['items'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isDark ? Colors.black.withOpacity(0.1) : Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INCLUDES:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  ...(p['items'] as List).map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• ${it['quantity']}x ${it['name']}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                  )),
                ],
              ),
            ),
          ] else const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No packages defined', style: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Define your services and rates for brands.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? prefix}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      labelStyle: const TextStyle(fontSize: 14),
      hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
      isDense: true,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFF6B7280))),
    );
  }
}
