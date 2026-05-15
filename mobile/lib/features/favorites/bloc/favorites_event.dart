import 'package:equatable/equatable.dart';
import '../../movies/models/movie_model.dart';

abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

class FavoritesLoaded extends FavoriteEvent {}

class FavoriteAdded extends FavoriteEvent {
  final Movie movie;

  const FavoriteAdded(this.movie);

  @override
  List<Object?> get props => [movie.imdbId];
}

class FavoriteRemoved extends FavoriteEvent {
  final String imdbId;

  const FavoriteRemoved(this.imdbId);

  @override
  List<Object?> get props => [imdbId];
}

class FavoritesSyncRequested extends FavoriteEvent {}
