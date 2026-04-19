// lib/presentation/providers/search_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../data/services/movie_service.dart';

class SearchProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();
  
  List<MovieModel> _suggestions = [];
  List<MovieModel> get suggestions => _suggestions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Timer? _debounce;

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _isLoading = true;
      notifyListeners();

      _suggestions = await _movieService.searchItems(query);
      
      _isLoading = false;
      notifyListeners();
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    _suggestions = [];
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
