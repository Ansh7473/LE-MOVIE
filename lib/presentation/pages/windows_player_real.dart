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
      
      _controller!.url.listen((url) {
        // STRICT ISOLATION for Windows
        if (url == 'about:blank' || url.isEmpty) return;
        
        final initialHost = Uri.parse(widget.stream.url).host;
        final newUri = Uri.parse(url);
        
        // Only allow same-host navigation
        if (newUri.host != initialHost) {
          debugPrint('WINDOWS ISOLATED PLAYER BLOCKED REDIRECT: $url');
          _controller!.loadUrl(widget.stream.url); // Force back to player
        }
      });

      // Inject ultimate popup blocker heartbeat into Windows WebView
      await _controller!.executeScript('''
        (function() {
          function block() {
            window.open = function() { return null; };
            window.alert = function() { return true; };
            window.confirm = function() { return true; };
          }
          block();
          setInterval(block, 100); 
          document.addEventListener('click', function(e) {
            var target = e.target;
            while (target && target.tagName !== 'A') target = target.parentNode;
            if (target && target.tagName === 'A') target.target = '_self';
          }, true);
        })();
      ''');

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
