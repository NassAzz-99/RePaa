import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Repository (inline, tidak butuh file terpisah) ───────

class _ProfileRepo {
  final Dio _dio;
  _ProfileRepo(this._dio);

  Future<void> updateProfile(String name, String email) async {
    await _dio.put('/profile', data: {'name': name, 'email': email});
  }

  Future<void> changePassword(
      String current, String newPass, String confirm) async {
    await _dio.put('/profile/password', data: {
      'current_password': current,
      'password': newPass,
      'password_confirmation': confirm,
    });
  }
}

// ── Screen ────────────────────────────────────────────────

/// Halaman Profil Pengguna.
/// Spesifikasi (04_profil.md): Edit nama/email, ubah password, tombol Keluar.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passFormKey    = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _savingProfile  = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl.text  = user?.name  ?? '';
    _emailCtrl.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _currentPassCtrl.dispose(); _newPassCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }

  _ProfileRepo get _repo =>
      _ProfileRepo(ref.read(dioProvider));

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      await _repo.updateProfile(_nameCtrl.text.trim(), _emailCtrl.text.trim());
      if (!mounted) return;
      _showSnack('Profil berhasil diperbarui.', success: true);
    } on ApiException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      await _repo.changePassword(
        _currentPassCtrl.text,
        _newPassCtrl.text,
        _confirmPassCtrl.text,
      );
      if (!mounted) return;
      _currentPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear();
      _showSnack('Password berhasil diubah.', success: true);
    } on ApiException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.successColor : AppTheme.dangerColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan keluar dari akun ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar dengan Avatar ──────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryVariant, AppTheme.primaryColor],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          (user?.name.isNotEmpty == true)
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.name ?? '',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.role == 'admin' ? '👑 Admin' : '👤 Pengguna',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: const Text('Profil Saya'),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Kartu Info Akun ──────────────────────
                _SectionCard(
                  title: '✏️  Informasi Akun',
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => Validators.required(v, 'Nama'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _savingProfile ? null : _saveProfile,
                            child: _savingProfile
                                ? const SizedBox(height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan Perubahan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Kartu Ubah Password ──────────────────
                _SectionCard(
                  title: '🔑  Ubah Password',
                  child: Form(
                    key: _passFormKey,
                    child: Column(
                      children: [
                        _PassField(
                          ctrl: _currentPassCtrl,
                          label: 'Password Saat Ini',
                          obscure: _obscureCurrent,
                          toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          validator: (v) => Validators.required(v, 'Password saat ini'),
                        ),
                        const SizedBox(height: 14),
                        _PassField(
                          ctrl: _newPassCtrl,
                          label: 'Password Baru',
                          obscure: _obscureNew,
                          toggle: () => setState(() => _obscureNew = !_obscureNew),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 14),
                        _PassField(
                          ctrl: _confirmPassCtrl,
                          label: 'Konfirmasi Password Baru',
                          obscure: _obscureConfirm,
                          toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) => Validators.confirmPassword(v, _newPassCtrl.text),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _savingPassword ? null : _changePassword,
                            child: _savingPassword
                                ? const SizedBox(height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Ubah Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Tombol Keluar ────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
                    label: const Text('Keluar',
                        style: TextStyle(color: AppTheme.dangerColor)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppTheme.dangerColor),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryColor)),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback toggle;
  final String? Function(String?) validator;

  const _PassField({
    required this.ctrl,
    required this.label,
    required this.obscure,
    required this.toggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }
}

