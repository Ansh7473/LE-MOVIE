// lib/data/services/movie_service.dart

import 'package:dio/dio.dart';
import '../models/movie_model.dart';
import '../models/tv_details_model.dart';
import '../models/stream_model.dart';

class MovieService {
  final Dio _dio = Dio();

  // ─── New Endpoints (fmovies infrastructure) ────────────────────────────────
  static const String _contentBaseUrl = 'https://db.videasy.net/3';
  static const String _apiKey = '4c1eef5a8d388386187a3426bc2345be';

  // vidsrc.wtf embed URL builders
  static String movieEmbedUrl(int id) =>
      'https://www.vidsrc.wtf/api/1/movie/?id=$id&color=215fb3';

  static String tvEmbedUrl(int id, int season, int episode) =>
      'https://www.vidsrc.wtf/api/1/tv/?id=$id&s=$season&e=$episode&color=215fb3';

  // ─── Headers (extracted exactly from HTTP Toolkit HAR capture) ─────────────

  // Used for all db.videasy.net content API calls
  // Matches the actual cross-site fetch that ww2-fmovies.com sends
  Options get _contentOptions => Options(headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',
        'sec-ch-ua':
            '"Google Chrome";v="147", "Not.A/Brand";v="8", "Chromium";v="147"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'Accept': '*/*',
        'Origin': 'https://ww2-fmovies.com',
        'Referer': 'https://ww2-fmovies.com/',
        'Sec-Fetch-Site': 'cross-site',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Dest': 'empty',
      });

  // Used when the player page itself makes internal requests to vidsrc.wtf
  Options get _vidsrcOptions => Options(headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36',
        'sec-ch-ua':
            '"Google Chrome";v="147", "Not.A/Brand";v="8", "Chromium";v="147"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'Accept': '*/*',
        'Origin': 'https://www.vidsrc.wtf',
        'Referer': 'https://www.vidsrc.wtf/',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Storage-Access': 'active',
      });

  // ─── 1. Smart Search ───────────────────────────────────────────────────────
  Future<List<MovieModel>> searchItems(String query) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/search/multi',
        queryParameters: {'api_key': _apiKey, 'query': query},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((item) => MovieModel.fromJson(item)).toList();
    } catch (e) {
      print('Search Error: $e');
      return [];
    }
  }

  // ─── 2. TV Show Details ────────────────────────────────────────────────────
  Future<TVDetailsModel?> getTVDetails(int id) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/tv/$id',
        queryParameters: {'api_key': _apiKey},
        options: _contentOptions,
      );
      return TVDetailsModel.fromJson(response.data);
    } catch (e) {
      print('TV Details Error: $e');
      return null;
    }
  }

  // ─── 3. Episodes per Season ────────────────────────────────────────────────
  Future<List<EpisodeModel>> getSeasonEpisodes(int tvId, int seasonNum) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/tv/$tvId/season/$seasonNum',
        queryParameters: {'api_key': _apiKey},
        options: _contentOptions,
      );
      final List episodes = response.data['episodes'] ?? [];
      return episodes.map((e) => EpisodeModel.fromJson(e)).toList();
    } catch (e) {
      print('Episodes Error: $e');
      return [];
    }
  }

  // ─── 4. Streaming Links (All embed APIs) ──────────────────────────────────
  // Returns a list with multiple server options using various TMDB embed APIs
  Future<List<StreamModel>> getStreams(int id, int season, int episode) async {
    try {
      final bool isMovie = season == 0 && episode == 0;
      final List<StreamModel> streams = [];

      void addServer(String name, String movieUrl, String tvUrl) {
        streams.add(StreamModel(
          language: name,
          url: isMovie ? movieUrl : tvUrl,
          headers: {'Referer': 'https://ww2-fmovies.com/'},
          isIframe: true,
        ));
      }

      // Hardcoded server list extracted directly from ww2-fmovies.com frontend JS
      addServer(
        'UltraBox',
        'https://player.vidplus.to/embed/movie/$id',
        'https://player.vidplus.to/embed/tv/$id/$season/$episode',
      );
      addServer(
        'HyperLink (vidsrc 1)',
        'https://vidsrc.wtf/api/1/movie/?id=$id&color=215fb3',
        'https://vidsrc.wtf/api/1/tv/?id=$id&s=$season&e=$episode&color=215fb3',
      );
      addServer(
        'CloudBox',
        'https://vidify.top/embed/movie/$id',
        'https://vidify.top/embed/tv/$id/$season/$episode',
      );
      addServer(
        'UpCloud (vidsrc.co)',
        'https://player.vidsrc.co/embed/movie/$id',
        'https://player.vidsrc.co/embed/tv/$id/$season/$episode',
      );
      addServer(
        'NexaStream (vidsrc 2)',
        'https://vidsrc.wtf/api/2/movie/?id=$id&color=215fb3',
        'https://vidsrc.wtf/api/2/tv/?id=$id&s=$season&e=$episode&color=215fb3',
      );
      addServer(
        'StreamVault',
        'https://hexa.watch/watch/movie/$id',
        'https://hexa.watch/watch/tv/$id/$season/$episode',
      );
      addServer(
        'MediaHub',
        'https://spencerdevs.xyz/movie/$id?theme=215fb3',
        'https://spencerdevs.xyz/tv/$id/$season/$episode?theme=215fb3',
      );
      addServer(
        'CloudPlay (vidsrc.cc)',
        'https://vidsrc.cc/v2/embed/movie/$id',
        'https://vidsrc.cc/v2/embed/tv/$id/$season/$episode',
      );
      addServer(
        'StreamBoxHD',
        'https://test.autoembed.cc/embed/movie/$id',
        'https://test.autoembed.cc/embed/tv/$id/$season/$episode',
      );
      addServer(
        'MovieVault',
        'https://rivestream.org/embed?type=movie&id=$id',
        'https://rivestream.org/embed?type=tv&id=$id&s=$season&e=$episode',
      );

      return streams;
    } catch (e) {
      print('Stream Error: $e');
      return [];
    }
  }

  // ─── 5. Trending Movies ────────────────────────────────────────────────────
  Future<List<MovieModel>> getTrendingMovies() async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/trending/movie/week',
        queryParameters: {'api_key': _apiKey, 'language': 'en'},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Trending Movies Error: $e');
      return [];
    }
  }

  // ─── 6. Trending TV Shows ──────────────────────────────────────────────────
  Future<List<MovieModel>> getTrendingTV() async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/trending/tv/week',
        queryParameters: {'api_key': _apiKey, 'language': 'en'},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Trending TV Error: $e');
      return [];
    }
  }

  // ─── 7. Movie Details ──────────────────────────────────────────────────────
  Future<MovieModel?> getMovieDetails(int id) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/movie/$id',
        queryParameters: {'api_key': _apiKey},
        options: _contentOptions,
      );
      return MovieModel.fromJson(response.data);
    } catch (e) {
      print('Movie Details Error: $e');
      return null;
    }
  }
}
