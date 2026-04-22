// lib/data/models/stream_model.dart

class StreamModel {
  final String language;
  final String url;
  final Map<String, String> headers;
  final bool isIframe;
  final bool isHindi;

  StreamModel({
    required this.language,
    required this.url,
    required this.headers,
    this.isIframe = false,
    this.isHindi = false,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      language: json['language'] ?? 'Unknown',
      url: json['url'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      isIframe: json['is_iframe'] ?? false,
      isHindi: json['is_hindi'] ?? false,
    );
  }
}
