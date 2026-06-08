import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_model.dart';

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final hasUnreadProvider = Provider<bool>((ref) {
  return ref.watch(notificationsProvider).value?.any((n) => !n.isRead) ?? false;
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _backgroundTapSub;

  @override
  Future<List<AppNotification>> build() async {
    var stored = await _loadFromDisk();

    // Opened from terminated state via notification tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      stored = _merge(initial, stored);
      await _saveToDisk(stored);
    }

    _foregroundSub = FirebaseMessaging.onMessage.listen(_addFromRemote);
    _backgroundTapSub = FirebaseMessaging.onMessageOpenedApp.listen(_addFromRemote);

    ref.onDispose(() {
      _foregroundSub?.cancel();
      _backgroundTapSub?.cancel();
    });

    return stored;
  }

  void _addFromRemote(RemoteMessage message) {
    final current = List<AppNotification>.from(state.value ?? []);
    final updated = _merge(message, current);
    if (updated.length == current.length) return; // already stored
    state = AsyncData(updated);
    _saveToDisk(updated);
  }

  List<AppNotification> _merge(RemoteMessage message, List<AppNotification> existing) {
    final notif = message.notification;
    if (notif == null) return existing;
    final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    if (existing.any((n) => n.id == id)) return existing;
    return [
      AppNotification(
        id: id,
        title: notif.title ?? '',
        body: notif.body ?? '',
        receivedAt: DateTime.now(),
      ),
      ...existing,
    ];
  }

  Future<void> markAllRead() async {
    final current = state.value ?? [];
    if (current.every((n) => n.isRead)) return;
    final updated = current.map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncData(updated);
    await _saveToDisk(updated);
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/onda_certa_notifications.json');
  }

  Future<List<AppNotification>> _loadFromDisk() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString()) as List<dynamic>;
      return raw.cast<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToDisk(List<AppNotification> notifs) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(notifs.map((n) => n.toJson()).toList()));
    } catch (_) {}
  }
}
