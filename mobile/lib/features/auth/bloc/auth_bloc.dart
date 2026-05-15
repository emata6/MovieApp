import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onStarted(
      AuthStarted event, Emitter<AuthState> emit) async {
    final user = await _repository.getStoredUser();
    if (user != null) {
      emit(AuthAuthenticated(username: user.username, email: user.email));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.login(event.email, event.password);
      emit(AuthAuthenticated(username: user.username, email: user.email));
    } catch (e) {
      emit(AuthError(_message(e)));
    }
  }

  Future<void> _onRegister(
      AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(
          event.username, event.email, event.password);
      emit(AuthAuthenticated(username: user.username, email: user.email));
    } catch (e) {
      emit(AuthError(_message(e)));
    }
  }

  Future<void> _onLogout(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(AuthUnauthenticated());
  }

  String _message(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
