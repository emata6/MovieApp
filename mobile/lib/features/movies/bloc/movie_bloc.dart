import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/movie_repository.dart';
import 'movie_event.dart';
import 'movie_state.dart';

class MovieBloc extends Bloc<MovieEvent, MovieState> {
  final MovieRepository _repository;

  MovieBloc(this._repository) : super(MovieInitial()) {
    on<MovieStoredLoaded>(_onStoredLoaded);
    on<MovieSearchRequested>(_onSearch);
    on<MovieSearchCleared>(_onCleared);
  }

  Future<void> _onStoredLoaded(
      MovieStoredLoaded event, Emitter<MovieState> emit) async {
    emit(MovieLoading());
    try {
      final result = await _repository.getStoredMovies(page: event.page);
      emit(MovieStoredSuccess(movies: result.items, hasMore: result.hasMore));
    } catch (e) {
      emit(MovieError(_message(e)));
    }
  }

  Future<void> _onSearch(
      MovieSearchRequested event, Emitter<MovieState> emit) async {
    emit(MovieLoading());
    try {
      final movies =
          await _repository.searchMovies(event.query, page: event.page);
      emit(MovieSearchSuccess(movies: movies, query: event.query));
    } catch (e) {
      emit(MovieError(_message(e)));
    }
  }

  Future<void> _onCleared(
      MovieSearchCleared event, Emitter<MovieState> emit) async {
    emit(MovieLoading());
    try {
      final result = await _repository.getStoredMovies();
      emit(MovieStoredSuccess(movies: result.items, hasMore: result.hasMore));
    } catch (e) {
      emit(MovieError(_message(e)));
    }
  }

  String _message(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
