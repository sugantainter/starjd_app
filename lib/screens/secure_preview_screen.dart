import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/collaboration.dart';
import '../services/collaboration_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class SecurePreviewScreen extends StatefulWidget {
  final Collaboration collaboration;

  const SecurePreviewScreen({super.key, required this.collaboration});

  @override
  State<SecurePreviewScreen> createState() => _SecurePreviewScreenState();
}

class _SecurePreviewScreenState extends State<SecurePreviewScreen> {
  bool _isLoading = true;
  String? _error;
  String? _previewUrl;
  String? _previewType;
  Map<String, String>? _authHeaders;
  
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final res = await CollaborationService.getFilePreview(widget.collaboration.id);
    if (!mounted) return;

    if (res['success']) {
      final data = res['data'];
      
      // If the backend says the preview isn't ready (transcoding in progress)
      if (data['ready'] == false) {
        setState(() {
          _isLoading = false;
          _error = 'Processing Preview: A high-quality watermarked preview is being prepared for this video. Please check back in 1-2 minutes.';
        });
        return;
      }

      final token = data['preview_token'];
      final baseUrl = data['url']; // Should be /api/collaborations/{id}/file/stream
      final fullUrl = 'https://www.starjd.com$baseUrl?preview_token=$token';
      
       final ext = widget.collaboration.deliverableContent?.split('.').last.toLowerCase() ?? '';
       final type = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext) ? 'image' : (ext == 'pdf' ? 'pdf' : 'video');
 
       final headers = await AuthService.getHeaders();

       setState(() {
         _previewUrl = fullUrl;
         _previewType = type;
         _authHeaders = headers;
       });

      if (type == 'video') {
        _initVideo(fullUrl);
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = res['message'];
      });
    }
  }

  void _initVideo(String url) async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: _authHeaders ?? {},
    );
    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: const Center(child: CircularProgressIndicator()),
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFFC4402),
          handleColor: const Color(0xFFFC4402),
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load video preview.';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          if (widget.collaboration.status == 'completed' || widget.collaboration.status == 'resolved')
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _handleDownload,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFC4402)))
          : _error != null
              ? _buildError()
              : _buildPreview(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white30),
            const SizedBox(height: 24),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        Center(
          child: _previewType == 'image'
              ? CachedNetworkImage(
                  imageUrl: _previewUrl!,
                  httpHeaders: _authHeaders,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : _previewType == 'video'
                  ? (_chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator())
                  : const Text('PDF Preview not yet supported on mobile.', style: TextStyle(color: Colors.white)),
        ),
        
        // Watermark Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.1,
              child: Center(
                child: RotationTransition(
                  turns: const AlwaysStoppedAnimation(-30 / 360),
                  child: Text(
                    'STARJD PREVIEW',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Modal Footer Hint
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 12, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'SECURE PREVIEW MODE',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDownload() async {
    final res = await CollaborationService.getFilePreview(widget.collaboration.id, intent: 'download');
    if (res['success']) {
      final data = res['data'];
      final token = data['preview_token'];
      final baseUrl = data['url'];
      final downloadUrl = 'https://www.starjd.com$baseUrl?preview_token=$token&download=1';
      
      final String fileName = widget.collaboration.deliverableContent?.split('/').last ?? 'project_deliverable_${widget.collaboration.id}.zip';
      
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
        // Trigger system local notification
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
}
