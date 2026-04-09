import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/collaboration.dart';
import '../services/collaboration_service.dart';

class BankAccountsScreen extends StatefulWidget {
  final bool isEmbed;
  final Function(BankAccount)? onSelect;

  const BankAccountsScreen({super.key, this.isEmbed = false, this.onSelect});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  List<BankAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    _accounts = await CollaborationService.getBankAccounts();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
        : _accounts.isEmpty
            ? _buildEmptyState()
            : _buildList();

    if (widget.isEmbed) return Column(children: [Expanded(child: content), _buildAddButton()]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Accounts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: content,
      bottomNavigationBar: _buildAddButton(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No bank accounts added', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add an account to receive payouts or refunds.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final acc = _accounts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            onTap: widget.onSelect != null ? () => widget.onSelect!(acc) : null,
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance, color: Color(0xFF6366F1)),
            ),
            title: Text(acc.bankName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(acc.accountHolderName, style: const TextStyle(fontSize: 13)),
                Text(acc.maskedAccountNumber, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text('IFSC: ${acc.ifscCode}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _handleDelete(acc),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: _showAddDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Add Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handleDelete(BankAccount acc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('Are you sure you want to remove this bank account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await CollaborationService.deleteBankAccount(acc.id);
      if (res['success']) _loadAccounts();
    }
  }

  void _showAddDialog() {
    final bankName = TextEditingController();
    final holderName = TextEditingController();
    final accNumber = TextEditingController();
    final ifsc = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 32, right: 32, top: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Bank Account', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildField(bankName, 'Bank Name', 'e.g. HDFC Bank'),
              const SizedBox(height: 16),
              _buildField(holderName, 'Account Holder Name', 'As per passbook'),
              const SizedBox(height: 16),
              _buildField(accNumber, 'Account Number', 'Enter full number'),
              const SizedBox(height: 16),
              _buildField(ifsc, 'IFSC Code', 'e.g. HDFC0001234'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (bankName.text.isEmpty || accNumber.text.isEmpty || ifsc.text.isEmpty) return;
                  final res = await CollaborationService.addBankAccount({
                    'bank_name': bankName.text,
                    'account_holder_name': holderName.text,
                    'account_number': accNumber.text,
                    'ifsc_code': ifsc.text,
                  });
                  if (res['success']) {
                    Navigator.pop(context);
                    _loadAccounts();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
