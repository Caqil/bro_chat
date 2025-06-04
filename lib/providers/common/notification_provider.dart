import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/storage/local_storage.dart';
import '../../services/notification/notification_handler.dart';
import '../../services/api/api_service.dart';

class NotificationSettings {
  final bool enabled;
  final bool messageNotifications;
  final bool callNotifications;
  final bool groupNotifications;
  final bool statusNotifications;
  final bool systemNotifications;
  final bool reactionNotifications;
  final bool mentionNotifications;
  final bool doNotDisturb;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool vibration;
  final bool sound;
  final String soundName;
  final bool badge;
  final bool preview;
  final bool lightScreen;
  final Map<String, bool> chatMutes;
  final Map<String, bool> groupMutes;
  final Map<String, DateTime> mutedUntil;

  NotificationSettings({
    this.enabled = true,
    this.messageNotifications = true,
    this.callNotifications = true,
    this.groupNotifications = true,
    this.statusNotifications = true,
    this.systemNotifications = true,
    this.reactionNotifications = false,
    this.mentionNotifications = true,
    this.doNotDisturb = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.vibration = true,
    this.sound = true,
    this.soundName = 'default',
    this.badge = true,
    this.preview = true,
    this.lightScreen = false,
    this.chatMutes = const {},
    this.groupMutes = const {},
    this.mutedUntil = const {},
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? messageNotifications,
    bool? callNotifications,
    bool? groupNotifications,
    bool? statusNotifications,
    bool? systemNotifications,
    bool? reactionNotifications,
    bool? mentionNotifications,
    bool? doNotDisturb,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? vibration,
    bool? sound,
    String? soundName,
    bool? badge,
    bool? preview,
    bool? lightScreen,
    Map<String, bool>? chatMutes,
    Map<String, bool>? groupMutes,
    Map<String, DateTime>? mutedUntil,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      callNotifications: callNotifications ?? this.callNotifications,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      statusNotifications: statusNotifications ?? this.statusNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      reactionNotifications:
          reactionNotifications ?? this.reactionNotifications,
      mentionNotifications: mentionNotifications ?? this.mentionNotifications,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      vibration: vibration ?? this.vibration,
      sound: sound ?? this.sound,
      soundName: soundName ?? this.soundName,
      badge: badge ?? this.badge,
      preview: preview ?? this.preview,
      lightScreen: lightScreen ?? this.lightScreen,
      chatMutes: chatMutes ?? this.chatMutes,
      groupMutes: groupMutes ?? this.groupMutes,
      mutedUntil: mutedUntil ?? this.mutedUntil,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'message_notifications': messageNotifications,
      'call_notifications': callNotifications,
      'group_notifications': groupNotifications,
      'status_notifications': statusNotifications,
      'system_notifications': systemNotifications,
      'reaction_notifications': reactionNotifications,
      'mention_notifications': mentionNotifications,
      'do_not_disturb': doNotDisturb,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'vibration': vibration,
      'sound': sound,
      'sound_name': soundName,
      'badge': badge,
      'preview': preview,
      'light_screen': lightScreen,
      'chat_mutes': chatMutes,
      'group_mutes': groupMutes,
      'muted_until': mutedUntil.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final mutedUntilMap = <String, DateTime>{};
    final rawMutedUntil = json['muted_until'] as Map<String, dynamic>? ?? {};
    for (final entry in rawMutedUntil.entries) {
      final dateTime = DateTime.tryParse(entry.value as String);
      if (dateTime != null) {
        mutedUntilMap[entry.key] = dateTime;
      }
    }

    return NotificationSettings(
      enabled: json['enabled'] ?? true,
      messageNotifications: json['message_notifications'] ?? true,
      callNotifications: json['call_notifications'] ?? true,
      groupNotifications: json['group_notifications'] ?? true,
      statusNotifications: json['status_notifications'] ?? true,
      systemNotifications: json['system_notifications'] ?? true,
      reactionNotifications: json['reaction_notifications'] ?? false,
      mentionNotifications: json['mention_notifications'] ?? true,
      doNotDisturb: json['do_not_disturb'] ?? false,
      quietHoursStart: json['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] ?? '07:00',
      vibration: json['vibration'] ?? true,
      sound: json['sound'] ?? true,
      soundName: json['sound_name'] ?? 'default',
      badge: json['badge'] ?? true,
      preview: json['preview'] ?? true,
      lightScreen: json['light_screen'] ?? false,
      chatMutes: Map<String, bool>.from(json['chat_mutes'] ?? {}),
      groupMutes: Map<String, bool>.from(json['group_mutes'] ?? {}),
      mutedUntil: mutedUntilMap,
    );
  }

  bool isChatMuted(String chatId) {
    if (chatMutes[chatId] == true) {
      final mutedUntilTime = mutedUntil[chatId];
      if (mutedUntilTime != null && DateTime.now().isAfter(mutedUntilTime)) {
        return false; // Mute has expired
      }
      return true;
    }
    return false;
  }

  bool isGroupMuted(String groupId) {
    if (groupMutes[groupId] == true) {
      final mutedUntilTime = mutedUntil[groupId];
      if (mutedUntilTime != null && DateTime.now().isAfter(mutedUntilTime)) {
        return false; // Mute has expired
      }
      return true;
    }
    return false;
  }

  bool get isQuietHoursActive {
    if (!doNotDisturb) return false;

    final now = TimeOfDay.now();
    final startTime = _parseTimeOfDay(quietHoursStart);
    final endTime = _parseTimeOfDay(quietHoursEnd);

    if (startTime == null || endTime == null) return false;

    // Handle overnight quiet hours (e.g., 22:00 to 07:00)
    if (startTime.hour > endTime.hour) {
      return now.hour >= startTime.hour || now.hour < endTime.hour;
    } else {
      return now.hour >= startTime.hour && now.hour < endTime.hour;
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error parsing time: $timeString');
    }
    return null;
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  static TimeOfDay now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }
}

class NotificationState {
  final NotificationSettings settings;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final bool permissionGranted;
  final int unreadCount;
  final Map<String, int> chatUnreadCounts;
  final List<NotificationData> recentNotifications;
  final DateTime? lastSettingsUpdate;

  NotificationState({
    NotificationSettings? settings,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.permissionGranted = false,
    this.unreadCount = 0,
    this.chatUnreadCounts = const {},
    this.recentNotifications = const [],
    this.lastSettingsUpdate,
  }) : settings = settings ?? NotificationSettings();

  NotificationState copyWith({
    NotificationSettings? settings,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool? permissionGranted,
    int? unreadCount,
    Map<String, int>? chatUnreadCounts,
    List<NotificationData>? recentNotifications,
    DateTime? lastSettingsUpdate,
  }) {
    return NotificationState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      unreadCount: unreadCount ?? this.unreadCount,
      chatUnreadCounts: chatUnreadCounts ?? this.chatUnreadCounts,
      recentNotifications: recentNotifications ?? this.recentNotifications,
      lastSettingsUpdate: lastSettingsUpdate ?? this.lastSettingsUpdate,
    );
  }
}

class NotificationNotifier
    extends StateNotifier<AsyncValue<NotificationState>> {
  final LocalStorage _localStorage;
  final NotificationHandler _notificationHandler;
  final ApiService _apiService;

  StreamSubscription<NotificationData>? _notificationSubscription;
  Timer? _unreadCountTimer;

  NotificationNotifier({
    required LocalStorage localStorage,
    required NotificationHandler notificationHandler,
    required ApiService apiService,
  }) : _localStorage = localStorage,
       _notificationHandler = notificationHandler,
       _apiService = apiService,
       super(AsyncValue.data(NotificationState())) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _loadSettings();
      await _checkPermission();
      _setupNotificationListener();
      _startUnreadCountUpdater();

      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, isInitialized: true),
      );

      if (kDebugMode) print('✅ Notification provider initialized');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing notification provider: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settingsData = _localStorage.getNotificationSettings();
      final settings = NotificationSettings.fromJson(settingsData);

      state = AsyncValue.data(
        state.value!.copyWith(
          settings: settings,
          lastSettingsUpdate: DateTime.now(),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error loading notification settings: $e');
    }
  }

  Future<void> _checkPermission() async {
    try {
      // Check notification permission status
      // This would depend on your permission handling implementation
      const permissionGranted = true; // Placeholder

      state = AsyncValue.data(
        state.value!.copyWith(permissionGranted: permissionGranted),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error checking notification permission: $e');
    }
  }

  void _setupNotificationListener() {
    _notificationSubscription = _notificationHandler.notificationStream.listen(
      _handleNotification,
      onError: (error) {
        if (kDebugMode) print('❌ Notification stream error: $error');
      },
    );
  }

  void _handleNotification(NotificationData notification) {
    state.whenData((notificationState) {
      final updatedRecentNotifications = [
        notification,
        ...notificationState.recentNotifications,
      ].take(50).toList(); // Keep only last 50 notifications

      // Update unread count
      var updatedUnreadCount = notificationState.unreadCount + 1;
      var updatedChatUnreadCounts = Map<String, int>.from(
        notificationState.chatUnreadCounts,
      );

      if (notification.data.containsKey('chat_id')) {
        final chatId = notification.data['chat_id'] as String;
        updatedChatUnreadCounts[chatId] =
            (updatedChatUnreadCounts[chatId] ?? 0) + 1;
      }

      state = AsyncValue.data(
        notificationState.copyWith(
          unreadCount: updatedUnreadCount,
          chatUnreadCounts: updatedChatUnreadCounts,
          recentNotifications: updatedRecentNotifications,
        ),
      );
    });
  }

  void _startUnreadCountUpdater() {
    _unreadCountTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateUnreadCounts(),
    );
  }

  Future<void> _updateUnreadCounts() async {
    try {
      // You can implement API call to get actual unread counts
      // For now, we'll keep the current implementation
    } catch (e) {
      if (kDebugMode) print('❌ Error updating unread counts: $e');
    }
  }

  // Public methods
  Future<void> updateSettings(NotificationSettings settings) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));

      // Save to local storage
      await _localStorage.setNotificationSettings(settings.toJson());

      // Update notification handler
      await _notificationHandler.updateNotificationSettings(settings.toJson());

      // Sync with server
      await _syncSettingsWithServer(settings);

      state = AsyncValue.data(
        state.value!.copyWith(
          settings: settings,
          isLoading: false,
          lastSettingsUpdate: DateTime.now(),
        ),
      );

      if (kDebugMode) print('✅ Notification settings updated');
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error updating notification settings: $e');
      rethrow;
    }
  }

  Future<void> _syncSettingsWithServer(NotificationSettings settings) async {
    try {
      // Implement API call to sync settings with server
      await _apiService.updateNotificationSettings(settings.toJson());
    } catch (e) {
      if (kDebugMode) print('❌ Error syncing settings with server: $e');
    }
  }

  Future<void> muteChatNotifications(
    String chatId, {
    DateTime? mutedUntil,
  }) async {
    try {
      final currentSettings = state.value!.settings;
      final updatedChatMutes = Map<String, bool>.from(
        currentSettings.chatMutes,
      );
      final updatedMutedUntil = Map<String, DateTime>.from(
        currentSettings.mutedUntil,
      );

      updatedChatMutes[chatId] = true;
      if (mutedUntil != null) {
        updatedMutedUntil[chatId] = mutedUntil;
      }

      final updatedSettings = currentSettings.copyWith(
        chatMutes: updatedChatMutes,
        mutedUntil: updatedMutedUntil,
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      if (kDebugMode) print('❌ Error muting chat notifications: $e');
      rethrow;
    }
  }

  Future<void> unmuteChatNotifications(String chatId) async {
    try {
      final currentSettings = state.value!.settings;
      final updatedChatMutes = Map<String, bool>.from(
        currentSettings.chatMutes,
      );
      final updatedMutedUntil = Map<String, DateTime>.from(
        currentSettings.mutedUntil,
      );

      updatedChatMutes.remove(chatId);
      updatedMutedUntil.remove(chatId);

      final updatedSettings = currentSettings.copyWith(
        chatMutes: updatedChatMutes,
        mutedUntil: updatedMutedUntil,
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      if (kDebugMode) print('❌ Error unmuting chat notifications: $e');
      rethrow;
    }
  }

  Future<void> muteGroupNotifications(
    String groupId, {
    DateTime? mutedUntil,
  }) async {
    try {
      final currentSettings = state.value!.settings;
      final updatedGroupMutes = Map<String, bool>.from(
        currentSettings.groupMutes,
      );
      final updatedMutedUntil = Map<String, DateTime>.from(
        currentSettings.mutedUntil,
      );

      updatedGroupMutes[groupId] = true;
      if (mutedUntil != null) {
        updatedMutedUntil[groupId] = mutedUntil;
      }

      final updatedSettings = currentSettings.copyWith(
        groupMutes: updatedGroupMutes,
        mutedUntil: updatedMutedUntil,
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      if (kDebugMode) print('❌ Error muting group notifications: $e');
      rethrow;
    }
  }

  Future<void> unmuteGroupNotifications(String groupId) async {
    try {
      final currentSettings = state.value!.settings;
      final updatedGroupMutes = Map<String, bool>.from(
        currentSettings.groupMutes,
      );
      final updatedMutedUntil = Map<String, DateTime>.from(
        currentSettings.mutedUntil,
      );

      updatedGroupMutes.remove(groupId);
      updatedMutedUntil.remove(groupId);

      final updatedSettings = currentSettings.copyWith(
        groupMutes: updatedGroupMutes,
        mutedUntil: updatedMutedUntil,
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      if (kDebugMode) print('❌ Error unmuting group notifications: $e');
      rethrow;
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      state.whenData((notificationState) {
        final updatedChatUnreadCounts = Map<String, int>.from(
          notificationState.chatUnreadCounts,
        );
        final previousCount = updatedChatUnreadCounts[chatId] ?? 0;
        updatedChatUnreadCounts[chatId] = 0;

        final updatedUnreadCount =
            notificationState.unreadCount - previousCount;

        state = AsyncValue.data(
          notificationState.copyWith(
            unreadCount: updatedUnreadCount.clamp(0, double.infinity).toInt(),
            chatUnreadCounts: updatedChatUnreadCounts,
          ),
        );
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error marking chat as read: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _notificationHandler.clearAllNotifications();

      state.whenData((notificationState) {
        state = AsyncValue.data(
          notificationState.copyWith(
            unreadCount: 0,
            chatUnreadCounts: {},
            recentNotifications: [],
          ),
        );
      });

      if (kDebugMode) print('✅ All notifications cleared');
    } catch (e) {
      if (kDebugMode) print('❌ Error clearing notifications: $e');
      rethrow;
    }
  }

  Future<void> testNotification() async {
    try {
      await _notificationHandler.testNotification(
        title: 'Test Notification',
        body: 'This is a test notification from BRO Chat',
        type: NotificationType.message,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  Future<void> requestPermission() async {
    try {
      // Implement permission request logic
      // This would depend on your permission handling implementation
      state.whenData((notificationState) {
        state = AsyncValue.data(
          notificationState.copyWith(permissionGranted: true),
        );
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error requesting notification permission: $e');
      rethrow;
    }
  }

  // Getters
  NotificationSettings get settings =>
      state.value?.settings ?? NotificationSettings();
  bool get isLoading => state.value?.isLoading ?? false;
  bool get permissionGranted => state.value?.permissionGranted ?? false;
  int get unreadCount => state.value?.unreadCount ?? 0;
  Map<String, int> get chatUnreadCounts => state.value?.chatUnreadCounts ?? {};

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _unreadCountTimer?.cancel();
    super.dispose();
  }
}

// Providers
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<NotificationState>>((
      ref,
    ) {
      return NotificationNotifier(
        localStorage: LocalStorage(),
        notificationHandler: NotificationHandler(),
        apiService: ref.watch(apiServiceProvider),
      );
    });

// Convenience providers
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.whenOrNull(data: (state) => state.settings) ??
      NotificationSettings();
});

final notificationLoadingProvider = Provider<bool>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.whenOrNull(data: (state) => state.isLoading) ??
      false;
});

final notificationPermissionProvider = Provider<bool>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.whenOrNull(
        data: (state) => state.permissionGranted,
      ) ??
      false;
});

final totalUnreadCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.whenOrNull(data: (state) => state.unreadCount) ?? 0;
});

final chatUnreadCountProvider = Provider.family<int, String>((ref, chatId) {
  final notificationState = ref.watch(notificationProvider);
  final chatUnreadCounts =
      notificationState.whenOrNull(data: (state) => state.chatUnreadCounts) ??
      {};
  return chatUnreadCounts[chatId] ?? 0;
});

final isChatMutedProvider = Provider.family<bool, String>((ref, chatId) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.isChatMuted(chatId);
});

final isGroupMutedProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.isGroupMuted(groupId);
});

final isQuietHoursActiveProvider = Provider<bool>((ref) {
  final settings = ref.watch(notificationSettingsProvider);
  return settings.isQuietHoursActive;
});

final recentNotificationsProvider = Provider<List<NotificationData>>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.whenOrNull(
        data: (state) => state.recentNotifications,
      ) ??
      [];
});
