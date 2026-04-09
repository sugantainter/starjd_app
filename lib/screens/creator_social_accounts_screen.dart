import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import 'creator_analytics_detail_screen.dart';

class CreatorSocialAccountsScreen extends StatefulWidget {
  const CreatorSocialAccountsScreen({super.key});

  @override
  State<CreatorSocialAccountsScreen> createState() => _CreatorSocialAccountsScreenState();
}

class _CreatorSocialAccountsScreenState extends State<CreatorSocialAccountsScreen> {
  bool _isLoading = true;
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final res = await CreatorDashboardService.getSocialAccounts();
    if (mounted) {
      setState(() {
        if (res['success']) {
          _accounts = res['data'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _showConnectDialog(dynamic account) async {
    final usernameController = TextEditingController(text: account['username'] ?? '');
    final urlController = TextEditingController(text: account['profile_url'] ?? '');
    final followersController = TextEditingController(text: account['followers_count']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            _buildPlatformIcon(account['platform'], size: 28),
            const SizedBox(width: 12),
            Text('Connect ${account['platform'].toString().toUpperCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: _inputDecoration('Username / Handle', hint: 'e.g. @johndoe'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: _inputDecoration('Profile URL', hint: 'https://...'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: followersController,
                decoration: _inputDecoration('Followers Count', hint: 'e.g. 5000'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your details manualy to showcase on your profile.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'platform': account['platform'],
                'username': usernameController.text.trim(),
                'profile_url': urlController.text.trim(),
                'followers_count': int.tryParse(followersController.text) ?? 0,
              };
              final res = await CreatorDashboardService.syncSocialAccount(data);
              if (res['success']) {
                if (mounted) Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _loadData();
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _disconnect(String platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account'),
        content: Text('Are you sure you want to remove your $platform account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      final res = await CreatorDashboardService.disconnectSocialAccount(platform);
      if (res['success']) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Social Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _accounts.length,
            itemBuilder: (context, index) {
              final acc = _accounts[index];
              return _buildSocialCard(acc);
            },
          ),
    );
  }

  Widget _buildSocialCard(dynamic acc) {
    bool isConnected = acc['is_connected'] ?? false;
    String platform = acc['platform'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPlatformIcon(platform),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.toString().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isConnected) ...[
                      const SizedBox(height: 2),
                      Text(
                        acc['username'] ?? 'Connected',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else
                      Text(
                        'Not connected',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showConnectDialog(acc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? Colors.grey.shade100 : const Color(0xFFE63946),
                  foregroundColor: isConnected ? Colors.black87 : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(80, 36),
                ),
                child: Text(isConnected ? 'Edit' : 'Connect', style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          if (isConnected) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (acc['followers_count'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Followers',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        acc['followers_count'].toString(),
                        style: const TextStyle(color: Color(0xFFE63946), fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFFE63946), size: 20),
                      onPressed: () => _refreshStats(platform),
                      tooltip: 'Refresh Stats',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => CreatorAnalyticsDetailScreen(accountData: acc)
                          )
                        );
                      },
                      label: const Text('Analytics', style: TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.bold, fontSize: 13)),
                      icon: const Icon(Icons.analytics_outlined, color: Color(0xFFE63946), size: 18),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.link_off, color: Colors.grey, size: 20),
                      onPressed: () => _disconnect(platform),
                      tooltip: 'Disconnect',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshStats(String platform) async {
    setState(() => _isLoading = true);
    final res = await CreatorDashboardService.refreshSocialAccountStats(platform);
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    if (res['success']) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$platform analytics updated live!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh: ${res['message']}')),
      );
    }
  }

  Widget _buildPlatformIcon(String platform, {double size = 40}) {
    IconData icon;
    Color color;
    
    switch (platform.toLowerCase()) {
      case 'instagram':
        icon = Icons.camera_alt;
        color = Colors.pink;
        break;
      case 'youtube':
        icon = Icons.play_circle_fill;
        color = Colors.red;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.blue.shade800;
        break;
      case 'tiktok':
        icon = Icons.music_note;
        color = Colors.black;
        break;
      case 'linkedin':
        icon = Icons.link;
        color = Colors.blue.shade700;
        break;
      case 'pinterest':
        icon = Icons.grid_view_rounded;
        color = const Color(0xFFE60023);
        break;
      default:
        icon = Icons.language;
        color = Colors.grey;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }
}
