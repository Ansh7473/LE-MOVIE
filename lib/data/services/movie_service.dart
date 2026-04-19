// lib/data/services/movie_service.dart

import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import '../models/tv_details_model.dart';
import '../models/stream_model.dart';

class MovieService {
  final Dio _dio = Dio();

  // Base URLs
  static const String _tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String _searchUrl = 'https://api.themoviedb.org/3/search/multi';
  static const String _streamBaseUrl = 'https://multilang-api.rgshows.ru';
  static const String _apiKey = '4c1eef5a8d388386187a3426bc2345be';

  // Helper for spoofing headers (still used for streams)
  Options _getOptions(String url) {
    String referer = 'https://www.rgshows.ru/';
    String origin = 'https://www.rgshows.ru';
    
    if (url.contains('videasy')) {
      referer = 'https://player.videasy.net/';
      origin = 'https://player.videasy.net';
    }

    return Options(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',
        'Referer': referer,
        'Origin': origin,
        'Accept': 'application/json, text/plain, */*',
      },
    );
  }

  // 1. Smart Search Suggestions
  Future<List<MovieModel>> searchItems(String query) async {
    try {
      final response = await _dio.get(
        _searchUrl, 
        queryParameters: {'api_key': _apiKey, 'query': query, 'language': 'en'},
      );
      
      final List results = response.data['results'] ?? [];
      return results.map((item) => MovieModel.fromJson(item)).toList();
    } catch (e) {
      print('Search Error: $e');
      return [];
    }
  }

  // 2. TV Show Details
  Future<TVDetailsModel?> getTVDetails(int id) async {
    try {
      final url = '$_tmdbBaseUrl/tv/$id';
      final response = await _dio.get(url, queryParameters: {'api_key': _apiKey});
      return TVDetailsModel.fromJson(response.data);
    } catch (e) {
      print('TV Details Error: $e');
      return null;
    }
  }

  // 3. Episodes per Season
  Future<List<EpisodeModel>> getSeasonEpisodes(int tvId, int seasonNum) async {
    try {
      final url = '$_tmdbBaseUrl/tv/$tvId/season/$seasonNum';
      final response = await _dio.get(url, queryParameters: {'api_key': _apiKey});
      final List episodes = response.data['episodes'] ?? [];
      return episodes.map((e) => EpisodeModel.fromJson(e)).toList();
    } catch (e) {
      print('Episodes Error: $e');
      return [];
    }
  }

  // 4. Streaming Links
  Future<List<StreamModel>> getStreams(int id, int season, int episode) async {
    try {
      final path = (season == 0 && episode == 0) 
          ? '$_streamBaseUrl/movie/$id' 
          : '$_streamBaseUrl/tv/$id/$season/$episode';
          
      final response = await _dio.get(path, options: _getOptions(path));
      final List results = response.data['streams'] ?? [];
      
      return results.map((s) {
        final stream = StreamModel.fromJson(s);
        final bool isIframe = stream.url.contains('vidsrc') || 
                            stream.url.contains('player') || 
                            !stream.url.contains('.m3u8');
        
        return StreamModel(
          language: stream.language,
          url: stream.url,
          headers: stream.headers,
          isIframe: isIframe,
        );
      }).toList();
    } catch (e) {
      print('Stream Error: $e');
      return [];
    }
  }

  // 5. Trending Movies
  Future<List<MovieModel>> getTrendingMovies() async {
    try {
      final url = '$_tmdbBaseUrl/trending/movie/week';
      final response = await _dio.get(
        url, 
        queryParameters: {'api_key': _apiKey, 'language': 'en'},
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Trending Movies Error: $e');
      return [];
    }
  }

  // 6. Trending TV Shows
  Future<List<MovieModel>> getTrendingTV() async {
    try {
      final url = '$_tmdbBaseUrl/trending/tv/week';
      final response = await _dio.get(
        url, 
        queryParameters: {'api_key': _apiKey, 'language': 'en'},
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Trending TV Error: $e');
      return [];
    }
  }

  // 7. Movie Details
  Future<MovieModel?> getMovieDetails(int id) async {
    try {
      final url = '$_tmdbBaseUrl/movie/$id';
      final response = await _dio.get(url, queryParameters: {'api_key': _apiKey});
      return MovieModel.fromJson(response.data);
    } catch (e) {
      print('Movie Details Error: $e');
      return null;
    }
  }
}
