import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/auth_service.dart';

class SocialAuthWebview extends StatefulWidget {
  final String providerUrl;
  final String title;
  final VoidCallback onSuccess;

  const SocialAuthWebview({
    super.key,
    required this.providerUrl,
    required this.title,
    required this.onSuccess,
  });

  @override
  State<SocialAuthWebview> createState() => _SocialAuthWebviewState();
}

class _SocialAuthWebviewState extends State<SocialAuthWebview> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkUrlForCompletion(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkUrlForCompletion(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.providerUrl));
  }

  void _checkUrlForCompletion(String url) async {
    // Check for social accounts connection success
    if (url.contains('success=connected')) {
      if (mounted) widget.onSuccess();
      return;
    }
    if (url.contains('error=')) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // If the Laravel backend redirects successfully, it will probably return back to a profile, dashboard, or home page.
    // E.g. http://10.0.2.2:8000/api/auth/google/callback or http://10.0.2.2:8000/
    if (url.contains('/api/auth/') && url.contains('/callback')) {
      // It's hitting the callback. We let it finish so cookies are set.
      return;
    }
    
    // Check if the user is authenticated by trying to fetch their profile
    // after a redirect occurs away from the authentication screens
    if (!url.contains('accounts.google.com') && !url.contains('facebook.com') && !url.contains('redirect') && !url.contains('webview-login')) {
      bool isLoggedIn = await AuthService.checkAuthStatus();
      if (isLoggedIn && mounted) {
        widget.onSuccess(); // Close the bottom sheet and trigger redirect
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
