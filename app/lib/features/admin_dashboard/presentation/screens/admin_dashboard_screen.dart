import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../notification/presentation/screens/notification_screen.dart';
import '../../data/models/dashboard_stat_model.dart';
import '../../data/models/report_model.dart';
import '../providers/admin_dashboard_provider.dart';
import '../providers/admin_report_provider.dart';

/// Halaman Terpadu: Dashboard & Laporan Admin.
/// Desain modern, bersih, dan elegan tanpa tumpukan kotak berlebih.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTabIndex = 0; // 0: Operasional, 1: Laporan & Tren

  void _refreshAll() {
    ref.read(adminDashboardProvider.notifier).load();
    ref.read(adminReportProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: false,
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          NotificationBell(onTap: () => context.go('/admin/notifikasi')),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Perbarui Data',
            color: AppTheme.textSecondary,
            onPressed: _refreshAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Elegant Floating Segmented Control ─────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Operasional Hari Ini',
                    icon: Icons.flash_on_rounded,
                    isSelected: _selectedTabIndex == 0,
                    onTap: () => setState(() => _selectedTabIndex = 0),
                  ),
                  _TabButton(
                    label: 'Tren & Analisis',
                    icon: Icons.insights_rounded,
                    isSelected: _selectedTabIndex == 1,
                    onTap: () => setState(() => _selectedTabIndex = 1),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF5)),

          // ── Content View ──────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _selectedTabIndex == 0
                  ? _OperationalView(key: const ValueKey('op'), onRefresh: _refreshAll)
                  : _ReportView(key: const ValueKey('rep'), onRefresh: _refreshAll),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// TAB SWITCHER BUTTON (ELEGAN & MODERN)
// ────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primaryColor : const Color(0xFF718096),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// VIEW 1: OPERASIONAL
// ────────────────────────────────────────────────────────────────────────────

class _OperationalView extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _OperationalView({super.key, required this.onRefresh});

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
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.dangerColor),
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── Stat Overview Banner (Menyatu, Elegan, Bukan Kotak Terpisah) ──
          _UnifiedStatsCard(data: data),
          const SizedBox(height: 20),

          // ── Pending Approval List (Sleek List dengan Quick Action) ───
          _PendingSection(
            items: data.pendingList,
            onApprove: (id) => ref.read(adminDashboardProvider.notifier).approve(id),
            onReject: (id, note) => ref.read(adminDashboardProvider.notifier).reject(id, note),
            onViewAll: () => context.go('/admin/reservasi'),
          ),
          const SizedBox(height: 20),

          // ── Visual Status Distribution ─────────────────────────────────
          _DonutSection(dist: data.statusDistribution),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// UNIFIED STATS CARD (SATU KARTU ELEGAN DENGAN 4 METRIK)
// ────────────────────────────────────────────────────────────────────────────

