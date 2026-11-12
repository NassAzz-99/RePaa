import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Hub screen untuk tab "Kelola" di AdminShell.
/// Menampilkan 3 menu: Kendaraan, Pengguna, Batch.
class AdminManageScreen extends StatelessWidget {
  const AdminManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Kelola')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ManageCard(
            icon: Icons.local_shipping_outlined,
            title: 'Kelola Kendaraan',
            subtitle: 'Tambah, ubah, hapus unit kendaraan PAA',
            color: AppTheme.accentColor,
            onTap: () => context.push('/admin/kelola/kendaraan'),
          ),
          const SizedBox(height: 12),
          _ManageCard(
            icon: Icons.people_outline,
            title: 'Kelola Pengguna',
            subtitle: 'Atur role dan status akun pengguna',
            color: AppTheme.primaryColor,
            onTap: () => context.push('/admin/kelola/pengguna'),
          ),
          const SizedBox(height: 12),
          _ManageCard(
            icon: Icons.access_time_outlined,
            title: 'Kelola Batch',
            subtitle: 'Atur slot waktu reservasi harian',
            color: AppTheme.warningColor,
            onTap: () => context.push('/admin/kelola/batch'),
          ),
        ],
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ManageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ]),
        ),
      ),
    );
  }
}

