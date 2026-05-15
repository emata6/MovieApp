import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/movie_bloc.dart';
import '../bloc/movie_event.dart';
import '../bloc/movie_state.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/bloc/favorites_event.dart';
import '../../favorites/bloc/favorites_state.dart';
import '../bloc/movie_detail_cubit.dart';
import '../repository/movie_repository.dart';
import '../../../shared/widgets/movie_tile.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MovieBloc>().add(const MovieStoredLoaded());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    context.read<MovieBloc>().add(MovieSearchRequested(query: query));
  }

  void _clear() {
    _controller.clear();
    context.read<MovieBloc>().add(MovieSearchCleared());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Movies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Search for a movie…',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (_, value, __) => value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clear,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<MovieBloc, MovieState>(
                  builder: (_, state) => IconButton.filled(
                    onPressed: state is MovieLoading ? null : _search,
                    icon: const Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<MovieBloc, MovieState>(
            builder: (_, state) =>
                state is MovieLoading ? const LinearProgressIndicator() : const SizedBox.shrink(),
          ),
          Expanded(
            child: BlocBuilder<MovieBloc, MovieState>(
              builder: (context, state) {
                if (state is MovieError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message,
                            style:
                                const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context
                              .read<MovieBloc>()
                              .add(const MovieStoredLoaded()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final movies = switch (state) {
                  MovieStoredSuccess(:final movies) => movies,
                  MovieSearchSuccess(:final movies) => movies,
                  _ => null,
                };

                if (movies == null) {
                  return const Center(child: Text('Search for a movie above'));
                }

                if (movies.isEmpty) {
                  final message = state is MovieSearchSuccess
                      ? 'No cached results for "${state.query}".\nConnect to the internet to search.'
                      : 'No cached movies.\nConnect to the internet to load movies.';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return BlocBuilder<FavoritesBloc, FavoriteState>(
                  builder: (context, favState) {
                    return ListView.builder(
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        final isFav = favState is FavoriteSuccess &&
                            favState.isFavorite(movie.imdbId);

                        return MovieTile(
                          movie: movie,
                          trailing: IconButton(
                            icon: Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFav ? Colors.red : null,
                            ),
                            onPressed: () {
                              if (isFav) {
                                context.read<FavoritesBloc>().add(
                                    FavoriteRemoved(movie.imdbId));
                              } else {
                                context.read<FavoritesBloc>().add(
                                    FavoriteAdded(movie));
                              }
                            },
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
