import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

/// Checking whether a saved session exists.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AppUser user;
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthLoading();
  }

  /// The user stays logged in until they log out: if a saved session exists we
  /// open the app immediately (even offline) and refresh the profile quietly.
  Future<void> _restore() async {
    if (!await _repo.hasSession()) {
      state = const Unauthenticated();
      return;
    }
    final cached = await _repo.cachedUser();
    state = Authenticated(
      cached ?? const AppUser(id: '', username: '', name: '', role: ''),
    );
    try {
      final fresh = await _repo.fetchMe();
      if (state is Authenticated) state = Authenticated(fresh);
    } catch (_) {
      // Offline or server error: stay logged in. A rejected refresh token
      // calls sessionExpired() through the API client.
    }
  }

  /// Returns null on success, or why the login failed.
  Future<LoginFailure?> login(String username, String password) async {
    try {
      final user = await _repo.login(username, password);
      state = Authenticated(user);
      return null;
    } on LoginException catch (e) {
      return e.failure;
    } catch (_) {
      return LoginFailure.unknown;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const Unauthenticated();
  }

  void sessionExpired() {
    if (state is Authenticated) state = const Unauthenticated();
  }
}
