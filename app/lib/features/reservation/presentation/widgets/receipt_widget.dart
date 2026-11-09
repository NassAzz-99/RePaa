import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/models/reservation_model.dart';

/// Widget Struk Reservasi – reusable, dipakai di halaman user dan admin.
/// Spesifikasi (03_reservasi.md §C):
/// - Logo, judul, badge status, No. Reservasi, Pemohon, Unit Kerja,
///   Kendaraan, Tanggal, Batch, Jenis Kebutuhan, keterangan resmi.
class ReceiptWidget extends StatelessWidget {
  final ReservationModel reservation;
  final bool showUserEmail; // true di tampilan admin

  const ReceiptWidget({
    super.key,
    required this.reservation,
    this.showUserEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_rounded,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Struk Reservasi PAA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Peralatan Angkat & Angkut',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: reservation.status),
              ],
            ),

            const Divider(height: 24),

            // ── Detail ────────────────────────────────────
            _Row('No. Reservasi', '#${reservation.id}'),
            _Row('Pemohon', reservation.user.name),
            if (showUserEmail && reservation.user.email != null)
              _Row('Email', reservation.user.email!),
            _Row('Unit Kerja', reservation.workUnit),
            _Row('Kendaraan', reservation.vehicle.name),
            _Row('Tanggal', reservation.reservationDate),
            _Row(
              'Batch',
              '${reservation.batch.name}  (${reservation.batch.startTime}–${reservation.batch.endTime})',
            ),
            _Row('Jenis Kebutuhan', reservation.purpose),

            if (reservation.adminNote != null &&
                reservation.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Admin',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reservation.adminNote!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 24),

            // ── Keterangan resmi ─────────────────────────
            const Text(
              'Struk ini adalah bukti sah reservasi kendaraan PAA. '
              'Tunjukkan struk ini kepada petugas terkait saat pengambilan unit.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = {
      'pending': (label: 'Menunggu', color: AppTheme.warningColor),
      'approved': (label: 'Disetujui', color: AppTheme.successColor),
      'rejected': (label: 'Ditolak', color: AppTheme.dangerColor),
      'cancelled': (label: 'Dibatalkan', color: Colors.grey),
      'completed': (label: 'Selesai', color: AppTheme.primaryColor),
    };
    final c = config[status] ??
        (label: status, color: Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        c.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
