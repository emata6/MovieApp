import 'package:equatable/equatable.dart';
import '../../movies/models/movie_model.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoriteSuccess extends FavoriteState {
  final List<Movie> favorites;
  final bool isSyncing;

  const FavoriteSuccess({required this.favorites, this.isSyncing = false});

  bool isFavorite(String imdbId) =>
      favorites.any((m) => m.imdbId == imdbId);

  @override
  List<Object?> get props => [favorites, isSyncing];
}
