import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';
import '../../../shared/widgets/movie_tile.dart';
import '../../movies/bloc/movie_detail_cubit.dart';
import '../../movies/repository/movie_repository.dart';
import '../../movies/screens/movie_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        actions: [
          BlocBuilder<FavoritesBloc, FavoriteState>(
            builder: (_, state) {
              if (state is FavoriteSuccess && state.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoriteState>(
        builder: (context, state) {
          if (state is FavoriteLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = state is FavoriteSuccess ? state.favorites : [];

          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'No favourites yet.\nSearch for movies to add some!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final movie = favorites[index];
              return MovieTile(
                movie: movie,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      context.read<FavoritesBloc>().add(FavoriteRemoved(movie.imdbId)),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => BlocProvider(
                      create: (_) =>
                          MovieDetailCubit(ctx.read<MovieRepository>())
                            ..loadDetail(movie.imdbId),
                      child: const MovieDetailScreen(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
