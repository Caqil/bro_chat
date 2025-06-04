import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/api/api_service.dart';
import '../../services/storage/cache_service.dart';
import '../../models/group/group_settings.dart';
import '../../models/common/api_response.dart';
import 'group_provider.dart';

enum MessagePermission {
  everyone,
  adminsOnly,
  moderatorsAndAdmins,
  membersOnly,
  disabled,
}

enum MediaPermission {
  everyone,
  adminsOnly,
  moderatorsAndAdmins,
  membersOnly,
  disabled,
}

enum MemberAddPermission { everyone, adminsOnly, moderatorsAndAdmins, disabled }

enum GroupInfoEditPermission { adminsOnly, moderatorsAndAdmins, disabled }

enum SlowModeInterval {
  disabled,
  seconds30,
  minutes1,
  minutes5,
  minutes15,
  minutes60,
}

class GroupSettingsData {
  final bool allowMessages;
  final bool allowMedia;
  final bool allowVoiceMessages;
  final bool allowStickers;
  final bool allowGifs;
  final bool allowPolls;
  final bool allowFiles;
  final bool allowLinks;
  final bool allowForwarding;
  final bool allowPinning;
  final bool allowReactions;
  final bool allowMentions;
  final bool allowReplies;
  final bool autoDeleteMessages;
  final Duration? autoDeleteDuration;
  final bool enableSlowMode;
  final SlowModeInterval slowModeInterval;
  final MessagePermission messagePermission;
  final MediaPermission mediaPermission;
  final MemberAddPermission memberAddPermission;
  final GroupInfoEditPermission groupInfoEditPermission;
  final bool requireApprovalToJoin;
  final bool allowInviteLinks;
  final bool showMemberCount;
  final bool showOnlineCount;
  final bool showLastSeen;
  final bool allowMemberSearch;
  final bool enableReadReceipts;
  final bool enableTypingIndicators;
  final bool enableDeliveryReceipts;
  final bool allowScreenshots;
  final bool protectContent;
  final bool enableBroadcastMode;
  final bool restrictSavingContent;
  final int maxPinnedMessages;
  final int maxFileSize; // in bytes
  final Duration messageHistoryVisibility;
  final List<String> bannedWords;
  final bool enableWordFilter;
  final bool enableAntiSpam;
  final Map<String, dynamic>? customSettings;

  GroupSettingsData({
    this.allowMessages = true,
    this.allowMedia = true,
    this.allowVoiceMessages = true,
    this.allowStickers = true,
    this.allowGifs = true,
    this.allowPolls = true,
    this.allowFiles = true,
    this.allowLinks = true,
    this.allowForwarding = true,
    this.allowPinning = true,
    this.allowReactions = true,
    this.allowMentions = true,
    this.allowReplies = true,
    this.autoDeleteMessages = false,
    this.autoDeleteDuration,
    this.enableSlowMode = false,
    this.slowModeInterval = SlowModeInterval.disabled,
    this.messagePermission = MessagePermission.everyone,
    this.mediaPermission = MediaPermission.everyone,
    this.memberAddPermission = MemberAddPermission.adminsOnly,
    this.groupInfoEditPermission = GroupInfoEditPermission.adminsOnly,
    this.requireApprovalToJoin = false,
    this.allowInviteLinks = true,
    this.showMemberCount = true,
    this.showOnlineCount = true,
    this.showLastSeen = true,
    this.allowMemberSearch = true,
    this.enableReadReceipts = true,
    this.enableTypingIndicators = true,
    this.enableDeliveryReceipts = true,
    this.allowScreenshots = true,
    this.protectContent = false,
    this.enableBroadcastMode = false,
    this.restrictSavingContent = false,
    this.maxPinnedMessages = 10,
    this.maxFileSize = 100 * 1024 * 1024, // 100MB
    this.messageHistoryVisibility = const Duration(days: 365),
    this.bannedWords = const [],
    this.enableWordFilter = false,
    this.enableAntiSpam = false,
    this.customSettings,
  });

