import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────

class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final int? reservationId;
  final String? readAt;
  final String createdAt;
  final String? adminNote;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.reservationId,
    this.readAt,
    required this.createdAt,
    this.adminNote,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    return NotificationModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: (j['type'] as String?) ?? 'info',
      title: (j['title'] as String?) ?? 'Notifikasi',
      message: (j['message'] as String?) ?? '',
      reservationId: (j['reservation_id'] as num?)?.toInt(),
      readAt: j['read_at'] as String?,
      createdAt: (j['created_at'] as String?) ?? '',
      adminNote: j['admin_note'] as String?,
    );
  }
}

// ── Helper Formatter ──────────────────────────────────────

String formatNotificationTime(String? rawIso) {
  if (rawIso == null || rawIso.isEmpty) return '';
  try {
    final dt = DateTime.parse(rawIso).toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  } catch (_) {
    return rawIso;
  }
}

// ── Provider ──────────────────────────────────────────────

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> items;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.items = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? items,
    int? unreadCount,
    String? errorMessage,
  }) =>
      NotificationState(
        isLoading: isLoading ?? this.isLoading,
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        errorMessage: errorMessage,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Dio _dio;
  NotificationNotifier(this._dio) : super(const NotificationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final r1 = await _dio.get('/notifications');
      final r2 = await _dio.get('/notifications/unread-count');
      final items = (r1.data['data'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
      final unread = (r2.data['data']?['unread'] as num?)?.toInt() ?? 0;
      state = state.copyWith(isLoading: false, items: items, unreadCount: unread);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } catch (_) {}
    state = state.copyWith(
      items: state.items.map((n) {
        if (n.id == id && !n.isRead) {
          return NotificationModel(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            reservationId: n.reservationId,
            readAt: DateTime.now().toIso8601String(),
            createdAt: n.createdAt,
            adminNote: n.adminNote,
          );
        }
        return n;
      }).toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, 999),
    );
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } catch (_) {}
    state = state.copyWith(
      items: state.items.map((n) => n.isRead ? n : NotificationModel(
        id: n.id,
        type: n.type,
        title: n.title,
        message: n.message,
        reservationId: n.reservationId,
        readAt: DateTime.now().toIso8601String(),
        createdAt: n.createdAt,
        adminNote: n.adminNote,
      )).toList(),
      unreadCount: 0,
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(dioProvider));
});

// ── Screen ────────────────────────────────────────────────

/// Halaman Notifikasi.
/// Sesuai spesifikasi FIX_STRUK_DAN_NOTIFIKASI.md:
/// - Notifikasi dapat diklik dan dibuka untuk membaca isi lengkapnya.
/// - Menampilkan judul, waktu (dd/MM/yyyy HH:mm), pesan penuh, dan alasan penolakan dari admin bila ada.
/// - Ditandai sudah dibaca setelah detail dibuka, dan badge unread diperbarui.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  void _openDetail(BuildContext context, WidgetRef ref, NotificationModel notif) {
    // 3. Tandai sebagai sudah dibaca setelah detail terbuka
    if (!notif.isRead) {
      ref.read(notificationProvider.notifier).markRead(notif.id);
    }

    final isRejected = notif.type == 'reservation_rejected' ||
        (notif.adminNote != null && notif.adminNote!.isNotEmpty);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isRejected
                      ? AppTheme.dangerColor.withValues(alpha: 0.12)
                      : AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.cancel_outlined : Icons.notifications_active_outlined,
                  color: isRejected ? AppTheme.dangerColor : AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatNotificationTime(notif.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 20),
                Text(
                  notif.message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.black87,
                  ),
                ),
                if (isRejected &&
                    notif.adminNote != null &&
                    notif.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.dangerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppTheme.dangerColor,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Alasan Penolakan dari Admin:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif.adminNote!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text(
                'Tandai semua dibaca',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () => ref.read(notificationProvider.notifier).load(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.items.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text(
                'Belum ada notifikasi.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ]),
          );
        }
        return ListView.separated(
          itemCount: state.items.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, i) {
            final n = state.items[i];
            return _NotifTile(
              notif: n,
              onTap: () => _openDetail(context, ref, n),
            );
          },
        );
      }),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon {
    return switch (notif.type) {
      'reservation_approved'  => Icons.check_circle_outline,
      'reservation_rejected'  => Icons.cancel_outlined,
      'reservation_completed' => Icons.flag_outlined,
      'reservation_created'   => Icons.add_circle_outline,
      _                       => Icons.notifications_outlined,
    };
  }

  Color get _iconColor {
    return switch (notif.type) {
      'reservation_approved'  => AppTheme.successColor,
      'reservation_rejected'  => AppTheme.dangerColor,
      'reservation_completed' => AppTheme.primaryColor,
      'reservation_created'   => AppTheme.accentColor,
      _                       => AppTheme.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.isRead ? null : AppTheme.accentColor.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Konten
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notif.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      formatNotificationTime(notif.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Lonceng (dipakai di AppBar dashboard) ───────────

/// Widget ikon lonceng + badge unread count.
/// Diletakkan di AppBar actions dashboard.
class NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;
  const NotificationBell({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(
      notificationProvider.select((s) => s.unreadCount),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifikasi',
          onPressed: onTap,
        ),
        if (unread > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppTheme.dangerColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
