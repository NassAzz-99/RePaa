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

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.reservationId,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    return NotificationModel(
      id: j['id'] as int,
      type: j['type'] as String,
      title: j['title'] as String,
      message: j['message'] as String,
      reservationId: j['reservation_id'] as int?,
      readAt: j['read_at'] as String?,
      createdAt: j['created_at'] as String,
    );
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
      final unread = r2.data['data']['unread'] as int;
      state = state.copyWith(isLoading: false, items: items, unreadCount: unread);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markRead(int id) async {
    try { await _dio.post('/notifications/$id/read'); } catch (_) {}
    state = state.copyWith(
      items: state.items.map((n) {
        if (n.id == id && !n.isRead) {
          return NotificationModel(
            id: n.id, type: n.type, title: n.title, message: n.message,
            reservationId: n.reservationId, readAt: DateTime.now().toIso8601String(),
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList(),
      unreadCount: (state.unreadCount - 1).clamp(0, 999),
    );
  }

  Future<void> markAllRead() async {
    try { await _dio.post('/notifications/read-all'); } catch (_) {}
    state = state.copyWith(
      items: state.items.map((n) => n.isRead ? n : NotificationModel(
        id: n.id, type: n.type, title: n.title, message: n.message,
        reservationId: n.reservationId, readAt: DateTime.now().toIso8601String(),
        createdAt: n.createdAt,
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
/// Spesifikasi (05_notifikasi.md): list notifikasi, badge belum dibaca, tandai dibaca.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

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
              child: const Text('Tandai semua dibaca',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
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
              const Text('Belum ada notifikasi.',
                  style: TextStyle(color: AppTheme.textSecondary)),
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
              onTap: () {
                if (!n.isRead) {
                  ref.read(notificationProvider.notifier).markRead(n.id);
                }
              },
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
              width: 42, height: 42,
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
                  Row(children: [
                    Expanded(
                      child: Text(notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          )),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentColor, shape: BoxShape.circle,
                        ),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text(notif.message,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
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
        IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: onTap),
        if (unread > 0)
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppTheme.dangerColor, shape: BoxShape.circle,
              ),
              child: Text('$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 9)),
            ),
          ),
      ],
    );
  }
}