  GroupSettingsData copyWith({
    bool? allowMessages,
    bool? allowMedia,
    bool? allowVoiceMessages,
    bool? allowStickers,
    bool? allowGifs,
    bool? allowPolls,
    bool? allowFiles,
    bool? allowLinks,
    bool? allowForwarding,
    bool? allowPinning,
    bool? allowReactions,
    bool? allowMentions,
    bool? allowReplies,
    bool? autoDeleteMessages,
    Duration? autoDeleteDuration,
    bool? enableSlowMode,
    SlowModeInterval? slowModeInterval,
    MessagePermission? messagePermission,
    MediaPermission? mediaPermission,
    MemberAddPermission? memberAddPermission,
    GroupInfoEditPermission? groupInfoEditPermission,
    bool? requireApprovalToJoin,
    bool? allowInviteLinks,
    bool? showMemberCount,
    bool? showOnlineCount,
    bool? showLastSeen,
    bool? allowMemberSearch,
    bool? enableReadReceipts,
    bool? enableTypingIndicators,
    bool? enableDeliveryReceipts,
    bool? allowScreenshots,
    bool? protectContent,
    bool? enableBroadcastMode,
    bool? restrictSavingContent,
    int? maxPinnedMessages,
    int? maxFileSize,
    Duration? messageHistoryVisibility,
    List<String>? bannedWords,
    bool? enableWordFilter,
    bool? enableAntiSpam,
    Map<String, dynamic>? customSettings,
  }) {
    return GroupSettingsData(
      allowMessages: allowMessages ?? this.allowMessages,
      allowMedia: allowMedia ?? this.allowMedia,
      allowVoiceMessages: allowVoiceMessages ?? this.allowVoiceMessages,
      allowStickers: allowStickers ?? this.allowStickers,
      allowGifs: allowGifs ?? this.allowGifs,
      allowPolls: allowPolls ?? this.allowPolls,
      allowFiles: allowFiles ?? this.allowFiles,
      allowLinks: allowLinks ?? this.allowLinks,
      allowForwarding: allowForwarding ?? this.allowForwarding,
      allowPinning: allowPinning ?? this.allowPinning,
      allowReactions: allowReactions ?? this.allowReactions,
      allowMentions: allowMentions ?? this.allowMentions,
      allowReplies: allowReplies ?? this.allowReplies,
      autoDeleteMessages: autoDeleteMessages ?? this.autoDeleteMessages,
      autoDeleteDuration: autoDeleteDuration ?? this.autoDeleteDuration,
      enableSlowMode: enableSlowMode ?? this.enableSlowMode,
      slowModeInterval: slowModeInterval ?? this.slowModeInterval,
      messagePermission: messagePermission ?? this.messagePermission,
      mediaPermission: mediaPermission ?? this.mediaPermission,
      memberAddPermission: memberAddPermission ?? this.memberAddPermission,
      groupInfoEditPermission:
          groupInfoEditPermission ?? this.groupInfoEditPermission,
      requireApprovalToJoin:
          requireApprovalToJoin ?? this.requireApprovalToJoin,
      allowInviteLinks: allowInviteLinks ?? this.allowInviteLinks,
      showMemberCount: showMemberCount ?? this.showMemberCount,
      showOnlineCount: showOnlineCount ?? this.showOnlineCount,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      allowMemberSearch: allowMemberSearch ?? this.allowMemberSearch,
      enableReadReceipts: enableReadReceipts ?? this.enableReadReceipts,
      enableTypingIndicators:
          enableTypingIndicators ?? this.enableTypingIndicators,
      enableDeliveryReceipts:
          enableDeliveryReceipts ?? this.enableDeliveryReceipts,
      allowScreenshots: allowScreenshots ?? this.allowScreenshots,
      protectContent: protectContent ?? this.protectContent,
      enableBroadcastMode: enableBroadcastMode ?? this.enableBroadcastMode,
      restrictSavingContent:
          restrictSavingContent ?? this.restrictSavingContent,
      maxPinnedMessages: maxPinnedMessages ?? this.maxPinnedMessages,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      messageHistoryVisibility:
          messageHistoryVisibility ?? this.messageHistoryVisibility,
      bannedWords: bannedWords ?? this.bannedWords,
      enableWordFilter: enableWordFilter ?? this.enableWordFilter,
      enableAntiSpam: enableAntiSpam ?? this.enableAntiSpam,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  Duration get slowModeDuration {
    switch (slowModeInterval) {
      case SlowModeInterval.seconds30:
        return const Duration(seconds: 30);
      case SlowModeInterval.minutes1:
        return const Duration(minutes: 1);
      case SlowModeInterval.minutes5:
        return const Duration(minutes: 5);
      case SlowModeInterval.minutes15:
        return const Duration(minutes: 15);
      case SlowModeInterval.minutes60:
        return const Duration(minutes: 60);
      case SlowModeInterval.disabled:
      default:
        return Duration.zero;
    }
  }

  String get maxFileSizeFormatted {
    if (maxFileSize < 1024) return '$maxFileSize B';
    if (maxFileSize < 1024 * 1024)
      return '${(maxFileSize / 1024).toStringAsFixed(1)} KB';
    if (maxFileSize < 1024 * 1024 * 1024)
      return '${(maxFileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(maxFileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_messages': allowMessages,
      'allow_media': allowMedia,
      'allow_voice_messages': allowVoiceMessages,
      'allow_stickers': allowStickers,
      'allow_gifs': allowGifs,
      'allow_polls': allowPolls,
      'allow_files': allowFiles,
      'allow_links': allowLinks,
      'allow_forwarding': allowForwarding,
      'allow_pinning': allowPinning,
      'allow_reactions': allowReactions,
      'allow_mentions': allowMentions,
      'allow_replies': allowReplies,
      'auto_delete_messages': autoDeleteMessages,
      'auto_delete_duration': autoDeleteDuration?.inMilliseconds,
      'enable_slow_mode': enableSlowMode,
      'slow_mode_interval': slowModeInterval.name,
      'message_permission': messagePermission.name,
      'media_permission': mediaPermission.name,
      'member_add_permission': memberAddPermission.name,
      'group_info_edit_permission': groupInfoEditPermission.name,
      'require_approval_to_join': requireApprovalToJoin,
      'allow_invite_links': allowInviteLinks,
      'show_member_count': showMemberCount,
      'show_online_count': showOnlineCount,
      'show_last_seen': showLastSeen,
      'allow_member_search': allowMemberSearch,
      'enable_read_receipts': enableReadReceipts,
      'enable_typing_indicators': enableTypingIndicators,
      'enable_delivery_receipts': enableDeliveryReceipts,
      'allow_screenshots': allowScreenshots,
      'protect_content': protectContent,
      'enable_broadcast_mode': enableBroadcastMode,
      'restrict_saving_content': restrictSavingContent,
      'max_pinned_messages': maxPinnedMessages,
      'max_file_size': maxFileSize,
      'message_history_visibility': messageHistoryVisibility.inMilliseconds,
      'banned_words': bannedWords,
      'enable_word_filter': enableWordFilter,
      'enable_anti_spam': enableAntiSpam,
      'custom_settings': customSettings,
    };
  }

  factory GroupSettingsData.fromJson(Map<String, dynamic> json) {
    return GroupSettingsData(
      allowMessages: json['allow_messages'] ?? true,
      allowMedia: json['allow_media'] ?? true,
      allowVoiceMessages: json['allow_voice_messages'] ?? true,
      allowStickers: json['allow_stickers'] ?? true,
      allowGifs: json['allow_gifs'] ?? true,
      allowPolls: json['allow_polls'] ?? true,
      allowFiles: json['allow_files'] ?? true,
      allowLinks: json['allow_links'] ?? true,
      allowForwarding: json['allow_forwarding'] ?? true,
      allowPinning: json['allow_pinning'] ?? true,
      allowReactions: json['allow_reactions'] ?? true,
      allowMentions: json['allow_mentions'] ?? true,
      allowReplies: json['allow_replies'] ?? true,
      autoDeleteMessages: json['auto_delete_messages'] ?? false,
      autoDeleteDuration: json['auto_delete_duration'] != null
          ? Duration(milliseconds: json['auto_delete_duration'])
          : null,
      enableSlowMode: json['enable_slow_mode'] ?? false,
      slowModeInterval: SlowModeInterval.values.firstWhere(
        (e) => e.name == json['slow_mode_interval'],
        orElse: () => SlowModeInterval.disabled,
      ),
      messagePermission: MessagePermission.values.firstWhere(
        (e) => e.name == json['message_permission'],
        orElse: () => MessagePermission.everyone,
      ),
      mediaPermission: MediaPermission.values.firstWhere(
        (e) => e.name == json['media_permission'],
        orElse: () => MediaPermission.everyone,
      ),
      memberAddPermission: MemberAddPermission.values.firstWhere(
        (e) => e.name == json['member_add_permission'],
        orElse: () => MemberAddPermission.adminsOnly,
      ),
      groupInfoEditPermission: GroupInfoEditPermission.values.firstWhere(
        (e) => e.name == json['group_info_edit_permission'],
        orElse: () => GroupInfoEditPermission.adminsOnly,
      ),
      requireApprovalToJoin: json['require_approval_to_join'] ?? false,
      allowInviteLinks: json['allow_invite_links'] ?? true,
      showMemberCount: json['show_member_count'] ?? true,
      showOnlineCount: json['show_online_count'] ?? true,
      showLastSeen: json['show_last_seen'] ?? true,
      allowMemberSearch: json['allow_member_search'] ?? true,
      enableReadReceipts: json['enable_read_receipts'] ?? true,
      enableTypingIndicators: json['enable_typing_indicators'] ?? true,
      enableDeliveryReceipts: json['enable_delivery_receipts'] ?? true,
      allowScreenshots: json['allow_screenshots'] ?? true,
      protectContent: json['protect_content'] ?? false,
      enableBroadcastMode: json['enable_broadcast_mode'] ?? false,
      restrictSavingContent: json['restrict_saving_content'] ?? false,
      maxPinnedMessages: json['max_pinned_messages'] ?? 10,
      maxFileSize: json['max_file_size'] ?? 100 * 1024 * 1024,
      messageHistoryVisibility: json['message_history_visibility'] != null
          ? Duration(milliseconds: json['message_history_visibility'])
          : const Duration(days: 365),
      bannedWords: List<String>.from(json['banned_words'] ?? []),
      enableWordFilter: json['enable_word_filter'] ?? false,
      enableAntiSpam: json['enable_anti_spam'] ?? false,
      customSettings: json['custom_settings'],
    );
  }
}

class GroupSettingsState {
  final String groupId;
  final GroupSettingsData settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool isInitialized;
  final DateTime? lastUpdateTime;
  final Map<String, dynamic> pendingChanges;

