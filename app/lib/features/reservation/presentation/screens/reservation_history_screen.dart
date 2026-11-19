import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../reservation/data/models/reservation_model.dart';
import '../providers/reservation_list_provider.dart';
import '../widgets/receipt_widget.dart';

/// Halaman Riwayat Reservasi Pengguna.
/// Sesuai spesifikasi FIX_BLANK_PAGE_RESERVASI.md:
/// - Mobile (< 700px): Card list rapi dengan Expanded(child: ListView.builder)
/// - Desktop (>= 700px): Tabel lebar DataTable dengan horizontal scroll
/// - Bebas unbounded constraint error dan null-safe 100%
class ReservationHistoryScreen extends ConsumerStatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  ConsumerState<ReservationHistoryScreen> createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState
    extends ConsumerState<ReservationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reservationListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationListProvider);

    Widget content;
    if (state.isLoading && state.reservations.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null && state.reservations.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(reservationListProvider.notifier).load(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    } else if (state.reservations.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_outlined, size: 32, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Riwayat Reservasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reservasi yang Anda ajukan akan muncul di sini beserta status persetujuan dari admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/reservasi'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Reservasi Baru'),
              ),
            ],
          ),
        ),
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            // ── Mobile View (< 700px): Card List ────────────
            return RefreshIndicator(
              onRefresh: () => ref.read(reservationListProvider.notifier).load(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.reservations.length,
                itemBuilder: (context, index) {
                  final r = state.reservations[index];
                  return _buildUserReservationCard(r);
                },
              ),
            );
          } else {
            // ── Desktop View (>= 700px): Tabel Lebar DataTable ─
            return RefreshIndicator(
              onRefresh: () => ref.read(reservationListProvider.notifier).load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth - 32),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Kendaraan', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Unit Kerja', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Jenis Kebutuhan', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Catatan Admin', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: state.reservations.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text(r.reservationDate)),
                              DataCell(Text('${r.batch.name} (${r.batch.startTime}–${r.batch.endTime})')),
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(r.vehicle.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(r.vehicle.type, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              )),
                              DataCell(Text(r.workUnit)),
                              DataCell(Text(r.purpose.length > 25 ? '${r.purpose.substring(0, 25)}...' : r.purpose)),
                              DataCell(_StatusChip(status: r.status)),
                              DataCell(Text(r.adminNote != null && r.adminNote!.isNotEmpty ? r.adminNote! : '-')),
                              DataCell(_buildUserActionButtons(r)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Riwayat Reservasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => ref.read(reservationListProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: content),
        ],
      ),
    );
  }

  // ── Card Widget untuk Mobile ──────────────────────────────
  Widget _buildUserReservationCard(ReservationModel r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.vehicle.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.vehicle.type,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: r.status),
              ],
            ),
            const Divider(height: 18),
            _InfoRow(
              Icons.calendar_today_outlined,
              '${r.reservationDate} · ${r.batch.name} (${r.batch.startTime}–${r.batch.endTime})',
            ),
            _InfoRow(Icons.business_outlined, r.workUnit),
            _InfoRow(Icons.notes_outlined, 'Kebutuhan: ${r.purpose}'),
            if (r.adminNote != null && r.adminNote!.isNotEmpty)
              _InfoRow(Icons.sticky_note_2_outlined, 'Catatan Admin: ${r.adminNote!}'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildUserActionButtons(r),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tombol Aksi User Sesuai Status ────────────────────────
  Widget _buildUserActionButtons(ReservationModel r) {
    if (r.isPending) {
      return OutlinedButton.icon(
        onPressed: () => _confirmCancel(r.id),
        icon: const Icon(Icons.cancel_outlined, size: 16),
        label: const Text('Batalkan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.dangerColor,
          side: const BorderSide(color: AppTheme.dangerColor),
        ),
      );
    }
    if (r.isApproved || r.isCompleted) {
      return ElevatedButton.icon(
        onPressed: () => _showReceipt(r),
        icon: const Icon(Icons.receipt_long, size: 16),
        label: const Text('Struk'),
      );
    }
    return const SizedBox.shrink();
  }

  void _confirmCancel(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Reservasi?'),
        content: const Text('Reservasi yang dibatalkan tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(reservationListProvider.notifier).cancel(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showReceipt(ReservationModel reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (ctx, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ReceiptWidget(reservation: reservation),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'pending': AppTheme.warningColor,
      'approved': AppTheme.successColor,
      'rejected': AppTheme.dangerColor,
      'cancelled': Colors.grey,
      'completed': AppTheme.primaryColor,
    };
    final labels = {
      'pending': 'Menunggu Persetujuan',
      'approved': 'Disetujui',
      'rejected': 'Ditolak',
      'cancelled': 'Dibatalkan',
      'completed': 'Selesai',
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
