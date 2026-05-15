import 'package:equatable/equatable.dart';

abstract class MovieEvent extends Equatable {
  const MovieEvent();

  @override
  List<Object?> get props => [];
}

class MovieStoredLoaded extends MovieEvent {
  final int page;

  const MovieStoredLoaded({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class MovieSearchRequested extends MovieEvent {
  final String query;
  final int page;

  const MovieSearchRequested({required this.query, this.page = 1});

  @override
  List<Object?> get props => [query, page];
}

class MovieSearchCleared extends MovieEvent {}
