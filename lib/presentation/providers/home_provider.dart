// lib/presentation/providers/home_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../data/services/movie_service.dart';

class HomeProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  List<MovieModel> _trendingMovies = [];
  List<MovieModel> get trendingMovies => _trendingMovies;

  List<MovieModel> _trendingTV = [];
  List<MovieModel> get trendingTV => _trendingTV;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MovieModel? get featuredItem => _trendingMovies.isNotEmpty ? _trendingMovies.first : null;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch both in parallel for performance
      final results = await Future.wait([
        _movieService.getTrendingMovies(),
        _movieService.getTrendingTV(),
      ]);

      _trendingMovies = results[0];
      _trendingTV = results[1];
      print('DEBUG: Successfully fetched ${_trendingMovies.length} movies and ${_trendingTV.length} TV shows.');
    } catch (e) {
      print('Home Init Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
