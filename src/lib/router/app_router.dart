import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth_gate.dart';
import '../screens/welcome_screen.dart';
import '../screens/join_class_screen.dart';
import '../screens/create_class_screen.dart';
import '../screens/main_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isSplash = authState.status == AuthStatus.initial;
      
      final isGoingToAuth = state.matchedLocation == '/welcome' || 
                            state.matchedLocation == '/join' || 
                            state.matchedLocation == '/create';

      if (isSplash) {
        return '/';
      }

      if (!isAuth) {
        return isGoingToAuth ? null : '/welcome';
      }

      if (isGoingToAuth || state.matchedLocation == '/') {
        return '/main';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinClassScreen(),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreateClassScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) {
          return MainScreen(
            role: authState.role ?? 'student', 
            classId: authState.classId ?? '',
          );
        },
      ),
    ],
  );
});
