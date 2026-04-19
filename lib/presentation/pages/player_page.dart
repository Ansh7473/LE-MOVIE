// lib/presentation/pages/player_page.dart

import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import '../../data/models/stream_model.dart';
import 'package:flutter/foundation.dart';

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
  void _initializeIframePlayer() {
    if (kIsWeb) {
      // WEB: Register sandboxed iframe
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'iframe-player-${widget.stream.url}',
        (int viewId) => html.IFrameElement()
          ..src = widget.stream.url
          ..style.border = 'none'
          ..allowFullscreen = true
          ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms allow-presentation'), 
          // CRITICAL: We omit 'allow-popups' to block tab-redirects
      );
    } else {
      // MOBILE: Initialize webview_flutter with redirect block
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              // Only allow the original URL or safe resources
              if (request.url.contains(widget.stream.url) || request.url.contains('player')) {
                return NavigationDecision.navigate;
              }
              print('BLOCKED REDIRECT: ${request.url}');
              return NavigationDecision.prevent; // HARD BLOCK Redirects
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.stream.url));
    }
    setState(() {});
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
    } else {
      return _webViewController != null 
          ? WebViewWidget(controller: _webViewController!)
          : const CircularProgressIndicator(color: Color(0xFFE50914));
    }
  }
}
