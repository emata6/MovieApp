import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../features/movies/models/movie_model.dart';

class MovieTile extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MovieTile(
      {super.key, required this.movie, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 50,
        height: 70,
        child: movie.poster != null && movie.poster != 'N/A'
            ? CachedNetworkImage(
                imageUrl: movie.poster!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.movie),
              )
            : const Icon(Icons.movie, size: 40),
      ),
      title: Text(movie.title,
          maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(movie.year ?? ''),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