  GroupSettingsState({
    required this.groupId,
    GroupSettingsData? settings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.isInitialized = false,
    this.lastUpdateTime,
    this.pendingChanges = const {},
  }) : settings = settings ?? GroupSettingsData();

  GroupSettingsState copyWith({
    String? groupId,
    GroupSettingsData? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? isInitialized,
    DateTime? lastUpdateTime,
    Map<String, dynamic>? pendingChanges,
  }) {
    return GroupSettingsState(
      groupId: groupId ?? this.groupId,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      pendingChanges: pendingChanges ?? this.pendingChanges,
    );
  }

  bool get hasPendingChanges => pendingChanges.isNotEmpty;
}

class GroupSettingsNotifier
    extends StateNotifier<AsyncValue<GroupSettingsState>> {
  final String groupId;
  final ApiService _apiService;
  final CacheService _cacheService;

  Timer? _saveTimer;
  static const Duration _autoSaveDelay = Duration(seconds: 2);

  GroupSettingsNotifier({
    required this.groupId,
    required ApiService apiService,
    required CacheService cacheService,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       super(AsyncValue.data(GroupSettingsState(groupId: groupId))) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _loadSettings();

      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          isInitialized: true,
          lastUpdateTime: DateTime.now(),
        ),
      );

      if (kDebugMode)
        print('✅ Group settings provider initialized for: $groupId');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing group settings provider: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      // Load from cache first
      final cachedSettings = await _loadSettingsFromCache();

      if (cachedSettings != null) {
        state = AsyncValue.data(
          state.value!.copyWith(settings: cachedSettings),
        );
      }

      // Load from API
      await _loadSettingsFromAPI();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading settings: $e');
      rethrow;
    }
  }

  Future<GroupSettingsData?> _loadSettingsFromCache() async {
    try {
      final cachedData = await _cacheService.getCachedGroupSettings(groupId);
      return cachedData != null ? GroupSettingsData.fromJson(cachedData) : null;
    } catch (e) {
      if (kDebugMode) print('❌ Error loading settings from cache: $e');
      return null;
    }
  }

  Future<void> _loadSettingsFromAPI() async {
    try {
      final response = await _apiService.getGroupSettings(groupId);

      if (response.success && response.data != null) {
        final settings = GroupSettingsData.fromJson(response.data!);
        await _cacheSettings(settings);

        state = AsyncValue.data(
          state.value!.copyWith(
            settings: settings,
            lastUpdateTime: DateTime.now(),
          ),
        );

        if (kDebugMode) print('✅ Loaded group settings from API');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading settings from API: $e');

      state.whenData((settingsState) {
        if (!settingsState.isInitialized) {
          state = AsyncValue.error(e, StackTrace.current);
        } else {
          state = AsyncValue.data(settingsState.copyWith(error: e.toString()));
        }
      });
    }
  }

  // Public methods for updating settings
  Future<void> updateSettings(GroupSettingsData newSettings) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isSaving: true));

      final response = await _apiService.updateGroupSettings(
        groupId,
        newSettings.toJson(),
      );

      if (response.success) {
        await _cacheSettings(newSettings);

        state = AsyncValue.data(
          state.value!.copyWith(
            settings: newSettings,
            isSaving: false,
            pendingChanges: {},
            lastUpdateTime: DateTime.now(),
          ),
        );

        if (kDebugMode) print('✅ Group settings updated');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isSaving: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error updating settings: $e');
      rethrow;
    }
  }

  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_autoSaveDelay, () {
      _autoSaveSettings();
    });
  }

  Future<void> _autoSaveSettings() async {
    final currentState = state.value!;
    if (!currentState.hasPendingChanges) return;

    try {
      final updatedSettings = _applyPendingChanges(
        currentState.settings,
        currentState.pendingChanges,
      );

      await updateSettings(updatedSettings);
    } catch (e) {
      if (kDebugMode) print('❌ Error in auto-save: $e');
    }
  }

  GroupSettingsData _applyPendingChanges(
    GroupSettingsData settings,
    Map<String, dynamic> changes,
  ) {
    var updatedSettings = settings;

    for (final entry in changes.entries) {
      switch (entry.key) {
        case 'allowMessages':
          updatedSettings = updatedSettings.copyWith(
            allowMessages: entry.value,
          );
          break;
        case 'allowMedia':
          updatedSettings = updatedSettings.copyWith(allowMedia: entry.value);
          break;
        case 'allowVoiceMessages':
          updatedSettings = updatedSettings.copyWith(
            allowVoiceMessages: entry.value,
          );
          break;
        case 'enableSlowMode':
          updatedSettings = updatedSettings.copyWith(
            enableSlowMode: entry.value,
          );
          break;
        case 'slowModeInterval':
          updatedSettings = updatedSettings.copyWith(
            slowModeInterval: entry.value,
          );
          break;
        case 'messagePermission':
          updatedSettings = updatedSettings.copyWith(
            messagePermission: entry.value,
          );
          break;
        case 'mediaPermission':
          updatedSettings = updatedSettings.copyWith(
            mediaPermission: entry.value,
          );
          break;
        case 'requireApprovalToJoin':
          updatedSettings = updatedSettings.copyWith(
            requireApprovalToJoin: entry.value,
          );
          break;
        case 'allowInviteLinks':
          updatedSettings = updatedSettings.copyWith(
            allowInviteLinks: entry.value,
          );
          break;
        case 'enableWordFilter':
          updatedSettings = updatedSettings.copyWith(
            enableWordFilter: entry.value,
          );
          break;
        case 'bannedWords':
          updatedSettings = updatedSettings.copyWith(bannedWords: entry.value);
          break;
        case 'protectContent':
          updatedSettings = updatedSettings.copyWith(
            protectContent: entry.value,
          );
          break;
        case 'maxFileSize':
          updatedSettings = updatedSettings.copyWith(maxFileSize: entry.value);
          break;
        // Add more cases as needed
      }
    }

    return updatedSettings;
  }

  void _addPendingChange(String key, dynamic value) {
    state.whenData((settingsState) {
      final updatedPendingChanges = Map<String, dynamic>.from(
        settingsState.pendingChanges,
      );
      updatedPendingChanges[key] = value;

      state = AsyncValue.data(
        settingsState.copyWith(pendingChanges: updatedPendingChanges),
      );

      _scheduleAutoSave();
    });
  }

  // Individual setting update methods
  void toggleMessages(bool allow) {
    _addPendingChange('allowMessages', allow);
  }

  void toggleMedia(bool allow) {
    _addPendingChange('allowMedia', allow);
  }

  void toggleVoiceMessages(bool allow) {
    _addPendingChange('allowVoiceMessages', allow);
  }

  void toggleStickers(bool allow) {
    _addPendingChange('allowStickers', allow);
  }

  void toggleGifs(bool allow) {
    _addPendingChange('allowGifs', allow);
  }

  void togglePolls(bool allow) {
    _addPendingChange('allowPolls', allow);
  }

  void toggleFiles(bool allow) {
    _addPendingChange('allowFiles', allow);
  }

  void toggleLinks(bool allow) {
    _addPendingChange('allowLinks', allow);
  }

  void toggleForwarding(bool allow) {
    _addPendingChange('allowForwarding', allow);
  }

  void togglePinning(bool allow) {
    _addPendingChange('allowPinning', allow);
  }

  void toggleReactions(bool allow) {
    _addPendingChange('allowReactions', allow);
  }

  void toggleMentions(bool allow) {
    _addPendingChange('allowMentions', allow);
  }

  void toggleReplies(bool allow) {
    _addPendingChange('allowReplies', allow);
  }

  void toggleSlowMode(bool enable) {
    _addPendingChange('enableSlowMode', enable);
  }

  void setSlowModeInterval(SlowModeInterval interval) {
    _addPendingChange('slowModeInterval', interval);
  }

  void setMessagePermission(MessagePermission permission) {
    _addPendingChange('messagePermission', permission);
  }

  void setMediaPermission(MediaPermission permission) {
    _addPendingChange('mediaPermission', permission);
  }

  void setMemberAddPermission(MemberAddPermission permission) {
    _addPendingChange('memberAddPermission', permission);
  }

  void setGroupInfoEditPermission(GroupInfoEditPermission permission) {
    _addPendingChange('groupInfoEditPermission', permission);
  }

  void toggleApprovalToJoin(bool require) {
    _addPendingChange('requireApprovalToJoin', require);
  }

  void toggleInviteLinks(bool allow) {
    _addPendingChange('allowInviteLinks', allow);
  }

  void toggleMemberCount(bool show) {
    _addPendingChange('showMemberCount', show);
  }

  void toggleOnlineCount(bool show) {
    _addPendingChange('showOnlineCount', show);
  }

  void toggleLastSeen(bool show) {
    _addPendingChange('showLastSeen', show);
  }

  void toggleMemberSearch(bool allow) {
    _addPendingChange('allowMemberSearch', allow);
  }

  void toggleReadReceipts(bool enable) {
    _addPendingChange('enableReadReceipts', enable);
  }

  void toggleTypingIndicators(bool enable) {
    _addPendingChange('enableTypingIndicators', enable);
  }

  void toggleDeliveryReceipts(bool enable) {
    _addPendingChange('enableDeliveryReceipts', enable);
  }

  void toggleScreenshots(bool allow) {
    _addPendingChange('allowScreenshots', allow);
  }

  void toggleContentProtection(bool protect) {
    _addPendingChange('protectContent', protect);
  }

  void toggleBroadcastMode(bool enable) {
    _addPendingChange('enableBroadcastMode', enable);
  }

  void toggleSavingContentRestriction(bool restrict) {
    _addPendingChange('restrictSavingContent', restrict);
  }

  void setMaxPinnedMessages(int max) {
    _addPendingChange('maxPinnedMessages', max);
  }

  void setMaxFileSize(int size) {
    _addPendingChange('maxFileSize', size);
  }

  void setMessageHistoryVisibility(Duration duration) {
    _addPendingChange('messageHistoryVisibility', duration);
  }

  void toggleWordFilter(bool enable) {
    _addPendingChange('enableWordFilter', enable);
  }

  void setBannedWords(List<String> words) {
    _addPendingChange('bannedWords', words);
  }

  void addBannedWord(String word) {
    final currentWords = List<String>.from(settings.bannedWords);
    if (!currentWords.contains(word.toLowerCase())) {
      currentWords.add(word.toLowerCase());
      setBannedWords(currentWords);
    }
  }

  void removeBannedWord(String word) {
    final currentWords = List<String>.from(settings.bannedWords);
    currentWords.remove(word.toLowerCase());
    setBannedWords(currentWords);
  }

  void toggleAntiSpam(bool enable) {
    _addPendingChange('enableAntiSpam', enable);
  }

  void setAutoDeleteMessages(bool enable, {Duration? duration}) {
    _addPendingChange('autoDeleteMessages', enable);
    if (duration != null) {
      _addPendingChange('autoDeleteDuration', duration);
    }
  }

  void updateCustomSetting(String key, dynamic value) {
    final currentCustomSettings = Map<String, dynamic>.from(
      settings.customSettings ?? {},
    );
    currentCustomSettings[key] = value;
    _addPendingChange('customSettings', currentCustomSettings);
  }

  void removeCustomSetting(String key) {
    final currentCustomSettings = Map<String, dynamic>.from(
      settings.customSettings ?? {},
    );
    currentCustomSettings.remove(key);
    _addPendingChange('customSettings', currentCustomSettings);
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    await _autoSaveSettings();
  }

  Future<void> revertChanges() async {
    state.whenData((settingsState) {
      state = AsyncValue.data(settingsState.copyWith(pendingChanges: {}));
    });

    _saveTimer?.cancel();
  }

  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = GroupSettingsData();
      await updateSettings(defaultSettings);

      if (kDebugMode) print('✅ Settings reset to defaults');
    } catch (e) {
      if (kDebugMode) print('❌ Error resetting settings: $e');
      rethrow;
    }
  }

  Future<void> refreshSettings() async {
    await _loadSettingsFromAPI();
  }

  Future<void> _cacheSettings(GroupSettingsData settings) async {
    try {
      await _cacheService.cacheGroupSettings(groupId, settings.toJson());
    } catch (e) {
      if (kDebugMode) print('❌ Error caching settings: $e');
    }
  }

  // Getters
  GroupSettingsData get settings =>
      state.value?.settings ?? GroupSettingsData();
  bool get isLoading => state.value?.isLoading ?? false;
  bool get isSaving => state.value?.isSaving ?? false;
  bool get hasPendingChanges => state.value?.hasPendingChanges ?? false;
  Map<String, dynamic> get pendingChanges => state.value?.pendingChanges ?? {};

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

