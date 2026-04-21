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
          const NavigationDelegate(),
        )
        ..loadRequest(Uri.parse(widget.stream.url))
        ..runJavaScript('''
          // Refined window.open blocker (Allows internal calls used by player menus)
          const originalOpen = window.open;
          window.open = function(url, name, specs) {
            if (!url || url === 'about:blank' || url === '') {
              return originalOpen.apply(window, arguments);
            }
            console.log('Blocked Popup to: ' + url);
            return null;
          };
          
          window.alert = function() { return true; };
          window.confirm = function() { return true; };
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
