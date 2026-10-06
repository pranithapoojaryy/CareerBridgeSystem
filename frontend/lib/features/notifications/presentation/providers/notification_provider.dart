import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';
import '../../data/notification_repository.dart';
import 'dart:async';

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(),
);

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.subscribeToNotifications().map((list) {
        return list.map((json) => NotificationModel.fromJson(json)).toList();
      });
    });

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  late NotificationRepository _repository;

  @override
  FutureOr<List<NotificationModel>> build() {
    _repository = ref.watch(notificationRepositoryProvider);
    _loadNotifications();
    return const []; // Initial empty state, _loadNotifications will update it
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      debugPrint('Notifier: Marking notification $id as read');
      await _repository.markAsRead(id);
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidate(notificationsStreamProvider);
      await _loadNotifications();
      debugPrint('Notifier: Mark as read success');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      debugPrint('Notifier: Marking ALL notifications as read');
      await _repository.markAllAsRead();
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidate(notificationsStreamProvider);
      await _loadNotifications();
      debugPrint('Notifier: Mark all as read success');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      debugPrint('Notifier: Deleting ALL notifications');
      await _repository.deleteAllNotifications();
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidate(notificationsStreamProvider);
      await _loadNotifications();
      debugPrint('Notifier: Delete all success');
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationNotifier,
      List<NotificationModel>
    >(() {
      return NotificationNotifier();
    });