// Providers
final groupSettingsProvider = StateNotifierProvider.autoDispose
    .family<GroupSettingsNotifier, AsyncValue<GroupSettingsState>, String>((
      ref,
      groupId,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      final cacheService = CacheService();

      return GroupSettingsNotifier(
        groupId: groupId,
        apiService: apiService,
        cacheService: cacheService,
      );
    });

// Convenience providers
final groupSettingsDataProvider = Provider.family<GroupSettingsData, String>((
  ref,
  groupId,
) {
  final settingsState = ref.watch(groupSettingsProvider(groupId));
  return settingsState.whenOrNull(data: (state) => state.settings) ??
      GroupSettingsData();
});

final groupSettingsLoadingProvider = Provider.family<bool, String>((
  ref,
  groupId,
) {
  final settingsState = ref.watch(groupSettingsProvider(groupId));
  return settingsState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final groupSettingsSavingProvider = Provider.family<bool, String>((
  ref,
  groupId,
) {
  final settingsState = ref.watch(groupSettingsProvider(groupId));
  return settingsState.whenOrNull(data: (state) => state.isSaving) ?? false;
});

final groupSettingsHasPendingProvider = Provider.family<bool, String>((
  ref,
  groupId,
) {
  final settingsState = ref.watch(groupSettingsProvider(groupId));
  return settingsState.whenOrNull(data: (state) => state.hasPendingChanges) ??
      false;
});

// Specific setting providers
final allowMessagesProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.allowMessages;
});

final allowMediaProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.allowMedia;
});

final slowModeEnabledProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.enableSlowMode;
});

final slowModeIntervalProvider = Provider.family<SlowModeInterval, String>((
  ref,
  groupId,
) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.slowModeInterval;
});

final messagePermissionProvider = Provider.family<MessagePermission, String>((
  ref,
  groupId,
) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.messagePermission;
});

final mediaPermissionProvider = Provider.family<MediaPermission, String>((
  ref,
  groupId,
) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.mediaPermission;
});

final requireApprovalProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.requireApprovalToJoin;
});

final allowInviteLinksProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.allowInviteLinks;
});

final protectContentProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.protectContent;
});

final enableWordFilterProvider = Provider.family<bool, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.enableWordFilter;
});

final bannedWordsProvider = Provider.family<List<String>, String>((
  ref,
  groupId,
) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.bannedWords;
});

final maxFileSizeProvider = Provider.family<int, String>((ref, groupId) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.maxFileSize;
});

final enableBroadcastModeProvider = Provider.family<bool, String>((
  ref,
  groupId,
) {
  final settings = ref.watch(groupSettingsDataProvider(groupId));
  return settings.enableBroadcastMode;
});
