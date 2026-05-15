import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/connectivity_service.dart';
import '../../movies/models/movie_model.dart';
import '../repository/favorites_repository.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoritesRepository _repository;
  StreamSubscription<bool>? _connectivitySub;

  FavoritesBloc(this._repository, ConnectivityService connectivity)
      : super(FavoriteInitial()) {
    on<FavoritesLoaded>(_onLoaded);
    on<FavoriteAdded>(_onAdded);
    on<FavoriteRemoved>(_onRemoved);
    on<FavoritesSyncRequested>(_onSync);

    _connectivitySub = connectivity.onConnectivityChanged.listen((online) {
      if (online) add(FavoritesSyncRequested());
    });
  }

  Future<void> _onLoaded(
      FavoritesLoaded event, Emitter<FavoriteState> emit) async {
    emit(FavoriteLoading());
    try {
      final favorites = await _repository.getFavorites();
      emit(FavoriteSuccess(favorites: favorites, isSyncing: true));
      await _repository.syncFavorites();
      final synced = await _repository.getFavorites();
      emit(FavoriteSuccess(favorites: synced));
    } catch (e) {
      final cached = await _safeFetch();
      emit(FavoriteSuccess(favorites: cached));
    }
  }

  Future<void> _onAdded(
      FavoriteAdded event, Emitter<FavoriteState> emit) async {
    final current = _current;
    try {
      await _repository.addFavorite(event.movie);
      emit(FavoriteSuccess(favorites: await _repository.getFavorites()));
    } catch (_) {
      emit(FavoriteSuccess(favorites: current));
    }
  }

  Future<void> _onRemoved(
      FavoriteRemoved event, Emitter<FavoriteState> emit) async {
    final current = _current;
    try {
      await _repository.removeFavorite(event.imdbId);
      emit(FavoriteSuccess(favorites: await _repository.getFavorites()));
    } catch (_) {
      emit(FavoriteSuccess(favorites: current));
    }
  }

  Future<void> _onSync(
      FavoritesSyncRequested event, Emitter<FavoriteState> emit) async {
    if (state is! FavoriteSuccess) return;
    final current = _current;
    emit(FavoriteSuccess(favorites: current, isSyncing: true));
    try {
      await _repository.syncFavorites();
      emit(FavoriteSuccess(favorites: await _repository.getFavorites()));
    } catch (_) {
      emit(FavoriteSuccess(favorites: current));
    }
  }

  List<Movie> get _current =>
      state is FavoriteSuccess ? (state as FavoriteSuccess).favorites : <Movie>[];

  Future<List<Movie>> _safeFetch() async {
    try {
      return await _repository.getFavorites();
    } catch (_) {
      return <Movie>[];
    }
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