class _UnifiedStatsCard extends StatelessWidget {
  final DashboardStatModel data;
  const _UnifiedStatsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Baris 1: Menunggu & Disetujui
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _StatItem(
                  label: 'Menunggu Persetujuan',
                  value: data.pending,
                  dotColor: AppTheme.warningColor,
                  isHighlighted: data.pending > 0,
                ),
                Container(width: 1, height: 44, color: const Color(0xFFEDF2F7)),
                _StatItem(
                  label: 'Disetujui Hari Ini',
                  value: data.approved,
                  dotColor: AppTheme.successColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
          // Baris 2: Kendaraan Siap & Total Pengguna
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _StatItem(
                  label: 'Armada Kendaraan Siap',
                  value: data.availableVehicles,
                  dotColor: AppTheme.accentColor,
                ),
                Container(width: 1, height: 44, color: const Color(0xFFEDF2F7)),
                _StatItem(
                  label: 'Pengguna Terdaftar',
                  value: data.totalUsers,
                  dotColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color dotColor;
  final bool isHighlighted;

  const _StatItem({
    required this.label,
    required this.value,
    required this.dotColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF718096),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isHighlighted ? dotColor : const Color(0xFF1A202C),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PERMOHONAN MENUNGGU (SLEEK LIST)
// ────────────────────────────────────────────────────────────────────────────

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pending_actions_rounded,
                    size: 16, color: AppTheme.warningColor),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Antrean Permohonan Reservasi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              if (items.isNotEmpty)
                GestureDetector(
                  onTap: onViewAll,
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 36, color: Color(0xFFA0AEC0)),
                    SizedBox(height: 6),
                    Text(
                      'Semua permohonan sudah diproses',
                      style: TextStyle(color: Color(0xFF718096), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 5 ? 5 : items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 20, color: Color(0xFFEDF2F7)),
              itemBuilder: (context, index) {
                final item = items[index];
                return Row(
                  children: [
                    // Mini avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        item.userName.isNotEmpty ? item.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.vehicleName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.userName} · ${item.batchName} · ${item.reservationDate}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Buttons (Clean & Pill)
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showRejectDialog(context, item.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tolak',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.dangerColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onApprove(item.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Setujui',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, int id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Reservasi'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Alasan Penolakan (opsional)',
            hintText: 'Contoh: Unit sedang perawatan mendadak...',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// DONUT CHART SECTION (CLEAN & MINIMALIS)
// ────────────────────────────────────────────────────────────────────────────

class _DonutSection extends StatelessWidget {
  final Map<String, int> dist;
  const _DonutSection({required this.dist});

  static const _config = [
    ('pending', 'Menunggu', AppTheme.warningColor),
    ('approved', 'Disetujui', AppTheme.successColor),
    ('rejected', 'Ditolak', AppTheme.dangerColor),
    ('cancelled', 'Dibatalkan', Color(0xFF94A3B8)),
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
              radius: 28,
              showTitle: false,
            ))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Status Reservasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 36,
                        sectionsSpace: 3,
                      ),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _config
                      .where((c) => (dist[c.$1] ?? 0) > 0)
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration:
                                      BoxDecoration(color: c.$3, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.$2,
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF4A5568)),
                                  ),
                                ),
                                Text(
                                  '${dist[c.$1]}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// VIEW 2: LAPORAN & TREN
// ────────────────────────────────────────────────────────────────────────────

class _ReportView extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _ReportView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReportProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(adminReportProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── Clean Filter Bar (Minimalis & Rapi) ─────────────────────────
          _FilterSection(state: state),
          const SizedBox(height: 16),

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
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppTheme.dangerColor),
                  const SizedBox(height: 12),
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(adminReportProvider.notifier).load(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (state.data != null) ...[
            // Status Summary Row
            _UnifiedReportSummaryCard(summary: state.data!.statusSummary),
            const SizedBox(height: 16),

            // Tren Chart Modern
            _TrendBarChartSection(trend: state.data!.trend, period: state.period),
            const SizedBox(height: 16),

            // Status Kesiapan Armada (Visual Meter)
            _VehicleStatusMeter(vehicleStatus: state.data!.vehicleStatus),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// FILTER SECTION (SLEEK & SOLID)
// ────────────────────────────────────────────────────────────────────────────

class _FilterSection extends ConsumerWidget {
  final AdminReportState state;
  const _FilterSection({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Period Toggle (Harian / Mingguan tanpa icon centang)
          Container(
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PeriodPill(
                  label: 'Harian',
                  isSelected: state.period == 'daily',
                  onTap: () => ref.read(adminReportProvider.notifier).setPeriod('daily'),
                ),
                _PeriodPill(
                  label: 'Mingguan',
                  isSelected: state.period == 'weekly',
                  onTap: () => ref.read(adminReportProvider.notifier).setPeriod('weekly'),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Date Selector Button
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final parts = state.startDate.split('-');
              final initial = parts.length == 3
                  ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
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
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 15, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    state.startDate.isNotEmpty ? state.startDate : 'Pilih Tanggal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// UNIFIED REPORT SUMMARY CARD (BERSIH & TERATUR)
// ────────────────────────────────────────────────────────────────────────────

class _UnifiedReportSummaryCard extends StatelessWidget {
  final Map<String, int> summary;
  const _UnifiedReportSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ReportSummaryItem(
            label: 'Menunggu',
            value: summary['pending'] ?? 0,
            color: AppTheme.warningColor,
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEDF2F7)),
          _ReportSummaryItem(
            label: 'Disetujui',
            value: summary['approved'] ?? 0,
            color: AppTheme.successColor,
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEDF2F7)),
          _ReportSummaryItem(
            label: 'Ditolak',
            value: summary['rejected'] ?? 0,
            color: AppTheme.dangerColor,
          ),
          Container(width: 1, height: 36, color: const Color(0xFFEDF2F7)),
          _ReportSummaryItem(
            label: 'Selesai',
            value: summary['completed'] ?? 0,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ReportSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// TREN BAR CHART (ELEGAN DENGAN GRADASI HALUS)
// ────────────────────────────────────────────────────────────────────────────

class _TrendBarChartSection extends StatelessWidget {
  final List<DailyTrendItem> trend;
  final String period;
  const _TrendBarChartSection({required this.trend, required this.period});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('Belum ada data tren',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final maxY = trend.map((t) => t.count).fold(0, (a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period == 'daily' ? 'Tren Reservasi 7 Hari' : 'Tren Reservasi Mingguan',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: (maxY < 4 ? 4 : maxY + 1).toDouble(),
                barGroups: trend.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.count.toDouble(),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF1A3A5C), Color(0xFF2E7DC0)],
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, _) => Text(
                        val.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= trend.length) return const SizedBox();
                        final parts = trend[idx].date.split('-');
                        final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : trend[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  drawHorizontalLine: true,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// STATUS KESIAPAN ARMADA (VISUAL METER)
// ────────────────────────────────────────────────────────────────────────────

class _VehicleStatusMeter extends StatelessWidget {
  final Map<String, int> vehicleStatus;
  const _VehicleStatusMeter({required this.vehicleStatus});

  @override
  Widget build(BuildContext context) {
    final available = vehicleStatus['available'] ?? 0;
    final maintenance = vehicleStatus['maintenance'] ?? 0;
    final inactive = vehicleStatus['inactive'] ?? 0;
    final total = available + maintenance + inactive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kesiapan Armada Kendaraan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              Text(
                'Total: $total Unit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (available > 0)
                    Expanded(
                      flex: available,
                      child: Container(color: AppTheme.successColor),
                    ),
                  if (maintenance > 0)
                    Expanded(
                      flex: maintenance,
                      child: Container(color: AppTheme.warningColor),
                    ),
                  if (inactive > 0)
                    Expanded(
                      flex: inactive,
                      child: Container(color: AppTheme.dangerColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MeterIndicator(label: 'Tersedia', count: available, color: AppTheme.successColor),
              _MeterIndicator(label: 'Perawatan', count: maintenance, color: AppTheme.warningColor),
              _MeterIndicator(label: 'Nonaktif', count: inactive, color: AppTheme.dangerColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterIndicator extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MeterIndicator({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          '$count',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
