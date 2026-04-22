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
        // Smart Redirect Blocking for Windows (Global)
        if (url == 'about:blank' || url.isEmpty) return;
        
        final currentUri = Uri.parse(widget.stream.url);
        final newUri = Uri.parse(url);
        
        // 1. ALWAYS ALLOW: Same host
        if (newUri.host == currentUri.host) return;

        // 2. ALLOW: Verified Streaming Infrastructure
        final allowedDomains = [
          'tmdb.org', 'cloudflare.com', 'videasy.net', 'vidsrc.wtf', 
          'vidsrc.to', 'vidsrc.me', 'vidsrc.vip', 'vidlink.pro',
          'vidbox.to', 'vidbox.cc', 'vidbox.dev', 'vidplus.to',
          'rgshows.ru', 'anixtv.in', 'boomboxapp.in', 'google.com',
          'gstatic.com', 'akamaized.net', 'm3u8', 'ts'
        ];

        // 3. BLACKLIST: Known ad networks
        final blacklist = [
          'adsterra', 'admaven', 'popads', 'onclickads', 'tracking',
          'doubleclick', 'analytics', 'ads', 'promo', 'offer'
        ];

        bool isBlacklisted = blacklist.any((pattern) => url.toLowerCase().contains(pattern));
        bool isAllowed = allowedDomains.any((domain) => url.contains(domain)) ||
                         url.contains('player') || 
                         url.contains('embed');

        if (isBlacklisted || !isAllowed) {
          debugPrint('WINDOWS GLOBAL REDIRECT BLOCKED: $url');
          _controller!.loadUrl(widget.stream.url); // Force back to player
        }
      });

      // Inject ultimate popup blocker into Windows WebView
      await _controller!.executeScript('''
        window.open = function() { return null; };
        window.alert = function() { return true; };
        window.confirm = function() { return true; };
        document.addEventListener('click', function(e) {
          var target = e.target;
          while (target && target.tagName !== 'A') {
            target = target.parentNode;
          }
          if (target && target.tagName === 'A' && target.target === '_blank') {
            target.target = '_self';
          }
        }, true);
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
