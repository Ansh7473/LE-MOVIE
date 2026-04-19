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

  List<MovieModel> _popularMovies = [];
  List<MovieModel> get popularMovies => _popularMovies;

  List<MovieModel> _popularTV = [];
  List<MovieModel> get popularTV => _popularTV;

  List<Map<String, dynamic>> _movieGenres = [];
  List<Map<String, dynamic>> get movieGenres => _movieGenres;

  List<Map<String, dynamic>> _tvGenres = [];
  List<Map<String, dynamic>> get tvGenres => _tvGenres;

  List<MovieModel> _genreResults = [];
  List<MovieModel> get genreResults => _genreResults;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingCategory = false;
  bool get isLoadingCategory => _isLoadingCategory;

  String _currentLanguage = 'en-US';

  MovieModel? get featuredItem => _trendingMovies.isNotEmpty ? _trendingMovies.first : null;

  Future<void> init(String language) async {
    _currentLanguage = language;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _movieService.getTrendingMovies(language: language),
        _movieService.getTrendingTV(language: language),
      ]);

      _trendingMovies = results[0];
      _trendingTV = results[1];
    } catch (e) {
      print('Home Init Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMovies() async {
    if (_popularMovies.isNotEmpty) return;
    _isLoadingCategory = true;
    notifyListeners();
    _popularMovies = await _movieService.getPopularMovies(language: _currentLanguage);
    _isLoadingCategory = false;
    notifyListeners();
  }

  Future<void> loadSeries() async {
    if (_popularTV.isNotEmpty) return;
    _isLoadingCategory = true;
    notifyListeners();
    _popularTV = await _movieService.getPopularTV(language: _currentLanguage);
    _isLoadingCategory = false;
    notifyListeners();
  }

  Future<void> loadGenres() async {
    if (_movieGenres.isNotEmpty) return;
    _isLoadingCategory = true;
    notifyListeners();
    
    final results = await Future.wait([
      _movieService.getGenres(false, language: _currentLanguage),
      _movieService.getGenres(true, language: _currentLanguage),
    ]);
    
    _movieGenres = results[0];
    _tvGenres = results[1];
    _isLoadingCategory = false;
    notifyListeners();
  }

  Future<void> selectGenre(int genreId, bool isTv) async {
    _isLoadingCategory = true;
    notifyListeners();
    _genreResults = await _movieService.getDiscoverByGenre(isTv, genreId, language: _currentLanguage);
    _isLoadingCategory = false;
    notifyListeners();
  }
}
