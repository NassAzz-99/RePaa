import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../reservation/data/models/reservation_model.dart';
import '../../../reservation/presentation/widgets/receipt_widget.dart';
import '../providers/admin_reservation_provider.dart';

/// Halaman Kelola Reservasi Administrator.
/// Sesuai spesifikasi FIX_RESPONSIVE_MOBILE_RESERVASI.md:
/// - Desktop (>= 700px): Tabel lebar DataTable (tidak diubah).
/// - Mobile (< 700px): Daftar Card format 'label: nilai' berurutan ke bawah.
/// - Menunggu: Tombol Setujui dan Tolak sejajar dan sama lebar.
/// - Disetujui: Tombol Struk dan Selesai.
/// - Selesai: Tombol Struk.
/// - Ditolak: Tanpa tombol aksi, tampilkan alasan penolakan.
/// - Tolak dengan Alasan: AlertDialog wajib minimal 5 karakter & cegah double click.
/// - Tidak ada overflow di 360px.
class AdminReservationScreen extends ConsumerStatefulWidget {
  const AdminReservationScreen({super.key});

  @override
  ConsumerState<AdminReservationScreen> createState() =>
      _AdminReservationScreenState();
}

class _AdminReservationScreenState
    extends ConsumerState<AdminReservationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminReservationProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReservationProvider);

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
                onPressed: () => ref.read(adminReservationProvider.notifier).load(),
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
                child: Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada permohonan reservasi.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.filter.isActive
                    ? 'Tidak ada data reservasi yang sesuai dengan filter.'
                    : 'Permohonan reservasi dari pengguna akan muncul di sini.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              if (state.filter.isActive) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => ref.read(adminReservationProvider.notifier).clearFilter(),
                  icon: const Icon(Icons.filter_alt_off, size: 16),
                  label: const Text('Reset Filter'),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            // ── Mobile View (< 700px): Card List (label: nilai) ───
            return RefreshIndicator(
              onRefresh: () => ref.read(adminReservationProvider.notifier).load(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.reservations.length,
                itemBuilder: (context, index) {
                  final r = state.reservations[index];
                  return _buildAdminMobileCard(r);
                },
              ),
            );
          } else {
            // ── Desktop View (>= 700px): Tabel Lebar DataTable (tetap) ─
            return RefreshIndicator(
              onRefresh: () => ref.read(adminReservationProvider.notifier).load(),
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
                          DataColumn(label: Text('Pemohon', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Unit Kerja', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Kendaraan', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Tanggal & Batch', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Jenis Kebutuhan', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: state.reservations.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(r.user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(r.user.email ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              )),
                              DataCell(Text(r.workUnit)),
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(r.vehicle.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(r.vehicle.type, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              )),
                              DataCell(Text('${r.reservationDate} · ${r.batch.name} (${r.batch.startTime}–${r.batch.endTime})')),
                              DataCell(Text(r.purpose.length > 25 ? '${r.purpose.substring(0, 25)}...' : r.purpose)),
                              DataCell(_StatusBadge(status: r.status)),
                              DataCell(_buildAdminTableActionButtons(r)),
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
        title: const Text('Kelola Reservasi'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter Reservasi',
                onPressed: () => _showFilterSheet(context, state.filter),
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
            tooltip: 'Segarkan',
            onPressed: () => ref.read(adminReservationProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.filter.isActive) _buildActiveFilterBanner(state.filter),
          Expanded(child: content),
        ],
      ),
    );
  }

  // ── Banner Filter Aktif ───────────────────────────────────
  Widget _buildActiveFilterBanner(AdminReservationFilter filter) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filter aktif: ${[
                if (filter.status != null && filter.status != 'all') 'Status: ${filter.status}',
                if (filter.date != null && filter.date!.isNotEmpty) 'Tgl: ${filter.date}',
                if (filter.workUnit != null && filter.workUnit!.isNotEmpty) 'Unit: ${filter.workUnit}',
              ].join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(adminReservationProvider.notifier).clearFilter(),
            child: const Text('Reset', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Card Widget untuk Mobile Sesuai Bagian 2 (Format label: nilai) ──
  Widget _buildAdminMobileCard(ReservationModel r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdminLabelValueRow(
              label: 'Pemohon',
              value: '${r.user.name} (${r.user.email ?? '-'})',
            ),
            const SizedBox(height: 8),
            _AdminLabelValueRow(label: 'Unit Kerja', value: r.workUnit),
            const SizedBox(height: 8),
            _AdminLabelValueRow(
              label: 'Kendaraan',
              value: '${r.vehicle.name} (${r.vehicle.type})',
            ),
            const SizedBox(height: 8),
            _AdminLabelValueRow(
              label: 'Tanggal dan Batch',
              value: '${r.reservationDate} · ${r.batch.name} (${r.batch.startTime}–${r.batch.endTime})',
            ),
            const SizedBox(height: 8),
            _AdminLabelValueRow(label: 'Jenis Kebutuhan', value: r.purpose),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 125,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Text(': ', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                _StatusBadge(status: r.status),
              ],
            ),
            if (r.status == 'rejected' && r.adminNote != null && r.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                ),
                child: _AdminLabelValueRow(
                  label: 'Alasan Penolakan',
                  value: r.adminNote!,
                  valueColor: AppTheme.dangerColor,
                ),
              ),
            ],
            // Aksi dinamis di bagian bawah kartu
            if (r.isPending) ...[
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showRejectDialog(r.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerColor,
                        side: const BorderSide(color: AppTheme.dangerColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(adminReservationProvider.notifier).approve(r.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Setuju'),
                    ),
                  ),
                ],
              ),
            ] else if (r.isApproved) ...[
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReceipt(r),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('Struk'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(adminReservationProvider.notifier).complete(r.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (r.isCompleted) ...[
              const Divider(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReceipt(r),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Struk'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tombol Aksi Tabel Desktop ─────────────────────────────
  Widget _buildAdminTableActionButtons(ReservationModel r) {
    if (r.isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => _showRejectDialog(r.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.dangerColor,
              side: const BorderSide(color: AppTheme.dangerColor),
            ),
            child: const Text('Tolak'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => ref.read(adminReservationProvider.notifier).approve(r.id),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('Setuju'),
          ),
        ],
      );
    }
    if (r.isApproved) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => _showReceipt(r),
            child: const Text('Struk'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => ref.read(adminReservationProvider.notifier).complete(r.id),
            child: const Text('Selesai'),
          ),
        ],
      );
    }
    if (r.isCompleted) {
      return ElevatedButton(
        onPressed: () => _showReceipt(r),
        child: const Text('Struk'),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Dialog Tolak dengan Validasi Min 5 Karakter & Anti Double Click ──
  Future<void> _showRejectDialog(int id) async {
    final ctrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final text = ctrl.text.trim();
          final isValid = text.length >= 5;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Tolak Reservasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan alasan penolakan (wajib diisi, minimal 5 karakter):',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  autofocus: true,
                  enabled: !isSubmitting,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Kendaraan sedang dalam pemeliharaan berkala.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                    errorText: (text.isNotEmpty && !isValid)
                        ? 'Alasan minimal 5 karakter (${text.length}/5)'
                        : null,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: (!isValid || isSubmitting)
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          await ref
                              .read(adminReservationProvider.notifier)
                              .reject(id, text);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (_) {
                          if (ctx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kirim Penolakan'),
              ),
            ],
          );
        },
      ),
    );
    ctrl.dispose();
  }

  // ── Filter BottomSheet ────────────────────────────────────
  void _showFilterSheet(BuildContext context, AdminReservationFilter current) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Reservasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: status ?? 'all',
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Menunggu Persetujuan')),
                  DropdownMenuItem(value: 'approved', child: Text('Disetujui')),
                  DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
                  DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                ],
                onChanged: (v) => setModal(() => status = (v == 'all' ? null : v)),
              ),
              const SizedBox(height: 12),
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
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    suffixIcon: date != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setModal(() => date = null),
                          )
                        : null,
                  ),
                  child: Text(
                    date ?? 'Semua tanggal',
                    style: TextStyle(
                      color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: workUnitCtrl,
                decoration: const InputDecoration(labelText: 'Unit Kerja'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(adminReservationProvider.notifier).clearFilter();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => workUnitCtrl.dispose());
  }

  void _showReceipt(ReservationModel reservation) {
    ReceiptWidget.show(context, reservation, showUserEmail: true);
  }
}

class _AdminLabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _AdminLabelValueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _map = {
    'pending': ('Menunggu Persetujuan', AppTheme.warningColor),
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
      child: Text(
        cfg.$1,
        style: TextStyle(color: cfg.$2, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
