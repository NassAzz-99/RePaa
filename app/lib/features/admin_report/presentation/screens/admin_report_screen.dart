import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/report_model.dart';
import '../providers/admin_report_provider.dart';

class AdminReportScreen extends ConsumerWidget {
  const AdminReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReportProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminReportProvider.notifier).load(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Filter Bar ───────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Toggle harian/mingguan
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'daily', label: Text('Harian')),
                      ButtonSegment(value: 'weekly', label: Text('Mingguan')),
                    ],
                    selected: {state.period},
                    onSelectionChanged: (s) =>
                        ref.read(adminReportProvider.notifier).setPeriod(s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primaryColor;
                        }
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return null;
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Date picker
                InkWell(
                  onTap: () async {
                    final parts = state.startDate.split('-');
                    final initial = parts.length == 3
                        ? DateTime(int.parse(parts[0]),
                            int.parse(parts[1]), int.parse(parts[2]))
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
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(state.startDate,
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          if (state.isLoading && state.data == null)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (state.errorMessage != null && state.data == null)
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
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
              ]),
            )
          else if (state.data != null) ...[
            _StatusSummaryGrid(summary: state.data!.statusSummary),
            const SizedBox(height: 12),
            _TrendChart(trend: state.data!.trend, period: state.period),
            const SizedBox(height: 12),
            _VehicleStatusCard(vehicleStatus: state.data!.vehicleStatus),
          ],
        ],
      ),
    );
  }
}

// ── Status Summary ────────────────────────────────────────

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
            child: Row(children: [
              Icon(c.$4, color: c.$3, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${summary[c.$1] ?? 0}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: c.$3)),
                  Text(c.$2,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Trend Bar Chart ───────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<DailyTrendItem> trend;
  final String period;
  const _TrendChart({required this.trend, required this.period});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox();
    final maxY = trend.map((t) => t.count).fold(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period == 'daily' ? '📈  Tren Harian' : '📈  Tren Mingguan',
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
                      sideTitles: SideTitles(
                          showTitles: true, reservedSize: 28)),
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
                            child: Text(label,
                                style: const TextStyle(fontSize: 9)),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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

// ── Vehicle Status ────────────────────────────────────────

class _VehicleStatusCard extends StatelessWidget {
  final Map<String, int> vehicleStatus;
  const _VehicleStatusCard({required this.vehicleStatus});

  @override
  Widget build(BuildContext context) {
    final available = vehicleStatus['available'] ?? 0;
    final maintenance = vehicleStatus['maintenance'] ?? 0;
    final inactive = vehicleStatus['inactive'] ?? 0;
    final total = available + maintenance + inactive;
    if (total == 0) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚛  Status Kendaraan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 14),
            _VehicleBar(
                label: 'Tersedia',
                count: available,
                total: total,
                color: AppTheme.successColor),
            const SizedBox(height: 10),
            _VehicleBar(
                label: 'Perawatan',
                count: maintenance,
                total: total,
                color: AppTheme.warningColor),
            const SizedBox(height: 10),
            _VehicleBar(
                label: 'Nonaktif',
                count: inactive,
                total: total,
                color: const Color(0xFF95A5A6)),
          ],
        ),
      ),
    );
  }
}

class _VehicleBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _VehicleBar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13))),
          Text('$count / $total',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

