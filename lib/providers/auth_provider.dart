import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';
import '../data/firestore_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? classId;
  final String? role;

  const AuthState({
    this.status = AuthStatus.initial,
    this.classId,
    this.role,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? classId,
    String? role,
  }) {
    return AuthState(
      status: status ?? this.status,
      classId: classId ?? this.classId,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkSession();
    return const AuthState();
  }

  Future<void> _checkSession() async {
    final classId = await AuthService.getSavedClassId();
    final role = await AuthService.getSavedRole();

    if (classId != null && role != null) {
      FirestoreService.setClassId(classId);
      final restored = await AuthService.restoreSession();
      if (restored) {
        final loaded = await AuthService.loadClassData(classId);
        if (loaded) {
          state = AuthState(
            status: AuthStatus.authenticated,
            classId: classId,
            role: role,
          );
          return;
        }
      }
      await AuthService.logout();
    }

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login(String classId, String role) async {
    FirestoreService.setClassId(classId);
    state = AuthState(
      status: AuthStatus.authenticated,
      classId: classId,
      role: role,
    );
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
