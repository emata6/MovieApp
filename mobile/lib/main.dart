import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/db/local_database.dart';
import 'core/network/connectivity_service.dart';
import 'core/services/api_client.dart';
import 'features/auth/api/auth_api.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/favorites/api/favorites_api.dart';
import 'features/favorites/bloc/favorites_bloc.dart';
import 'features/favorites/bloc/favorites_event.dart';
import 'features/favorites/bloc/favorites_state.dart';
import 'features/favorites/repository/favorites_repository.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'features/movies/api/movie_api.dart';
import 'features/movies/bloc/movie_bloc.dart';
import 'features/movies/repository/movie_repository.dart';
import 'features/movies/screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localDb = LocalDatabase();
  final apiClient = ApiClient();
  final connectivity = ConnectivityService();

  final authRepository =
      AuthRepository(AuthApi(), apiClient);
  final movieRepository =
      MovieRepository(MovieApi(apiClient), localDb);
  final favoritesRepository =
      FavoritesRepository(FavoritesApi(apiClient), localDb);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MovieRepository>.value(
            value: movieRepository),
        RepositoryProvider<FavoritesRepository>.value(
            value: favoritesRepository),
        RepositoryProvider<AuthRepository>.value(
            value: authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AuthBloc(authRepository)..add(AuthStarted()),
          ),
          BlocProvider(
            create: (_) => MovieBloc(movieRepository),
          ),
          BlocProvider(
            create: (_) =>
                FavoritesBloc(favoritesRepository, connectivity),
          ),
        ],
        child: const MovieApp(),
      ),
    ),
  );
}

class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<FavoritesBloc>().add(FavoritesLoaded());
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) return const MainShell();
          if (state is AuthLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [SearchScreen(), FavoritesScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: BlocBuilder<FavoritesBloc, FavoriteState>(
              builder: (_, state) {
                final count = state is FavoriteSuccess
                    ? state.favorites.length
                    : 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.favorite),
                );
              },
            ),
            label: 'Favourites',
          ),
        ],
      ),
    );
  }
}
