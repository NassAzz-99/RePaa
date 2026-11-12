import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../reservation/data/models/reservation_model.dart';
import '../../../reservation/presentation/widgets/receipt_widget.dart';
import '../providers/admin_reservation_provider.dart';

class AdminReservationScreen extends ConsumerWidget {
  const AdminReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReservationProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Kelola Reservasi'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context, ref, state.filter),
              ),
              if (state.filter.isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.warningColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminReservationProvider.notifier).load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminReservationProvider.notifier).load(),
        child: Builder(builder: (context) {
          if (state.isLoading && state.reservations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.reservations.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.dangerColor),
                const SizedBox(height: 8),
                Text(state.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(adminReservationProvider.notifier).load(),
                  child: const Text('Coba Lagi'),
                ),
              ]),
            );
          }
          if (state.reservations.isEmpty) {
            return const Center(
              child: Text('Tidak ada reservasi.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.reservations.length,
            itemBuilder: (context, index) {
              final r = state.reservations[index];
              return _ReservationCard(
                reservation: r,
                onApprove: () =>
                    ref.read(adminReservationProvider.notifier).approve(r.id),
                onReject: (note) =>
                    ref.read(adminReservationProvider.notifier).reject(r.id, note),
                onComplete: () =>
                    ref.read(adminReservationProvider.notifier).complete(r.id),
              );
            },
          );
        }),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref,
      AdminReservationFilter current) {
    String? status = current.status;
    String? date = current.date;
    final workUnitCtrl = TextEditingController(text: current.workUnit);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Filter Reservasi',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              initialValue: status ?? 'all',
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'pending', child: Text('Menunggu')),
                DropdownMenuItem(value: 'approved', child: Text('Disetujui')),
                DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
                DropdownMenuItem(value: 'completed', child: Text('Selesai')),
              ],
              onChanged: (v) => setModal(() => status = v),
            ),
            const SizedBox(height: 12),

            // Tanggal
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  final d =
                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  setModal(() => date = d);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal'),
                child: Text(date ?? 'Semua tanggal',
                    style: TextStyle(
                        color: date != null
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary)),
              ),
            ),
            const SizedBox(height: 12),

            // Unit Kerja
            TextField(
              controller: workUnitCtrl,
              decoration: const InputDecoration(labelText: 'Unit Kerja'),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref
                        .read(adminReservationProvider.notifier)
                        .clearFilter();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(adminReservationProvider.notifier).setFilter(
                          AdminReservationFilter(
                            status: status,
                            date: date,
                            workUnit: workUnitCtrl.text.trim().isEmpty
                                ? null
                                : workUnitCtrl.text.trim(),
                          ),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Terapkan'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Card Reservasi ────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onApprove;
  final void Function(String? note) onReject;
  final VoidCallback onComplete;

  const _ReservationCard({
    required this.reservation,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(r.user.email ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
            ),
            _StatusBadge(status: r.status),
          ]),
          const Divider(height: 16),

          // Info rows
          _Row(Icons.business_outlined, r.workUnit),
          _Row(Icons.local_shipping_outlined, r.vehicle.name),
          _Row(Icons.calendar_today_outlined,
              '${r.reservationDate} · ${r.batch.name} ${r.batch.startTime}–${r.batch.endTime}'),
          _Row(Icons.notes_outlined, r.purpose,
              maxLines: 2),
          if (r.adminNote != null && r.adminNote!.isNotEmpty)
            _Row(Icons.sticky_note_2_outlined, 'Catatan: ${r.adminNote!}'),

          const SizedBox(height: 10),

          // Aksi
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (r.isPending) ...[
              OutlinedButton(
                onPressed: () => _showRejectDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerColor,
                  side: const BorderSide(color: AppTheme.dangerColor),
                ),
                child: const Text('Tolak'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor),
                child: const Text('Setuju'),
              ),
            ],
            if (r.isApproved) ...[
              OutlinedButton(
                onPressed: () => _showReceipt(context),
                child: const Text('Struk'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onComplete,
                child: const Text('Selesai'),
              ),
            ],
            if (r.isCompleted)
              ElevatedButton(
                onPressed: () => _showReceipt(context),
                child: const Text('Struk'),
              ),
          ]),
        ]),
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
          decoration:
              const InputDecoration(hintText: 'Catatan penolakan (opsional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onReject(ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
    }
  }

  void _showReceipt(BuildContext context) {
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
          child: ReceiptWidget(
              reservation: reservation, showUserEmail: true),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _map = {
    'pending': ('Menunggu', AppTheme.warningColor),
    'approved': ('Disetujui', AppTheme.successColor),
    'rejected': ('Ditolak', AppTheme.dangerColor),
    'cancelled': ('Dibatalkan', Color(0xFF95A5A6)),
    'completed': ('Selesai', AppTheme.primaryColor),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _map[status] ?? ('?', Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$2.withValues(alpha: 0.15),
        border: Border.all(color: cfg.$2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(cfg.$1,
          style: TextStyle(
              color: cfg.$2, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;
  const _Row(this.icon, this.text, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
