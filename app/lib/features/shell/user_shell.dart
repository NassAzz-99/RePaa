import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Shell navigasi pengguna: 4 tab (Dashboard, Reservasi, Riwayat, Profil).
/// Spesifikasi (01_auth.md): bottom navigation untuk role 'user'.
class UserShell extends StatelessWidget {
  final Widget child;
  const UserShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/home'),
    _TabItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Reservasi', path: '/reservasi'),
    _TabItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Riwayat', path: '/riwayat'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', path: '/profil'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon, color: AppTheme.primaryColor),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
