import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PayUWebViewScreen extends StatefulWidget {
  final Map<String, dynamic> payuData;

  const PayUWebViewScreen({super.key, required this.payuData});

  @override
  State<PayUWebViewScreen> createState() => _PayUWebViewScreenState();
}

class _PayUWebViewScreenState extends State<PayUWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final params = widget.payuData['params'] ?? {};
    final payuUrl = (widget.payuData['payment_url'] ?? '').toString();

    if (payuUrl.isEmpty) {
      // Safeguard for unexpected empty URLs
      Future.delayed(Duration.zero, () {
        if (mounted) Navigator.pop(context, false);
      });
      return;
    }

    String html = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Secure Payment</title>
          <style>
             body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: white; }
             h2 { color: #333; }
             .loader { border: 4px solid #f3f3f3; border-top: 4px solid #10b981; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 20px auto; }
             @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
          </style>
        </head>
        <body onload="document.forms[0].submit()">
        <div style="text-align:center;">
          <div class="loader"></div>
          <h2>Redirecting to Secure Payment...</h2>
          <p style="color:#666;">Please do not refresh or close this screen.</p>
        </div>
        <form method="post" action="$payuUrl">
    ''';
    
    (params as Map<String, dynamic>).forEach((key, value) {
      if (value != null) {
        String safeVal = value.toString().replaceAll('"', '&quot;');
        html += '<input type="hidden" name="$key" value="$safeVal" />\n';
      }
    });

    html += '''
          </form>
        </body>
      </html>
    ''';

    final String contentBase64 = base64Encode(const Utf8Encoder().convert(html));

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            final lowUrl = url.toLowerCase();

            // Handle UPI and other common payment app schemes
            if (lowUrl.startsWith('upi://') || 
                lowUrl.startsWith('tez://') || 
                lowUrl.startsWith('phonepe://') || 
                lowUrl.startsWith('paytmmp://')) {
              try {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                debugPrint('Error launching payment app: $e');
              }
              return NavigationDecision.prevent;
            }

            // StarJD generic backend URL redirects containing the callback result
            if (lowUrl.contains('/payment/result') && lowUrl.contains('status=success')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            } else if (lowUrl.contains('/payment/result') && lowUrl.contains('status=failed')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('data:text/html;base64,$contentBase64'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
             const Center(child: CircularProgressIndicator(color: Color(0xFF10b981))),
        ],
      ),
    );
  }
}
