class Movie {
  final String imdbId;
  final String title;
  final String? year;
  final String? poster;
  final String? genre;
  final String? director;
  final String? actors;
  final String? plot;
  final String? imdbRating;
  final String? runtime;
  final String? rated;

  const Movie({
    required this.imdbId,
    required this.title,
    this.year,
    this.poster,
    this.genre,
    this.director,
    this.actors,
    this.plot,
    this.imdbRating,
    this.runtime,
    this.rated,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        imdbId: json['imdbId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        year: json['year'] as String?,
        poster: json['poster'] as String?,
        genre: json['genre'] as String?,
        director: json['director'] as String?,
        actors: json['actors'] as String?,
        plot: json['plot'] as String?,
        imdbRating: json['imdbRating'] as String?,
        runtime: json['runtime'] as String?,
        rated: json['rated'] as String?,
      );

  factory Movie.fromOmdbSearch(Map<String, dynamic> json) => Movie(
        imdbId: json['imdbID'] as String? ?? '',
        title: json['Title'] as String? ?? '',
        year: json['Year'] as String?,
        poster: json['Poster'] as String?,
      );

  factory Movie.fromLocalMap(Map<String, dynamic> map) => Movie(
        imdbId: map['imdbId'] as String,
        title: map['title'] as String,
        year: map['year'] as String?,
        poster: map['poster'] as String?,
        genre: map['genre'] as String?,
        director: map['director'] as String?,
        actors: map['actors'] as String?,
        plot: map['plot'] as String?,
        imdbRating: map['imdbRating'] as String?,
        runtime: map['runtime'] as String?,
        rated: map['rated'] as String?,
      );

  Map<String, dynamic> toLocalMap() => {
        'imdbId': imdbId,
        'title': title,
        'year': year,
        'poster': poster,
        'genre': genre,
        'director': director,
        'actors': actors,
        'plot': plot,
        'imdbRating': imdbRating,
        'runtime': runtime,
        'rated': rated,
        'fetchedAt': DateTime.now().toIso8601String(),
      };
}
