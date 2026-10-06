import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPopoverNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void open() {
    state = true;
  }

  void close() {
    state = false;
  }
}

final notificationPopoverProvider =
    NotifierProvider<NotificationPopoverNotifier, bool>(() {
      return NotificationPopoverNotifier();
    });
