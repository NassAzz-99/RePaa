import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_stat_model.dart';
import '../providers/admin_dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminDashboardProvider.notifier).load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminDashboardProvider.notifier).load(),
        child: Builder(builder: (context) {
          if (state.isLoading && state.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.data == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.dangerColor),
                const SizedBox(height: 8),
                Text(state.errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(adminDashboardProvider.notifier).load(),
                  child: const Text('Coba Lagi'),
                ),
              ]),
            );
          }
          final data = state.data;
          if (data == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Stat Cards ───────────────────────────────
              _StatCards(data: data),
              const SizedBox(height: 16),

              // ── Donut Chart ──────────────────────────────
              _DonutSection(dist: data.statusDistribution),
              const SizedBox(height: 16),

              // ── Pending List ─────────────────────────────
              _PendingSection(
                items: data.pendingList,
                onApprove: (id) =>
                    ref.read(adminDashboardProvider.notifier).approve(id),
                onReject: (id, note) =>
                    ref.read(adminDashboardProvider.notifier).reject(id, note),
                onViewAll: () => context.go('/admin/reservasi'),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Stat Cards ────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  final DashboardStatModel data;
  const _StatCards({required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _StatCard(
          label: 'Menunggu',
          value: data.pending,
          icon: Icons.hourglass_top_outlined,
          color: AppTheme.warningColor,
        ),
        _StatCard(
          label: 'Disetujui',
          value: data.approved,
          icon: Icons.check_circle_outline,
          color: AppTheme.successColor,
        ),
        _StatCard(
          label: 'Kendaraan Siap',
          value: data.availableVehicles,
          icon: Icons.local_shipping_outlined,
          color: AppTheme.accentColor,
        ),
        _StatCard(
          label: 'Total Pengguna',
          value: data.totalUsers,
          icon: Icons.people_outline,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Donut Chart ───────────────────────────────────────────

class _DonutSection extends StatelessWidget {
  final Map<String, int> dist;
  const _DonutSection({required this.dist});

  static const _config = [
    ('pending', 'Menunggu', AppTheme.warningColor),
    ('approved', 'Disetujui', AppTheme.successColor),
    ('rejected', 'Ditolak', AppTheme.dangerColor),
    ('cancelled', 'Dibatalkan', Color(0xFF95A5A6)),
    ('completed', 'Selesai', AppTheme.primaryColor),
  ];

  @override
  Widget build(BuildContext context) {
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox();

    final sections = _config
        .where((c) => (dist[c.$1] ?? 0) > 0)
        .map((c) => PieChartSectionData(
              value: (dist[c.$1] ?? 0).toDouble(),
              color: c.$3,
              radius: 48,
              title: '${dist[c.$1]}',
              titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊  Distribusi Status Reservasi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: _config
                  .where((c) => (dist[c.$1] ?? 0) > 0)
                  .map((c) => _Legend(
                      color: c.$3,
                      label: '${c.$2} (${dist[c.$1]})'))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}

// ── Pending List ──────────────────────────────────────────

class _PendingSection extends StatelessWidget {
  final List<PendingReservationItem> items;
  final void Function(int id) onApprove;
  final void Function(int id, String? note) onReject;
  final VoidCallback onViewAll;

  const _PendingSection({
    required this.items,
    required this.onApprove,
    required this.onReject,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                child: Text(
                  '⏳  Reservasi Menunggu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('Lihat semua →'),
              ),
            ]),
            const Divider(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Tidak ada reservasi menunggu.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ...items.map((item) => _PendingCard(
                    item: item,
                    onApprove: () => onApprove(item.id),
                    onReject: (note) => onReject(item.id, note),
                  )),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final PendingReservationItem item;
  final VoidCallback onApprove;
  final void Function(String? note) onReject;
  const _PendingCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.05),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.userName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(item.userEmail,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          _InfoRow(Icons.business_outlined, item.workUnit),
          _InfoRow(Icons.local_shipping_outlined, item.vehicleName),
          _InfoRow(
            Icons.access_time_outlined,
            '${item.reservationDate} · ${item.batchName} ${item.batchStartTime}–${item.batchEndTime}',
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(context),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerColor,
                  side: const BorderSide(color: AppTheme.dangerColor),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Setuju'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Reservasi'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Catatan penolakan (opsional)',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    if (confirmed == true) {
      onReject(text.isEmpty ? null : text);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

