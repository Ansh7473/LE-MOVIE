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
  Future<List<MovieModel>> searchItems(String query, {String language = 'en-US'}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/search/multi',
        queryParameters: {'api_key': _apiKey, 'query': query, 'language': language},
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
  Future<TVDetailsModel?> getTVDetails(int id, {String language = 'en-US'}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/tv/$id',
        queryParameters: {'api_key': _apiKey, 'language': language},
        options: _contentOptions,
      );
      final details = TVDetailsModel.fromJson(response.data);
      
      // Fetch IMDB ID for TV show
      try {
        final extResponse = await _dio.get(
          '$_contentBaseUrl/tv/$id/external_ids',
          queryParameters: {'api_key': _apiKey},
          options: _contentOptions,
        );
        return TVDetailsModel.fromJson({...response.data, 'imdb_id': extResponse.data['imdb_id']});
      } catch (_) {
        return details;
      }
    } catch (e) {
      print('TV Details Error: $e');
      return null;
    }
  }

  // ─── 3. Episodes per Season ────────────────────────────────────────────────
  Future<List<EpisodeModel>> getSeasonEpisodes(int tvId, int seasonNum, {String language = 'en-US'}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/tv/$tvId/season/$seasonNum',
        queryParameters: {'api_key': _apiKey, 'language': language},
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
  // Returns a list with multiple server options using various TMDB/IMDB embed APIs
  Future<List<StreamModel>> getStreams(int id, int season, int episode, {String? imdbId}) async {
    try {
      final bool isMovie = season == 0 && episode == 0;
      final List<StreamModel> streams = [];

      void addServer(String name, String movieUrl, String tvUrl, {Map<String, String>? customHeaders}) {
        streams.add(StreamModel(
          language: name,
          url: isMovie ? movieUrl : tvUrl,
          headers: customHeaders ?? {'Referer': 'https://ww2-fmovies.com/'},
          isIframe: true,
        ));
      }

      // ─── HINDI & MULTI-LANG SERVERS (TOP PRIORITY) ──────────────────────────
      const String themeColor = '00A8E1'; // Blue theme

      addServer(
        'VidZen (Hindi/Multi)',
        'https://anixtv.vidzen.fun/movie/$id',
        'https://anixtv.vidzen.fun/tv/$id/$season/$episode',
        customHeaders: {'Referer': 'https://anixtv.in/'},
      );

      addServer(
        'VidFast (Hindi Available)',
        'https://vidfast.pro/movie/$id?autoPlay=true&theme=$themeColor',
        'https://vidfast.pro/tv/$id/$season/$episode?autoPlay=true&theme=$themeColor',
        customHeaders: {'Referer': 'https://anixtv.in/'},
      );

      addServer(
        'Mapple (Premium/Hindi)',
        'https://mapple.uk/watch/movie/$id',
        'https://mapple.uk/watch/tv/$id-$season-$episode',
        customHeaders: {'Referer': 'https://www.boomboxapp.in/'},
      );

      addServer(
        'Vidify (Hindi/Premium)',
        'https://player.vidify.top/embed/movie/$id?primarycolor=$themeColor&autoplay=true&poster=true&server=hindi',
        'https://player.vidify.top/embed/tv/$id/$season/$episode?primarycolor=$themeColor&autoplay=true&poster=true&server=hindi',
        customHeaders: {'Referer': 'https://www.boomboxapp.in/'},
      );

      addServer(
        'VidPlus (Hindi/Premium)',
        'https://player.vidplus.to/embed/movie/$id?primarycolor=$themeColor&autoplay=true&poster=true&download=true&server=hindi',
        'https://player.vidplus.to/embed/tv/$id/$season/$episode?primarycolor=$themeColor&autoplay=true&poster=true&download=true&server=hindi',
        customHeaders: {'Referer': 'https://www.boomboxapp.in/'},
      );

      addServer(
        'RGShow 2 (Videasy-Hindi)',
        'https://rgshows.ru/player/movies/api2/index.html?id=$id&color=e01621',
        'https://rgshows.ru/player/series/api2/index.html?id=$id&s=$season&e=$episode&color=e01621',
        customHeaders: {'Referer': 'https://rgshows.ru/'},
      );

      addServer(
        'RGShow 3 (Multi-Lang-Hindi)',
        'https://rgshows.ru/player/movies/api3/index.html?id=$id&color=e01621',
        'https://rgshows.ru/player/series/api3/index.html?id=$id&s=$season&e=$episode&color=e01621',
        customHeaders: {'Referer': 'https://rgshows.ru/'},
      );

      addServer(
        'NexaStream (vidsrc 2-Hindi)',
        'https://vidsrc.wtf/api/2/movie/?id=$id&color=215fb3',
        'https://vidsrc.wtf/api/2/tv/?id=$id&s=$season&e=$episode&color=215fb3',
      );

      // ─── PREMIUM & FAST SERVERS (ENGLISH/GLOBAL) ──────────────────────────
      addServer(
        'VidBox (Premium)',
        'https://vidbox.to/watch/movie?id=$id',
        'https://vidbox.to/watch/tv?id=$id&s=$season&e=$episode',
        customHeaders: {
          'Referer': 'https://vidbox.to/',
          'Origin': 'https://vidbox.to',
        },
      );

      addServer(
        'VidSrc VIP (Fast)',
        'https://vidsrc.vip/embed/movie/$id',
        'https://vidsrc.vip/embed/tv/$id/$season/$episode',
        customHeaders: {'Referer': 'https://vidsrc.vip/'},
      );

      addServer(
        'VidSrc.to (Premium)',
        'https://vidsrc.to/embed/movie/$id',
        'https://vidsrc.to/embed/tv/$id/$season/$episode',
      );

      addServer(
        'VidCore (Fast)',
        'https://vidcore.net/movie/$id?autoPlay=true&theme=$themeColor&title=true&poster=true',
        'https://vidcore.net/tv/$id/$season/$episode?autoPlay=true&theme=$themeColor&nextButton=true&autoNext=true&title=true&poster=true',
        customHeaders: {'Referer': 'https://anixtv.in/'},
      );

      addServer(
        'VidPlays',
        'https://vidplays.fun/embed/movie/$id',
        'https://vidplays.fun/embed/tv/$id/$season/$episode',
        customHeaders: {'Referer': 'https://anixtv.in/'},
      );

      addServer(
        'VidPlus Anime (Premium)',
        'https://player.vidplus.to/embed/anime/$id/1?dub=true',
        'https://player.vidplus.to/embed/anime/$id/$episode?dub=true',
        customHeaders: {'Referer': 'https://player.vidplus.to/'},
      );

      // ─── FALLBACK & ADDITIONAL SERVERS ──────────────────────────────────
      addServer(
        'VidLink (Multi)',
        'https://vidlink.pro/movie/$id',
        'https://vidlink.pro/tv/$id/$season/$episode',
        customHeaders: {'Referer': 'https://vidlink.pro/'},
      );

      addServer(
        'VidNest',
        'https://vidnest.fun/movie/$id',
        'https://vidnest.fun/tv/$id/$season/$episode',
        customHeaders: {'Referer': 'https://anixtv.in/'},
      );

      addServer(
        'EmbedMaster',
        'https://embedmaster.link/movie/$id',
        'https://embedmaster.link/tv/$id/$season/$episode',
        customHeaders: {'Referer': 'https://anixtv.in/'},
      );

      addServer(
        'OniStream (Multi)',
        'https://onistream.vercel.app/embed/movie/$id',
        'https://onistream.vercel.app/embed/tv/$id/$season/$episode',
        customHeaders: {'Referer': 'https://www.boomboxapp.in/'},
      );

      addServer(
        'VidSrc.me (Direct)',
        'https://vidsrc.me/embed/movie?tmdb=$id',
        'https://vidsrc.me/embed/tv?tmdb=$id&s=$season&e=$episode',
      );

      addServer(
        'AutoEmbed (Direct)',
        'https://player.autoembed.cc/embed/movie/$id',
        'https://player.autoembed.cc/embed/tv/$id/$season/$episode',
      );

      addServer(
        '2Embed (Global)',
        'https://www.2embed.cc/embed/$id',
        'https://www.2embed.cc/embedtv/$id&s=$season&e=$episode',
      );

      addServer(
        'VidSrc WTF (v1)',
        'https://vidsrc.wtf/api/1/movie/?id=$id',
        'https://vidsrc.wtf/api/1/tv/?id=$id&s=$season&e=$episode',
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
  Future<List<MovieModel>> getTrendingMovies({String language = 'en-US'}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/trending/movie/week',
        queryParameters: {'api_key': _apiKey, 'language': language},
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
  Future<List<MovieModel>> getTrendingTV({String language = 'en-US'}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/trending/tv/week',
        queryParameters: {'api_key': _apiKey, 'language': language},
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
  Future<MovieModel?> getMovieDetails(int id, {String language = 'en-US'}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/movie/$id',
        queryParameters: {'api_key': _apiKey, 'language': language},
        options: _contentOptions,
      );
      return MovieModel.fromJson(response.data);
    } catch (e) {
      print('Movie Details Error: $e');
      return null;
    }
  }

  // ─── 8. Popular Movies and Series ──────────────────────────────────────────
  Future<List<MovieModel>> getPopularMovies({String language = 'en-US', int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/movie/popular',
        queryParameters: {'api_key': _apiKey, 'language': language, 'page': page},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Popular Movies Error: $e');
      return [];
    }
  }

  Future<List<MovieModel>> getPopularTV({String language = 'en-US', int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/tv/popular',
        queryParameters: {'api_key': _apiKey, 'language': language, 'page': page},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Popular TV Error: $e');
      return [];
    }
  }

  // ─── New list endpoints ────────────────────────────────────────────────────
  Future<List<MovieModel>> getUpcomingMovies({String language = 'en-US', int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/movie/upcoming',
        queryParameters: {'api_key': _apiKey, 'language': language, 'page': page},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Upcoming Movies Error: $e');
      return [];
    }
  }

  Future<List<MovieModel>> getNowPlayingMovies({String language = 'en-US', int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/movie/now_playing',
        queryParameters: {'api_key': _apiKey, 'language': language, 'page': page},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Now Playing Movies Error: $e');
      return [];
    }
  }

  Future<List<MovieModel>> getTopRatedMovies({String language = 'en-US', int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/movie/top_rated',
        queryParameters: {'api_key': _apiKey, 'language': language, 'page': page},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Top Rated Movies Error: $e');
      return [];
    }
  }

  Future<List<MovieModel>> getTopRatedTV({String language = 'en-US', int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_contentBaseUrl/tv/top_rated',
        queryParameters: {'api_key': _apiKey, 'language': language, 'page': page},
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Top Rated TV Error: $e');
      return [];
    }
  }

  
  // ─── 10. Additional Movie & TV Lists ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getGenres(bool isTv, {String language = 'en-US'}) async {
    try {
      final type = isTv ? 'tv' : 'movie';
      final response = await _dio.get(
        '$_contentBaseUrl/genre/$type/list',
        queryParameters: {'api_key': _apiKey, 'language': language},
        options: _contentOptions,
      );
      final List genres = response.data['genres'] ?? [];
      return genres.map((g) => g as Map<String, dynamic>).toList();
    } catch (e) {
      print('Genres List Error: $e');
      return [];
    }
  }

  Future<List<MovieModel>> getDiscoverByGenre(bool isTv, int genreId, {String language = 'en-US', int page = 1}) async {
    try {
      final type = isTv ? 'tv' : 'movie';
      final response = await _dio.get(
        '$_contentBaseUrl/discover/$type',
        queryParameters: {
          'api_key': _apiKey, 
          'language': language, 
          'page': page,
          'with_genres': genreId,
          'sort_by': 'popularity.desc'
        },
        options: _contentOptions,
      );
      final List results = response.data['results'] ?? [];
      return results.map((m) => MovieModel.fromJson(m)).toList();
    } catch (e) {
      print('Discover Genre Error: $e');
      return [];
    }
  }
}
