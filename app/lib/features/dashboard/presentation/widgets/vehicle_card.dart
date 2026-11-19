import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/models/vehicle_availability_model.dart';
import 'slot_badge.dart';

/// Kartu kendaraan di dashboard.
/// Menampilkan foto, badge status kendaraan, nama, jenis, daftar slot batch.
/// Tombol Reservasi → callback ke parent.
class VehicleCard extends StatelessWidget {
  final VehicleSlotModel vehicle;
  final VoidCallback? onReserveTap; // null = disabled (maintenance)

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onReserveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Foto & Status Kendaraan ───────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: vehicle.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: vehicle.photoUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _VehicleStatusBadge(status: vehicle.status),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nama, Jenis, dan Status Kendaraan ─────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vehicle.type,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _VehicleStatusBadge(status: vehicle.status),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Label Status Slot Batch ────────────────────────
                Row(
                  children: const [
                    Icon(Icons.schedule, size: 14, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      'Status Ketersediaan Slot Batch:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Slots Tiap Batch ──────────────────────────────
                if (vehicle.slots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Belum ada batch aktif hari ini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...vehicle.slots.map(
                    (slot) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${slot.batchName} (${slot.startTime}–${slot.endTime})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SlotBadge(status: slot.status),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // ── Tombol Reservasi ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: vehicle.isAvailable ? onReserveTap : null,
                    icon: Icon(
                      vehicle.isAvailable
                          ? Icons.add_circle_outline
                          : Icons.block,
                      size: 18,
                    ),
                    label: Text(
                      vehicle.isAvailable
                          ? 'Reservasi Kendaraan Ini'
                          : 'Kendaraan Dalam Perawatan',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vehicle.isAvailable
                          ? AppTheme.primaryColor
                          : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.local_shipping_rounded,
        size: 56,
        color: Colors.grey,
      ),
    );
  }
}

class _VehicleStatusBadge extends StatelessWidget {
  final String status;
  const _VehicleStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available';
    final color = isAvailable ? AppTheme.successColor : AppTheme.warningColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Tersedia' : 'Perawatan',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
