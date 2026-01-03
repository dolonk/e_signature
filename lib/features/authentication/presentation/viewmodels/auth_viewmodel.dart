import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/di/injection_container.dart';

// State Class
class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final Failure? failure;

  const AuthState({this.isLoading = false, this.user, this.failure});

  factory AuthState.initial() => const AuthState();

  factory AuthState.loading() => const AuthState(isLoading: true);

  factory AuthState.authenticated(UserEntity user) => AuthState(user: user);

  factory AuthState.unauthenticated() => const AuthState();

  factory AuthState.error(Failure failure) => AuthState(failure: failure);

  AuthState copyWith({bool? isLoading, UserEntity? user, Failure? failure}) {
    return AuthState(isLoading: isLoading ?? this.isLoading, user: user ?? this.user, failure: failure ?? this.failure);
  }
}

// ViewModel Class
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(AuthState.initial()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    state = AuthState.loading();
    final result = await _repository.getCurrentUser();
    result.fold((failure) => state = AuthState.unauthenticated(), (user) => state = AuthState.authenticated(user));
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    final result = await _repository.login(email, password);
    state = result.fold((failure) => AuthState.error(failure), (user) => AuthState.authenticated(user));
  }

  Future<void> register(String email, String password) async {
    state = AuthState.loading();
    final result = await _repository.register(email, password);
    state = result.fold((failure) => AuthState.error(failure), (user) => AuthState.authenticated(user));
  }

  Future<void> logout() async {
    state = AuthState.loading();
    final result = await _repository.logout();
    state = result.fold((failure) => AuthState.error(failure), (_) => AuthState.unauthenticated());
  }
}

// Provider
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref.read(authRepositoryProvider));
});

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});
