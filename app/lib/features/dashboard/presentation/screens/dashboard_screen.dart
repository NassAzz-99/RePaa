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
/// - Legenda warna, grid/list kartu kendaraan, ikon lonceng di AppBar
/// - Pull-to-refresh
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          NotificationBell(onTap: () => context.go('/notifikasi')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // ── Header Card ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                              SizedBox(height: 2),
                              Text(
                                'Status per batch · Tarik untuk perbarui',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/reservasi'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Buat Reservasi'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── Legenda ───────────────────────────
                    const _Legend(),
                  ],
                ),
              ),
            ),

            // ── Loading ───────────────────────────────────
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),

            // ── Error ─────────────────────────────────────
            if (!state.isLoading && state.errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.dangerColor),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(dashboardProvider.notifier).refresh(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Empty ─────────────────────────────────────
            if (!state.isLoading &&
                state.errorMessage == null &&
                (state.data?.vehicles.isEmpty ?? true))
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Tidak ada kendaraan tersedia.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),

            // ── Daftar Kendaraan ──────────────────────────
            if (!state.isLoading &&
                state.errorMessage == null &&
                (state.data?.vehicles.isNotEmpty ?? false))
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final vehicle = state.data!.vehicles[index];
                    return VehicleCard(
                      vehicle: vehicle,
                      onReserveTap: vehicle.isAvailable
                          ? () => context.go(
                                '/reservasi',
                                extra: {'vehicle_id': vehicle.id},
                              )
                          : null,
                    );
                  },
                  childCount: state.data!.vehicles.length,
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
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
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
