// lib/presentation/pages/windows_player_real.dart
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart' as win;
import 'dart:io' show Platform;
import '../../data/models/stream_model.dart';

class WindowsPlayer extends StatefulWidget {
  final StreamModel stream;
  const WindowsPlayer({super.key, required this.stream});

  @override
  State<WindowsPlayer> createState() => _WindowsPlayerState();
}

class _WindowsPlayerState extends State<WindowsPlayer> {
  win.WebviewController? _controller;
  bool _isReady = false;
  bool _isSupported = false;

  @override
  void initState() {
    super.initState();
    _isSupported = Platform.isWindows;
    if (_isSupported) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      _controller = win.WebviewController();
      await _controller!.initialize();
      await _controller!.setBackgroundColor(Colors.black);
      await _controller!.loadUrl(widget.stream.url);
      
      // Smart Redirect Blocking for Windows
      _controller!.url.listen((url) {
        if (url == 'about:blank' || url.isEmpty) return;
        
        final currentUri = Uri.parse(widget.stream.url);
        final newUri = Uri.parse(url);
        
        // If the host changes to something unrelated, it's likely a redirect
        if (newUri.host.isNotEmpty && 
            newUri.host != currentUri.host && 
            !url.contains('player') && 
            !url.contains('embed') &&
            !url.contains('rgshows.ru') &&
            !url.contains('vidlink.pro')) {
          debugPrint('WINDOWS REDIRECT BLOCKED: $url');
          _controller!.loadUrl(widget.stream.url); // Force back to player
        }
      });

      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      debugPrint('Windows WebView Initialization Error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) return const SizedBox.shrink();
    
    return _isReady 
      ? win.Webview(_controller!) 
      : const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
  }
}
