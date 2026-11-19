import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Shell navigasi admin: 4 tab (Dashboard, Reservasi, Kelola, Profil).
/// Halaman Laporan sudah terintegrasi langsung di dalam Dashboard.
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/admin'),
    _TabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Reservasi', path: '/admin/reservasi'),
    _TabItem(icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts, label: 'Kelola', path: '/admin/kelola'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', path: '/admin/profil'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // Exact match untuk /admin agar tidak menabrak /admin/*
    if (location == '/admin') return 0;
    final idx = _tabs.indexWhere((t) => t.path != '/admin' && location.startsWith(t.path));
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
