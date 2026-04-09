import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/collaboration.dart';
import '../services/collaboration_service.dart';
import '../services/auth_service.dart';
import 'bank_accounts_screen.dart';
import 'secure_preview_screen.dart';
import 'payu_webview_screen.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';

class CollaborationsScreen extends StatefulWidget {
  const CollaborationsScreen({super.key});

  @override
  State<CollaborationsScreen> createState() => _CollaborationsScreenState();
}

class _CollaborationsScreenState extends State<CollaborationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Collaboration> _collaborations = [];
  bool _isLoading = true;
   String? _userRole;
   int? _userId;
   bool _isProcessingPayment = false;
   final Map<int, bool> _acceptedAgreements = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getUser();
    _userRole = user?['role'];
    _userId = user?['id'];
    _collaborations = await CollaborationService.getCollaborations();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Collaborations',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'PROJECTS'),
            Tab(text: 'BANK ACCOUNTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjectsTab(),
          const BankAccountsScreen(isEmbed: true),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFC4402)));
    }

    if (_collaborations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'No active projects',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your collaboration requests will appear here.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ).animate().fadeIn().scale();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _collaborations.length,
        itemBuilder: (context, index) {
          final collab = _collaborations[index];
          return _buildCollabCard(collab);
        },
      ),
    );
  }

  Widget _buildCollabCard(Collaboration collab) {
    final isCreator = collab.creatorId == _userId;
    final otherParty = isCreator ? collab.brand : collab.creator;
    final otherName = otherParty?['name'] ?? 'Unknown';
    final otherAvatar = isCreator 
        ? (collab.brand?['brand_profile']?['logo_url'] ?? collab.brand?['avatar_url'])
        : (collab.creator?['creator_profile']?['avatar_url'] ?? collab.creator?['avatar_url']);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF1F5F9),
                  backgroundImage: otherAvatar != null ? NetworkImage(otherAvatar) : null,
                  child: otherAvatar == null ? Text(otherName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otherName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              collab.package?['name'] ?? 'Custom Project',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${collab.amount}',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF1A1A1A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isCreator ? 'EARNINGS' : 'PROJECT TOTAL',
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Text(
                      '₹${isCreator ? collab.creatorAmount : (collab.amount - (collab.resolvedRefundAmount ?? 0))}',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Progress Stepper
          _buildProgressStepper(collab),

          // Action Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (collab.status == 'revision_requested')
                  _buildStatusBubble(
                    Icons.history_outlined,
                    'Revision Requested',
                    collab.revisionNotes ?? '',
                    Colors.purple,
                  ),
                if (collab.status == 'disputed')
                  _buildStatusBubble(
                    Icons.gavel_outlined,
                    'Dispute Under Review',
                    'Admin mediation in progress offline.',
                    Colors.red,
                  ),
                if (collab.brandNotes != null && collab.brandNotes!.isNotEmpty)
                  _buildStatusBubble(
                    Icons.assignment_outlined,
                    'Project Brief',
                    collab.brandNotes!,
                    const Color(0xFF3B82F6),
                  ),
                if (collab.deliverableContent != null)
                  _buildDeliverableRow(collab),

                const SizedBox(height: 16),
                _buildActionButtons(collab),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildProgressStepper(Collaboration collab) {
    const steps = ['Req', 'Acc', 'Paid', 'Delv', 'Comp'];
    final currentIdx = collab.statusIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 2,
                color: const Color(0xFFF1F5F9),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: collab.progressPercentage.clamp(0.0, 1.0),
                child: Container(height: 3, color: const Color(0xFFFC4402)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(steps.length, (index) {
                  final isCompleted = currentIdx > index;
                  final isActive = currentIdx == index;
                  
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFFFC4402) : (isActive ? Colors.white : const Color(0xFFF1F5F9)),
                      border: Border.all(
                        color: isCompleted || isActive ? const Color(0xFFFC4402) : Colors.white,
                        width: isActive ? 4 : 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : (isActive ? null : Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 8, color: Colors.grey)))),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((s) => Text(s, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBubble(IconData icon, String title, String notes, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                Text(notes, style: GoogleFonts.outfit(fontSize: 13, color: color.withOpacity(0.8), fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverableRow(Collaboration collab) {
    return GestureDetector(
      onTap: () => _openPreview(collab),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.description_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Project Deliverable', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(collab.deliverableContent!.split('/').last, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (collab.status == 'delivered' && collab.creatorId != _userId)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFFFC4402)),
                   const SizedBox(width: 4),
                   Text(
                    'SECURE PREVIEW', 
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFC4402)),
                  ),
                ],
              ),
            if (['completed', 'resolved'].contains(collab.status))
              InkWell(
                onTap: () => _handleDashboardDownload(collab),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_for_offline_outlined, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'DOWNLOAD', 
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            if (collab.status == 'delivered' && collab.creatorId == _userId)
               Text('AWAITING APPROVAL', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber[700])),
          ],
        ),
      ),
    );
  }

  void _handleDashboardDownload(Collaboration collab) async {
    final res = await CollaborationService.getFilePreview(collab.id, intent: 'download');
    if (res['success']) {
      final data = res['data'];
      final token = data['preview_token'];
      final baseUrl = data['url'];
      final downloadUrl = 'https://www.starjd.com$baseUrl?preview_token=$token&download=1';
      
      final String fileName = collab.deliverableContent?.split('/').last ?? 'project_deliverable_${collab.id}.zip';
      
      Directory? dir;
      bool saveToPublic = false;

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final base = await getExternalStorageDirectory();
          final String? rootPath = base?.path.split('/Android')[0];
          if (rootPath != null) {
            dir = Directory('$rootPath/Download');
            if (!await dir.exists()) await dir.create(recursive: true);
            saveToPublic = true;
          }
        }
      }
      
      dir ??= await getApplicationDocumentsDirectory();
      final String savePath = '${dir.path}/$fileName';
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting secure download...')));
      
      final downloadRes = await CollaborationService.downloadFile(
        downloadUrl, 
        savePath, 
        (progress) {}
      );
      
      if (!mounted) return;
      if (downloadRes['success']) {
        NotificationService.showDownloadNotification(fileName, savePath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saveToPublic ? 'Saved to Downloads: $fileName' : 'Saved to App Docs: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'OPEN', 
              textColor: Colors.white, 
              onPressed: () async {
                final openRes = await OpenFilex.open(savePath);
                if (openRes.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open file: ${openRes.message}')),
                  );
                }
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download Failed: ${downloadRes['message']}')),
        );
      }
    }
  }

  Widget _buildActionButtons(Collaboration collab) {
    final isCreator = collab.creatorId == _userId;

    if (collab.status == 'pending') {
      if (isCreator) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAccept(collab),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleReject(collab),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Text('WAITING FOR CREATOR', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[700])),
          ),
        );
      }
    }

    if (collab.status == 'accepted') {
      if (!isCreator) {
        final isAccepted = _acceptedAgreements[collab.id] ?? false;
        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _acceptedAgreements[collab.id] = !isAccepted;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: isAccepted,
                        onChanged: (val) {
                          setState(() {
                            _acceptedAgreements[collab.id] = val ?? false;
                          });
                        },
                        activeColor: const Color(0xFFFC4402),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'I ACCEPT THE ',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: 'Working Agreement',
                              style: const TextStyle(color: Color(0xFFFC4402)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: (_isProcessingPayment || !isAccepted) ? null : () => _handlePayment(collab),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC4402),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessingPayment 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Secure Pay ₹${collab.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      } else {
        return _buildStatusWait('WAITING FOR BRAND PAYMENT');
      }
    }

    if (['paid', 'revision_requested', 'delivered'].contains(collab.status)) {
      if (isCreator) {
        return ElevatedButton(
          onPressed: () => _handleDeliver(collab),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFC4402),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(collab.status == 'delivered' ? 'Update Work' : 'Submit Deliverable', style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      } else if (collab.status == 'delivered') {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => _handleComplete(collab),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Accept & Finish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (collab.revisionCount < collab.maxRevisions)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleRevision(collab),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: const BorderSide(color: Color(0xFFF3E8FF)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Revision', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (collab.revisionCount < collab.maxRevisions) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDispute(collab),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFFEE2E2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        return _buildStatusWait('CREATOR IS WORKING');
      }
    }

    if (['completed', 'resolved'].contains(collab.status)) {
      final isClaimed = isCreator ? collab.creatorClaimed : collab.brandClaimed;
      final payout = collab.payoutRequests.firstWhere((p) => p.type == (isCreator ? 'creator_payout' : 'brand_refund'), orElse: () => const PayoutRequest(id: 0, amount: 0, type: '', status: ''));
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isCreator ? 'YOUR PAYOUT' : 'SETTLEMENT REFUND', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('₹${isCreator ? (collab.resolvedCreatorAmount ?? collab.creatorAmount) : (collab.resolvedRefundAmount ?? 0)}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
          ElevatedButton(
            onPressed: isClaimed ? null : () => _handleClaim(collab),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              disabledBackgroundColor: Colors.grey[200],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isClaimed 
                ? (payout.isPaid ? 'PAID' : 'PROCESSING') 
                : 'CLAIM NOW',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusWait(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(message, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
      ),
    );
  }

  // Action Handlers
  void _handleAccept(Collaboration collab) async {
    final res = await CollaborationService.acceptCollaboration(collab.id);
    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collaboration accepted!')));
      _loadData();
    }
  }

  void _handleReject(Collaboration collab) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Collaboration?'),
        content: const Text('Are you sure you want to decline this project request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await CollaborationService.rejectCollaboration(collab.id);
      if (res['success']) _loadData();
    }
  }

  void _handleDeliver(Collaboration collab) async {
    final picker = ImagePicker();
    final file = await picker.pickMedia(); // Handles both image and video
    if (file != null) {
      _showUploadProgress(collab, File(file.path));
    }
  }

  void _showUploadProgress(Collaboration collab, File file) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Uploading Deliverable...', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const LinearProgressIndicator(color: Color(0xFFFC4402)),
              const SizedBox(height: 32),
              Text('Please don\'t close the app.', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
    
    CollaborationService.submitDeliverable(collab.id, file, (progress) {
      // Could update progress bar if used a more complex state
    }).then((res) {
      Navigator.pop(context); // Close bottom sheet
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project delivered successfully!')));
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${res['message']}')));
      }
    });
  }

  Future<void> _handlePayment(Collaboration collab) async {
    setState(() => _isProcessingPayment = true);
    
    final res = await PaymentService.createPayUOrder(
      type: 'collaboration',
      collaborationId: collab.id,
      amount: collab.amount,
    );

    if (!mounted) return;
    setState(() => _isProcessingPayment = false);

    if (res['success'] == true) {
      final Map<String, dynamic> payuData = res['data'];
      
      // Launch the internal invisible browser checkout
      final bool? paymentSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayUWebViewScreen(payuData: payuData),
        ),
      );

      if (!mounted) return;

      if (paymentSuccess == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful!'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled or failed.')),
        );
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Unable to create payment session')),
       );
    }
  }

  void _handleComplete(Collaboration collab) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Delivery?'),
        content: const Text('This will release the payment to the creator and finalize the project.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Accept & Finish', style: TextStyle(color: Colors.green))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await CollaborationService.completeCollaboration(collab.id);
      if (res['success']) _loadData();
    }
  }

  void _handleRevision(Collaboration collab) {
    _showTextInputDialog(
      title: 'Request Revision',
      hint: 'Be specific about what needs to be changed...',
      onConfirm: (text) async {
        final res = await CollaborationService.requestRevision(collab.id, text);
        if (res['success']) _loadData();
      },
    );
  }

  void _handleDispute(Collaboration collab) {
    _showTextInputDialog(
      title: 'Raise Dispute',
      hint: 'Explain why you are rejecting this work...',
      onConfirm: (text) async {
        final res = await CollaborationService.rejectDelivery(collab.id, 'Work Unacceptable', text);
        if (res['success']) _loadData();
      },
    );
  }

  void _handleClaim(Collaboration collab) async {
    // Show bank selector
    final banks = await CollaborationService.getBankAccounts();
    if (banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a bank account first.')));
      _tabController.animateTo(1);
      return;
    }

    final selectedBank = await showModalBottomSheet<BankAccount>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Bank Account', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...banks.map((b) => ListTile(
              onTap: () => Navigator.pop(context, b),
              leading: const Icon(Icons.account_balance),
              title: Text(b.bankName),
              subtitle: Text(b.maskedAccountNumber),
              trailing: const Icon(Icons.chevron_right),
            )),
          ],
        ),
      ),
    );

    if (selectedBank != null) {
      final isCreator = collab.creatorId == _userId;
      final res = await CollaborationService.claimSettlement(collab.id, isCreator ? 'creator' : 'brand', selectedBank.id);
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim request submitted!')));
        _loadData();
      }
    }
  }

  void _openPreview(Collaboration collab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SecurePreviewScreen(collaboration: collab)),
    );
  }

  void _showTextInputDialog({required String title, required String hint, required Function(String) onConfirm}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                onConfirm(controller.text);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
