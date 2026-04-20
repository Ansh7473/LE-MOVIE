// lib/data/models/tv_details_model.dart

import 'movie_model.dart';

class TVDetailsModel {
  final int id;
  final String name;
  final String backdropPath;
  final String overview;
  final double voteAverage;
  final String firstAirDate;
  final List<SeasonModel> seasons;

  TVDetailsModel({
    required this.id,
    required this.name,
    required this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.firstAirDate,
    required this.seasons,
  });

  factory TVDetailsModel.fromJson(Map<String, dynamic> json) {
    return TVDetailsModel(
      id: json['id'],
      name: json['name'],
      backdropPath: json['backdrop_path'] ?? '',
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: json['first_air_date'] ?? '',
      seasons: (json['seasons'] as List)
          .map((s) => SeasonModel.fromJson(s))
          .toList(),
    );
  }
}

class SeasonModel {
  final int id;
  final int seasonNumber;
  final String name;
  final String overview;
  final String posterPath;
  final int episodeCount;

  SeasonModel({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.episodeCount,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'],
      seasonNumber: json['season_number'],
      name: json['name'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      episodeCount: json['episode_count'] ?? 0,
    );
  }
}

class EpisodeModel {
  final int id;
  final int episodeNumber;
  final String name;
  final String overview;
  final String stillPath;

  EpisodeModel({
    required this.id,
    required this.episodeNumber,
    required this.name,
    required this.overview,
    required this.stillPath,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'],
      episodeNumber: json['episode_number'],
      name: json['name'],
      overview: json['overview'] ?? '',
      stillPath: json['still_path'] ?? '',
    );
  }
}
