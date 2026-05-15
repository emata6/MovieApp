import 'package:equatable/equatable.dart';
import '../models/movie_model.dart';

abstract class MovieState extends Equatable {
  const MovieState();

  @override
  List<Object?> get props => [];
}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieStoredSuccess extends MovieState {
  final List<Movie> movies;
  final bool hasMore;

  const MovieStoredSuccess({required this.movies, required this.hasMore});

  @override
  List<Object?> get props => [movies, hasMore];
}

class MovieSearchSuccess extends MovieState {
  final List<Movie> movies;
  final String query;

  const MovieSearchSuccess({required this.movies, required this.query});

  @override
  List<Object?> get props => [movies, query];
}

class MovieError extends MovieState {
  final String message;

  const MovieError(this.message);

  @override
  List<Object?> get props => [message];
}
