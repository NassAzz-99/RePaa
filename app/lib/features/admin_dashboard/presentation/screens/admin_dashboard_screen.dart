import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/dashboard_stat_model.dart';
import '../../data/models/report_model.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_report_provider.dart';

/// Halaman Terpadu: Dashboard & Laporan Admin.
/// Menggabungkan operasional real-time (tindakan approval cepat & metrik hari ini)
/// serta analisis tren historis (grafik harian/mingguan & status armada).
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.read(adminDashboardProvider.notifier).load();
    ref.read(adminReportProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Dashboard & Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Data',
            onPressed: _refreshAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Operasional'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Laporan & Tren'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Operasional ────────────────────────────────────
          _OperationalTab(onRefresh: _refreshAll),

          // ── Tab 2: Laporan & Tren ─────────────────────────────────
          _ReportTab(onRefresh: _refreshAll),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// TAB 1: OPERASIONAL
// ────────────────────────────────────────────────────────────────────────────

class _OperationalTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _OperationalTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);

    if (state.isLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
            const SizedBox(height: 8),
            Text(state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(adminDashboardProvider.notifier).load(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final data = state.data;
    if (data == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: () async => ref.read(adminDashboardProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Stat Cards ──────────────────────────────────────────
          _StatCards(data: data),
          const SizedBox(height: 16),

          // ── Permohonan Menunggu Tindakan (Aksi Cepat) ───────────
          _PendingSection(
            items: data.pendingList,
            onApprove: (id) =>
                ref.read(adminDashboardProvider.notifier).approve(id),
            onReject: (id, note) =>
                ref.read(adminDashboardProvider.notifier).reject(id, note),
            onViewAll: () => context.go('/admin/reservasi'),
          ),
          const SizedBox(height: 16),

          // ── Donut Chart Distribusi Status ────────────────────────
          _DonutSection(dist: data.statusDistribution),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// TAB 2: LAPORAN & TREN
// ────────────────────────────────────────────────────────────────────────────

class _ReportTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _ReportTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReportProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(adminReportProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Filter Bar ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppTheme.primaryColor;
                            }
                            return Colors.grey.shade100;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return AppTheme.textPrimary;
                          },
                        ),
                        side: WidgetStateProperty.all(
                          BorderSide(color: Colors.grey.shade300),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 'daily',
                          label: Text(
                            'Harian',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: 'weekly',
                          label: Text(
                            'Mingguan',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      selected: {state.period},
                      onSelectionChanged: (s) =>
                          ref.read(adminReportProvider.notifier).setPeriod(s.first),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Date Picker
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final parts = state.startDate.split('-');
                      final initial = parts.length == 3
                          ? DateTime(int.parse(parts[0]), int.parse(parts[1]),
                              int.parse(parts[2]))
                          : DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final d =
                            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        ref.read(adminReportProvider.notifier).setStartDate(d);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 15, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            state.startDate.isNotEmpty
                                ? state.startDate
                                : 'Pilih Tanggal',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Content State ───────────────────────────────────────
          if (state.isLoading && state.data == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.errorMessage != null && state.data == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppTheme.dangerColor),
                  const SizedBox(height: 8),
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(adminReportProvider.notifier).load(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (state.data != null) ...[
            // Status Summary Cards
            _StatusSummaryGrid(summary: state.data!.statusSummary),
            const SizedBox(height: 14),

            // Bar Chart Tren
            _TrendChart(trend: state.data!.trend, period: state.period),
            const SizedBox(height: 14),

            // Kesiapan Armada
            _VehicleStatusCard(vehicleStatus: state.data!.vehicleStatus),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Komponen Operasional: StatCards, Donut, PendingList
// ────────────────────────────────────────────────────────────────────────────

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
              radius: 46,
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
                  '⏳  Reservasi Menunggu Persetujuan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                ),
            ]),
            const Divider(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Tidak ada reservasi menunggu persetujuan.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.vehicleName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.userName} · ${item.batchName}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            Text(
                              item.reservationDate,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _showRejectDialog(context, item.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerColor,
                          side: const BorderSide(color: AppTheme.dangerColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Tolak', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () => onApprove(item.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Setujui', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, int id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Reservasi'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Alasan Penolakan (opsional)',
            hintText: 'Masukkan alasan...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.dispose();
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final note = ctrl.text.trim();
              Navigator.pop(ctx);
              ctrl.dispose();
              onReject(id, note.isEmpty ? null : note);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Komponen Laporan: SummaryGrid, TrendChart, VehicleStatusCard
// ────────────────────────────────────────────────────────────────────────────

class _StatusSummaryGrid extends StatelessWidget {
  final Map<String, int> summary;
  const _StatusSummaryGrid({required this.summary});

  static const _config = [
    ('pending', 'Menunggu', AppTheme.warningColor, Icons.hourglass_top_outlined),
    ('approved', 'Disetujui', AppTheme.successColor, Icons.check_circle_outline),
    ('rejected', 'Ditolak', AppTheme.dangerColor, Icons.cancel_outlined),
    ('completed', 'Selesai', AppTheme.primaryColor, Icons.flag_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: _config.map((c) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(c.$4, color: c.$3, size: 28),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${summary[c.$1] ?? 0}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: c.$3,
                      ),
                    ),
                    Text(
                      c.$2,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<DailyTrendItem> trend;
  final String period;
  const _TrendChart({required this.trend, required this.period});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('Belum ada data tren untuk periode ini.',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    final maxY = trend.map((t) => t.count).fold(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period == 'daily' ? '📈  Tren Reservasi Harian' : '📈  Tren Reservasi Mingguan',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: (maxY + 2).toDouble(),
                  barGroups: trend.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.count.toDouble(),
                          color: AppTheme.accentColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= trend.length) {
                            return const SizedBox();
                          }
                          final date = trend[idx].date;
                          final parts = date.split('-');
                          final label = parts.length >= 3
                              ? '${parts[2]}/${parts[1]}'
                              : date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  final Map<String, int> vehicleStatus;
  const _VehicleStatusCard({required this.vehicleStatus});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚚  Kesiapan Armada Kendaraan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusIndicator(
                  label: 'Tersedia',
                  count: vehicleStatus['available'] ?? 0,
                  color: AppTheme.successColor,
                ),
                _StatusIndicator(
                  label: 'Perawatan',
                  count: vehicleStatus['maintenance'] ?? 0,
                  color: AppTheme.warningColor,
                ),
                _StatusIndicator(
                  label: 'Nonaktif',
                  count: vehicleStatus['inactive'] ?? 0,
                  color: AppTheme.dangerColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusIndicator({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
