// lib/presentation/pages/player_page_web.dart
// Web-only iframe registration — only imported on web builds

// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void registerIframeFactory(String viewId, String url) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) => html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..allowFullscreen = true
      ..setAttribute('sandbox',
          'allow-scripts allow-same-origin allow-forms allow-presentation'),
  );
}
