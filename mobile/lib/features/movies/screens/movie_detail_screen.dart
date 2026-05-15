import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/movie_detail_cubit.dart';
import '../bloc/movie_detail_state.dart';
import '../models/movie_model.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/bloc/favorites_event.dart';
import '../../favorites/bloc/favorites_state.dart';

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailCubit, MovieDetailState>(
      builder: (context, state) {
        if (state is MovieDetailLoading || state is MovieDetailInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is MovieDetailError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }

        final movie = (state as MovieDetailLoaded).movie;

        return Scaffold(
          appBar: AppBar(
            title: Text(movie.title, overflow: TextOverflow.ellipsis),
            actions: [_FavoriteButton(movie: movie)],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie.poster != null && movie.poster != 'N/A')
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: movie.poster!,
                      height: 320,
                      errorWidget: (_, __, ___) => const Icon(Icons.movie, size: 100),
                    ),
                  ),
                const SizedBox(height: 16),
                _InfoRow('Rating', movie.imdbRating != null ? '${movie.imdbRating} / 10' : '—'),
                _InfoRow('Year', movie.year ?? '—'),
                _InfoRow('Runtime', movie.runtime ?? '—'),
                _InfoRow('Genre', movie.genre ?? '—'),
                _InfoRow('Director', movie.director ?? '—'),
                _InfoRow('Actors', movie.actors ?? '—'),
                if (movie.plot != null) ...[
                  const SizedBox(height: 12),
                  Text('Plot', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(movie.plot!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final Movie movie;

  const _FavoriteButton({required this.movie});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoriteState>(
      builder: (context, state) {
        final isFav = state is FavoriteSuccess && state.isFavorite(movie.imdbId);
        return IconButton(
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null),
          onPressed: () {
            if (isFav) {
              context.read<FavoritesBloc>().add(FavoriteRemoved(movie.imdbId));
            } else {
              context.read<FavoritesBloc>().add(FavoriteAdded(movie));
            }
          },
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
