import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/movie_repository.dart';
import 'movie_detail_state.dart';

class MovieDetailCubit extends Cubit<MovieDetailState> {
  final MovieRepository _repository;

  MovieDetailCubit(this._repository) : super(MovieDetailInitial());

  Future<void> loadDetail(String imdbId) async {
    emit(MovieDetailLoading());
    try {
      final movie = await _repository.getMovieDetail(imdbId);
      emit(MovieDetailLoaded(movie));
    } catch (e) {
      emit(MovieDetailError(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
