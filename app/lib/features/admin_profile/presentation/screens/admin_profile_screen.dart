import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin_dashboard/data/models/dashboard_stat_model.dart';
import '../../../admin_dashboard/presentation/providers/admin_dashboard_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Halaman Profil Admin.
/// Menampilkan info admin, statistik ringkas, shortcut kelola, dan tombol Keluar.
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final dashState = ref.watch(adminDashboardProvider);

    final initial = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : 'A';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── Header SliverAppBar bergradien ─────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      // Avatar lingkaran inisial
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Badge role
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Statistik ringkas ────────────────────────────────────
                  _StatCard(data: dashState.data),

                  const SizedBox(height: 16),

                  // ── Kelola Sistem ────────────────────────────────────────
                  const _SectionLabel(label: 'Kelola Sistem'),
                  const SizedBox(height: 8),
                  _MenuCard(
                    children: [
                      _MenuItem(
                        icon: Icons.directions_car_outlined,
                        iconColor: AppTheme.primaryColor,
                        title: 'Kelola Kendaraan',
                        subtitle: 'Tambah, edit, nonaktifkan kendaraan',
                        onTap: () => context.go('/admin/kelola/kendaraan'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _MenuItem(
                        icon: Icons.people_outline,
                        iconColor: AppTheme.accentColor,
                        title: 'Kelola Pengguna',
                        subtitle: 'Lihat dan kelola akun pengguna',
                        onTap: () => context.go('/admin/kelola/pengguna'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _MenuItem(
                        icon: Icons.schedule_outlined,
                        iconColor: AppTheme.warningColor,
                        title: 'Kelola Batch',
                        subtitle: 'Atur slot waktu reservasi',
                        onTap: () => context.go('/admin/kelola/batch'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Akun ─────────────────────────────────────────────────
                  const _SectionLabel(label: 'Akun'),
                  const SizedBox(height: 8),
                  _MenuCard(
                    children: [
                      _MenuItem(
                        icon: Icons.manage_accounts_outlined,
                        iconColor: Colors.blueGrey,
                        title: 'Edit Profil & Password',
                        subtitle: 'Ubah nama, email, dan kata sandi',
                        onTap: () => _showEditProfileSheet(context, ref, user),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Tombol Keluar ─────────────────────────────────────────
                  _LogoutButton(ref: ref),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(
      BuildContext context, WidgetRef ref, UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditProfileSheet(
        initialName: user?.name ?? '',
        initialEmail: user?.email ?? '',
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// StatCard: Statistik ringkas dari adminDashboardProvider
// ────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final DashboardStatModel? data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final approved = data?.approved ?? 0;
    final pending = data?.pending ?? 0;
    final vehicles = data?.availableVehicles ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _StatItem(
              value: '$approved',
              label: 'Disetujui',
              color: AppTheme.successColor,
              icon: Icons.check_circle_outline,
            ),
            _VertDivider(),
            _StatItem(
              value: '$pending',
              label: 'Menunggu',
              color: AppTheme.warningColor,
              icon: Icons.hourglass_empty_outlined,
            ),
            _VertDivider(),
            _StatItem(
              value: '$vehicles',
              label: 'Kendaraan',
              color: AppTheme.primaryColor,
              icon: Icons.local_shipping_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: Colors.grey.shade200);
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatItem(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Menu helpers
// ────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right,
          color: AppTheme.textSecondary, size: 20),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Logout Button
// ────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  final WidgetRef ref;
  const _LogoutButton({required this.ref});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.dangerColor),
            SizedBox(width: 8),
            Text('Keluar?'),
          ],
        ),
        content: const Text(
            'Anda akan keluar dari sesi admin ini.\nPastikan semua pekerjaan sudah tersimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _loggingOut = true);
    await widget.ref.read(authProvider.notifier).logout();
    // go_router redirect otomatis ke /login setelah logout
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loggingOut ? null : _logout,
        icon: _loggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.logout),
        label: Text(_loggingOut ? 'Keluar...' : 'Keluar dari Akun'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.dangerColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Edit Profile Bottom Sheet
// ────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final String initialName;
  final String initialEmail;
  const _EditProfileSheet(
      {required this.initialName, required this.initialEmail});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.put<dynamic>('/profile', data: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      // Refresh data user di authProvider
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = ApiException.fromDioError(e).message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Edit Profil Admin',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}
