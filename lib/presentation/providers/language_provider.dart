import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguageCode = 'en-US';

  String get currentLanguageCode => _currentLanguageCode;

  void setLanguage(String code) {
    if (_currentLanguageCode != code) {
      _currentLanguageCode = code;
      notifyListeners();
    }
  }
}
