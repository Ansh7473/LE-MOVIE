// lib/data/models/stream_model.dart

class StreamModel {
  final String language;
  final String url;
  final Map<String, String> headers;
  final bool isIframe;

  StreamModel({
    required this.language,
    required this.url,
    required this.headers,
    this.isIframe = false,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      language: json['language'] ?? 'Unknown',
      url: json['url'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      isIframe: json['is_iframe'] ?? false,
    );
  }
}
