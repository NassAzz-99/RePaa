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
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 160,
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
                // ── Nama & Jenis ──────────────────────────
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
                const SizedBox(height: 12),

                // ── Slots ─────────────────────────────────
                ...vehicle.slots.map(
                  (slot) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${slot.batchName}  ${slot.startTime}–${slot.endTime}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        SlotBadge(status: slot.status),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Tombol Reservasi ──────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: vehicle.isAvailable ? onReserveTap : null,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(
                      vehicle.isAvailable
                          ? 'Reservasi Kendaraan Ini'
                          : 'Tidak Tersedia',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vehicle.isAvailable
                          ? AppTheme.primaryColor
                          : Colors.grey,
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
      height: 160,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.successColor : AppTheme.warningColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAvailable ? 'Tersedia' : 'Perawatan',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
