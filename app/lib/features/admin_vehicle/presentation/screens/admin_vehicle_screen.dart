import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/vehicle_model.dart';
import '../providers/admin_vehicle_provider.dart';

class AdminVehicleScreen extends ConsumerWidget {
  const AdminVehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminVehicleProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Kelola Kendaraan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/kelola/kendaraan/form'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminVehicleProvider.notifier).load(),
        child: Builder(builder: (context) {
          if (state.isLoading && state.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.vehicles.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppTheme.dangerColor),
                const SizedBox(height: 8),
                Text(state.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(adminVehicleProvider.notifier).load(),
                  child: const Text('Coba Lagi'),
                ),
              ]),
            );
          }
          if (state.vehicles.isEmpty) {
            return const Center(
              child: Text('Belum ada kendaraan.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: state.vehicles.length,
            itemBuilder: (context, index) {
              final v = state.vehicles[index];
              return _VehicleCard(
                vehicle: v,
                onEdit: () => context.push('/admin/kelola/kendaraan/form',
                    extra: v),
                onDelete: () => _confirmDelete(context, ref, v),
              );
            },
          );
        }),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, VehicleModel v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kendaraan?'),
        content: Text(
            '"${v.name}" akan dihapus. Riwayat reservasi tetap tersimpan (soft delete).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminVehicleProvider.notifier).delete(v.id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _VehicleCard(
      {required this.vehicle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final isAvailable = v.status == 'available';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          // Foto
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: v.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: v.photoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: (ctx, url, err) => _PhotoPlaceholder(),
                  )
                : _PhotoPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(v.type,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isAvailable
                              ? AppTheme.successColor
                              : AppTheme.warningColor)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      v.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                    ),
                  ),
                ]),
          ),
          Column(children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppTheme.accentColor),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.dangerColor),
              onPressed: onDelete,
            ),
          ]),
        ]),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppTheme.scaffoldBg,
      child: const Icon(Icons.local_shipping_outlined,
          size: 32, color: AppTheme.textSecondary),
    );
  }
}

