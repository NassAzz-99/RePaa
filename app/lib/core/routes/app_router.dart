import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin_batch/presentation/screens/admin_batch_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin_manage/presentation/screens/admin_manage_screen.dart';
import '../../features/admin_profile/presentation/screens/admin_profile_screen.dart';
import '../../features/admin_report/presentation/screens/admin_report_screen.dart';
import '../../features/admin_reservation/presentation/screens/admin_reservation_screen.dart';
import '../../features/admin_user/presentation/screens/admin_user_screen.dart';
import '../../features/admin_vehicle/data/models/vehicle_model.dart';
import '../../features/admin_vehicle/presentation/screens/admin_vehicle_form_screen.dart';
import '../../features/admin_vehicle/presentation/screens/admin_vehicle_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/reservation/presentation/screens/reservation_form_screen.dart';
import '../../features/reservation/presentation/screens/reservation_history_screen.dart';
import '../../features/shell/admin_shell.dart';
import '../../features/shell/user_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isAuthPage = loc == '/login' || loc == '/register';

      if (auth.status == AuthStatus.initial ||
          auth.status == AuthStatus.loading) {
        return null;
      }
      if (auth.status == AuthStatus.unauthenticated ||
          auth.status == AuthStatus.error) {
        return isAuthPage ? null : '/login';
      }
      if (auth.status == AuthStatus.authenticated && isAuthPage) {
        return auth.user?.isAdmin == true ? '/admin' : '/home';
      }
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),

      // ── User Shell ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => UserShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/reservasi',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final vehicleId = extra?['vehicle_id'] as int?;
              return ReservationFormScreen(preSelectedVehicleId: vehicleId);
            },
          ),
          GoRoute(
            path: '/riwayat',
            builder: (context, state) => const ReservationHistoryScreen(),
          ),
          GoRoute(
            path: '/profil',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifikasi',
            builder: (context, state) => const NotificationScreen(),
          ),
        ],
      ),

      // ── Admin Shell ───────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/reservasi',
            builder: (context, state) => const AdminReservationScreen(),
          ),
          GoRoute(
            path: '/admin/kelola',
            builder: (context, state) => const AdminManageScreen(),
          ),
          GoRoute(
            path: '/admin/laporan',
            builder: (context, state) => const AdminReportScreen(),
          ),
          GoRoute(
            path: '/admin/profil',
            builder: (context, state) => const AdminProfileScreen(),
          ),
        ],
      ),

      // ── Admin sub-pages (push, tanpa shell) ───────────────
      GoRoute(
        path: '/admin/kelola/kendaraan',
        builder: (context, state) => const AdminVehicleScreen(),
      ),
      GoRoute(
        path: '/admin/kelola/kendaraan/form',
        builder: (context, state) {
          final vehicle = state.extra as VehicleModel?;
          return AdminVehicleFormScreen(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: '/admin/kelola/pengguna',
        builder: (context, state) => const AdminUserScreen(),
      ),
      GoRoute(
        path: '/admin/kelola/batch',
        builder: (context, state) => const AdminBatchScreen(),
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  _RouterNotifier(this._ref) {
    _sub = _ref.listen(authProvider, (previous, next) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
