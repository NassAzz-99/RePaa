import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/shell/user_shell.dart';
import '../../features/shell/admin_shell.dart';

/// Router GoRouter dengan redirect berbasis status auth dan role.
/// Spesifikasi (01_auth.md):
///   role 'user'  → UserShell (bottom nav 4 tab)
///   role 'admin' → AdminShell (bottom nav 4 tab)
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' || location == '/register';

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      if (authState.status == AuthStatus.unauthenticated ||
          authState.status == AuthStatus.error) {
        return isAuthPage ? null : '/login';
      }

      if (authState.status == AuthStatus.authenticated && isAuthPage) {
        return authState.user?.isAdmin == true ? '/admin' : '/home';
      }

      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── User Shell (bottom nav pengguna) ─────────────────
      ShellRoute(
        builder: (context, state, child) => UserShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Dashboard'),
          ),
          GoRoute(
            path: '/reservasi',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Form Reservasi'),
          ),
          GoRoute(
            path: '/riwayat',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Riwayat Reservasi'),
          ),
          GoRoute(
            path: '/profil',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Profil'),
          ),
        ],
      ),

      // ── Admin Shell (bottom nav admin) ───────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Dashboard Admin'),
          ),
          GoRoute(
            path: '/admin/reservasi',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Kelola Reservasi'),
          ),
          GoRoute(
            path: '/admin/kelola',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Kelola'),
          ),
          GoRoute(
            path: '/admin/laporan',
            builder: (context, state) =>
                const _PlaceholderPage(label: 'Laporan'),
          ),
        ],
      ),
    ],
  );
});

/// Mendengarkan perubahan authProvider dan memberitahu GoRouter untuk redirect.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  _RouterNotifier(this._ref) {
    _subscription = _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Placeholder halaman untuk tab yang belum diimplementasi.
class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          '🚧 $label\n(Segera hadir)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
