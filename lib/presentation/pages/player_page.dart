// lib/presentation/pages/player_page.dart

import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'windows_player_stub.dart'
    if (dart.library.io) 'windows_player_real.dart';
import '../../data/models/stream_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Process, Platform;

// Conditional import: loads web iframe helper on web, no-op stub on mobile
import 'player_page_stub.dart'
    if (dart.library.html) 'player_page_web.dart';

class PlayerPage extends StatefulWidget {
  final StreamModel stream;
  const PlayerPage({super.key, required this.stream});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  // Native Player State
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // WebView State (Mobile)
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (widget.stream.isIframe) {
      _initializeIframePlayer();
    } else {
      _initializeNativePlayer();
    }
  }

  // --- Hybrid Logic A: Native HLS Player ---
  Future<void> _initializeNativePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.stream.url),
      httpHeaders: widget.stream.headers,
    );

    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFE50914),
        handleColor: const Color(0xFFE50914),
      ),
    );
    setState(() {});
  }

  // --- Hybrid Logic B: Hardened WebView Player ---
  void _initializeIframePlayer() async {
    if (kIsWeb) {
      // WEB: Register sandboxed iframe via conditional import
      registerIframeFactory(
        'iframe-player-${widget.stream.url}',
        widget.stream.url,
      );
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      // WINDOWS: Handled by WindowsPlayer widget via conditional import
    } else {
      // MOBILE: Initialize webview_flutter with redirect block
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              final allowedDomains = [
                'tmdb.org', 'cloudflare.com', 'videasy.net', 'vidsrc.wtf', 
                'vidsrc.to', 'vidsrc.me', 'vidsrc.vip', 'vidlink.pro',
                'vidbox.to', 'vidbox.cc', 'vidbox.dev', 'vidplus.to',
                'rgshows.ru', 'anixtv.in', 'boomboxapp.in', 'google.com',
                'gstatic.com', 'akamaized.net', 'm3u8', 'ts'
              ];

              bool isAllowed = allowedDomains.any((domain) => request.url.contains(domain)) ||
                               request.url.contains('player') || 
                               request.url.contains('embed') ||
                               request.url.startsWith('blob:') ||
                               request.url.startsWith('data:') ||
                               request.url.startsWith('about:blank');

              // 4. BLACKLIST: Known ad networks and malicious patterns
              final blacklist = [
                'adsterra', 'admaven', 'popads', 'onclickads', 'tracking',
                'doubleclick', 'analytics', 'ads', 'promo', 'offer'
              ];
              
              bool isBlacklisted = blacklist.any((pattern) => request.url.toLowerCase().contains(pattern));
              
              if (isBlacklisted) {
                debugPrint('BLACKLISTED REDIRECT BLOCKED: ${request.url}');
                return NavigationDecision.prevent;
              }

              if (isAllowed) return NavigationDecision.navigate;

              // 5. BLOCK EVERYTHING ELSE
              debugPrint('BLOCKED REDIRECT: ${request.url}');
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.stream.url))
        ..runJavaScript('''
          // Ultimate window.open and popup blocker
          window.open = function() { return null; };
          window.alert = function() { return true; };
          window.confirm = function() { return true; };
          
          // Focus Lock: If an ad tries to open a popup, focus back immediately
          window.addEventListener('blur', function() {
            setTimeout(function() { window.focus(); }, 1);
          });
          
          // Disable any target="_blank" links dynamically
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
    }
    setState(() {});
  }

  Future<void> _launchInBrowser(String url) async {
    try {
      // Standard Windows command to open a URL in default browser
      await Process.run('start', [url], runInShell: true);
    } catch (e) {
      print('Windows Browser Launch Error: $e');
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: widget.stream.isIframe 
          ? _buildIframeView()
          : _buildNativeView(),
      ),
    );
  }

  Widget _buildNativeView() {
    return _chewieController != null && 
           _chewieController!.videoPlayerController.value.isInitialized
        ? Chewie(controller: _chewieController!)
        : const CircularProgressIndicator(color: Color(0xFFE50914));
  }

  Widget _buildIframeView() {
    if (kIsWeb) {
      return HtmlElementView(viewType: 'iframe-player-${widget.stream.url}');
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return WindowsPlayer(stream: widget.stream);
    } else {
      return _webViewController != null 
          ? WebViewWidget(controller: _webViewController!)
          : const CircularProgressIndicator(color: Color(0xFFE50914));
    }
  }
}
