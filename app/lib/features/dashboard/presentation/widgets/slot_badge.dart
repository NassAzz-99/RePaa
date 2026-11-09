import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Badge warna untuk status slot batch.
/// Spesifikasi: Kosong (hijau), Menunggu (kuning), Dipesan (merah)
class SlotBadge extends StatelessWidget {
  final String status; // 'empty' | 'pending' | 'booked'

  const SlotBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config[status] ?? _config['empty']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        border: Border.all(color: config.color, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static const _config = {
    'empty': _SlotConfig(label: 'Kosong', color: AppTheme.successColor),
    'pending': _SlotConfig(label: 'Menunggu', color: AppTheme.warningColor),
    'booked': _SlotConfig(label: 'Dipesan', color: AppTheme.dangerColor),
  };
}

class _SlotConfig {
  final String label;
  final Color color;
  const _SlotConfig({required this.label, required this.color});
}
