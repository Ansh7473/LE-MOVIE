// lib/presentation/providers/streaming_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/movie_model.dart';
import '../../data/models/tv_details_model.dart';
import '../../data/models/stream_model.dart';
import '../../data/services/movie_service.dart';

class StreamingProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  TVDetailsModel? _currentTVDetails;
  TVDetailsModel? get currentTVDetails => _currentTVDetails;

  List<EpisodeModel> _currentEpisodes = [];
  List<EpisodeModel> get currentEpisodes => _currentEpisodes;

  List<StreamModel> _availableStreams = [];
  List<StreamModel> get availableStreams => _availableStreams;

  SeasonModel? _selectedSeason;
  SeasonModel? get selectedSeason => _selectedSeason;

  EpisodeModel? _selectedEpisode;
  EpisodeModel? get selectedEpisode => _selectedEpisode;

  StreamModel? _selectedStream;
  StreamModel? get selectedStream => _selectedStream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. Initialize Media Data (Supports both Movie & TV)
  Future<void> loadMedia(int id, {bool isTv = true}) async {
    _isLoading = true;
    _currentTVDetails = null;
    _currentEpisodes = [];
    _availableStreams = [];
    _selectedSeason = null;
    _selectedEpisode = null;
    notifyListeners();

    if (isTv) {
      _currentTVDetails = await _movieService.getTVDetails(id);
      if (_currentTVDetails != null && _currentTVDetails!.seasons.isNotEmpty) {
        await selectSeason(_currentTVDetails!.seasons.first);
      }
    } else {
      // It's a Movie
      _availableStreams = await _movieService.getStreams(id, 0, 0); // Special case for movies
      if (_availableStreams.isNotEmpty) {
        _selectedStream = _availableStreams.first;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. Select Season
  Future<void> selectSeason(SeasonModel season) async {
    _selectedSeason = season;
    _selectedEpisode = null;
    _availableStreams = [];
    notifyListeners();

    if (_currentTVDetails != null) {
      _currentEpisodes = await _movieService.getSeasonEpisodes(
        _currentTVDetails!.id,
        season.seasonNumber,
      );
      if (_currentEpisodes.isNotEmpty) {
        selectEpisode(_currentEpisodes.first);
      }
    }
  }

  // 3. Select Episode & Fetch Servers
  Future<void> selectEpisode(EpisodeModel episode) async {
    _selectedEpisode = episode;
    _selectedStream = null;
    _isLoading = true;
    notifyListeners();

    if (_currentTVDetails != null && _selectedSeason != null) {
      _availableStreams = await _movieService.getStreams(
        _currentTVDetails!.id,
        _selectedSeason!.seasonNumber,
        episode.episodeNumber,
      );
      
      if (_availableStreams.isNotEmpty) {
        _selectedStream = _availableStreams.first;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // 4. Change Server
  void selectStream(StreamModel stream) {
    _selectedStream = stream;
    notifyListeners();
  }
}
