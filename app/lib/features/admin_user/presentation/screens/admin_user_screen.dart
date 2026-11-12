import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/admin_user_model.dart';
import '../providers/admin_user_provider.dart';

class AdminUserScreen extends ConsumerWidget {
  const AdminUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUserProvider);
    final currentUserId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminUserProvider.notifier).load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminUserProvider.notifier).load(),
        child: Builder(builder: (context) {
          if (state.isLoading && state.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.users.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.dangerColor),
                const SizedBox(height: 8),
                Text(state.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(adminUserProvider.notifier).load(),
                  child: const Text('Coba Lagi'),
                ),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final u = state.users[index];
              final isSelf = u.id == currentUserId;
              return _UserCard(
                user: u,
                isSelf: isSelf,
                onToggleRole: isSelf
                    ? null
                    : () => _confirmToggleRole(context, ref, u),
                onToggleActive: isSelf
                    ? null
                    : () => _confirmToggleActive(context, ref, u),
              );
            },
          );
        }),
      ),
    );
  }

  void _confirmToggleRole(
      BuildContext context, WidgetRef ref, AdminUserModel u) {
    final toAdmin = u.role != 'admin';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(toAdmin ? 'Jadikan Admin?' : 'Jadikan Pengguna?'),
        content: Text(
            '${u.name} akan dijadikan ${toAdmin ? 'Admin' : 'Pengguna biasa'}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminUserProvider.notifier).toggleRole(u.id, u.role);
            },
            child: const Text('Ya, Ubah'),
          ),
        ],
      ),
    );
  }

  void _confirmToggleActive(
      BuildContext context, WidgetRef ref, AdminUserModel u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(u.isActive ? 'Nonaktifkan Pengguna?' : 'Aktifkan Pengguna?'),
        content: Text(u.isActive
            ? '${u.name} tidak akan bisa login hingga diaktifkan kembali.'
            : 'Aktifkan kembali akun ${u.name}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(adminUserProvider.notifier)
                  .toggleActive(u.id, u.isActive);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  u.isActive ? AppTheme.dangerColor : AppTheme.successColor,
            ),
            child: Text(u.isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserModel user;
  final bool isSelf;
  final VoidCallback? onToggleRole;
  final VoidCallback? onToggleActive;

  const _UserCard({
    required this.user,
    required this.isSelf,
    this.onToggleRole,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final u = user;
    final initial = u.name.isNotEmpty ? u.name[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor,
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(u.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    if (isSelf)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Akun Anda',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  Text(u.email,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, children: [
                    _Badge(
                      label: u.roleLabel,
                      color: u.role == 'admin'
                          ? AppTheme.accentColor
                          : const Color(0xFF95A5A6),
                    ),
                    _Badge(
                      label: u.isActive ? 'Aktif' : 'Nonaktif',
                      color: u.isActive
                          ? AppTheme.successColor
                          : AppTheme.dangerColor,
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('${u.totalReservations} reservasi · Daftar: ${u.createdAt.split('T').first}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  if (!isSelf) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onToggleRole,
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: Text(
                            u.role == 'admin'
                                ? 'Jadikan Pengguna'
                                : 'Jadikan Admin',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onToggleActive,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 6),
                            backgroundColor: u.isActive
                                ? AppTheme.dangerColor
                                : AppTheme.successColor,
                          ),
                          child: Text(
                            u.isActive ? 'Nonaktifkan' : 'Aktifkan',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

