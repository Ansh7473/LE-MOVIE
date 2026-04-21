// lib/data/models/movie_model.dart

class MovieModel {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String releaseDate;
  final bool isTv;
  final String? imdbId;

  MovieModel({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    this.isTv = false,
    this.imdbId,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Unknown',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] is num) 
          ? (json['vote_average'] as num).toDouble() 
          : 0.0,
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      isTv: json['name'] != null || json['first_air_date'] != null,
      imdbId: json['imdb_id'],
    );
  }

  // Helper to construct image URLs
  String get fullPosterPath => 'https://image.tmdb.org/t/p/w500$posterPath';
  String get fullBackdropPath => 'https://image.tmdb.org/t/p/original$backdropPath';
}
