import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../notification/presentation/screens/notification_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/vehicle_card.dart';

/// Halaman Dashboard Pengguna.
/// Spesifikasi (02_dashboard_user.md):
/// - Header: "Ketersediaan Kendaraan Hari Ini", keterangan, tombol Buat Reservasi
/// - Legenda warna, kartu kendaraan per unit & status batch slot, ikon lonceng di AppBar
/// - Pull-to-refresh
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data saat pertama mount memastikan token dan data terbaru dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final vehicles = state.data?.vehicles ?? [];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          NotificationBell(onTap: () => context.go('/notifikasi')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ── Header Card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ketersediaan Kendaraan Hari Ini',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Status per batch · Tarik ke bawah untuk perbarui',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/reservasi'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Buat Reservasi'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      // ── Legenda ───────────────────────────────────
                      const _Legend(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Loading State ────────────────────────────────────────
            if (state.isLoading && state.data == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),

            // ── Error State ──────────────────────────────────────────
            if (!state.isLoading && state.errorMessage != null && state.data == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.dangerColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(dashboardProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Empty State ──────────────────────────────────────────
            if (!state.isLoading &&
                state.errorMessage == null &&
                vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tidak ada kendaraan tersedia saat ini.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Seksi Rekomendasi Kendaraan ──────────────────────────
            if (vehicles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.thumb_up_alt_outlined,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Rekomendasi Kendaraan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${vehicles.where((v) => v.isAvailable).length} Unit Tersedia',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Daftar Kartu Kendaraan
              ...vehicles.map(
                (v) => VehicleCard(
                  vehicle: v,
                  onReserveTap: v.isAvailable
                      ? () => context.go(
                            '/reservasi',
                            extra: {'vehicle_id': v.id},
                          )
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(color: AppTheme.successColor, label: 'Kosong'),
        _LegendItem(color: AppTheme.warningColor, label: 'Menunggu'),
        _LegendItem(color: AppTheme.dangerColor, label: 'Dipesan'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
