import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../providers/reservation_list_provider.dart';
import '../widgets/receipt_widget.dart';

/// Halaman Riwayat Reservasi.
/// Spesifikasi (03_reservasi.md §B):
/// - List card: Tanggal, Batch, Kendaraan, Unit Kerja, Status (badge warna)
/// - Aksi: Struk (jika Disetujui/Selesai) atau Batalkan (jika Menunggu)
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

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Riwayat Reservasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(reservationListProvider.notifier).load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(reservationListProvider.notifier).load(),
        child: Builder(builder: (context) {
          if (state.isLoading && state.reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.reservations.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppTheme.dangerColor),
                      const SizedBox(height: 8),
                      Text(state.errorMessage!,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(reservationListProvider.notifier).load(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state.reservations.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                        child: Icon(
                          Icons.history_outlined,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
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
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
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
              ),
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: state.reservations.length,
            itemBuilder: (context, index) {
              final r = state.reservations[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Card ─────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.vehicle.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _StatusChip(status: r.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                        Icons.calendar_today_outlined, r.reservationDate),
                    _InfoRow(Icons.access_time_outlined,
                        '${r.batch.name}  ${r.batch.startTime}–${r.batch.endTime}'),
                    _InfoRow(Icons.business_outlined, r.workUnit),
                    if (r.adminNote != null && r.adminNote!.isNotEmpty)
                      _InfoRow(Icons.sticky_note_2_outlined, r.adminNote!),
                    const SizedBox(height: 10),

                    // ── Aksi ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Batalkan (hanya jika pending)
                        if (r.isPending)
                          OutlinedButton.icon(
                            onPressed: () => _confirmCancel(context, ref, r.id),
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Batalkan'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.dangerColor,
                              side: const BorderSide(
                                  color: AppTheme.dangerColor),
                            ),
                          ),

                        if (r.isPending) const SizedBox(width: 8),

                        // Lihat Struk (approved/completed)
                        if (r.isApproved || r.isCompleted)
                          ElevatedButton.icon(
                            onPressed: () => _showReceipt(context, r),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('Struk'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Reservasi?'),
        content: const Text(
            'Reservasi yang dibatalkan tidak dapat dikembalikan.'),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, dynamic reservation) {
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
      'pending': 'Menunggu',
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
