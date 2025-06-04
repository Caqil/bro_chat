import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat/chat_settings.dart';
import '../../models/chat/participant_model.dart';
import '../../services/api/api_service.dart';
import '../../services/websocket/chat_socket.dart';
import '../../services/storage/cache_service.dart';
import '../../models/chat/chat_model.dart';
import '../../models/common/api_response.dart';
import '../../services/websocket/websocket_event_types.dart';

// Chat state
class ChatState {
  final ChatModel? chat;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final DateTime? lastFetchTime;

  ChatState({
    this.chat,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.lastFetchTime,
  });

  ChatState copyWith({
    ChatModel? chat,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    DateTime? lastFetchTime,
  }) {
    return ChatState(
      chat: chat ?? this.chat,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }

  bool get hasChat => chat != null;
  bool get isGroup => chat?.isGroup ?? false;
  bool get isPrivate => chat?.isPrivate ?? false;
  bool get isMuted => chat?.isMuted ?? false;
  bool get isPinned => chat?.isPinned ?? false;
  bool get isArchived => chat?.isArchived ?? false;
  bool get hasUnreadMessages => chat?.hasUnreadMessages ?? false;
  int get unreadCount => chat?.unreadCount ?? 0;
}

class ChatNotifier extends StateNotifier<AsyncValue<ChatState>> {
  final String chatId;
  final ApiService _apiService;
  final ChatSocketService _chatSocketService;
  final CacheService _cacheService;

  StreamSubscription<ChatUpdate>? _chatUpdateSubscription;
  StreamSubscription<ChatMessage>? _messageSubscription;

  ChatNotifier({
    required this.chatId,
    required ApiService apiService,
    required ChatSocketService chatSocketService,
    required CacheService cacheService,
  }) : _apiService = apiService,
       _chatSocketService = chatSocketService,
       _cacheService = cacheService,
       super(AsyncValue.data(ChatState())) {
    _initialize();
  }

  void _initialize() async {
    _setupSubscriptions();
    await _loadChat();
  }

  void _setupSubscriptions() {
    // Listen to chat updates
    _chatUpdateSubscription = _chatSocketService
        .getUpdatesForChat(chatId)
        .listen(_handleChatUpdate);

    // Listen to new messages to update unread count
    _messageSubscription = _chatSocketService
        .getMessagesForChat(chatId)
        .listen(_handleNewMessage);
  }

  void _handleChatUpdate(ChatUpdate update) {
    switch (update.type) {
      case ChatUpdateType.chatUpdated:
        _handleChatInfoUpdate(update.data);
        break;
      case ChatUpdateType.participantAdded:
        _handleParticipantAdded(update.data);
        break;
      case ChatUpdateType.participantRemoved:
        _handleParticipantRemoved(update.data);
        break;
      default:
        break;
    }
  }

  void _handleChatInfoUpdate(Map<String, dynamic> data) {
    state.whenData((chatState) {
      if (chatState.chat == null) return;

      ChatModel updatedChat = chatState.chat!;

      if (data.containsKey('name')) {
        updatedChat = updatedChat.copyWith(name: data['name']);
      }
      if (data.containsKey('description')) {
        updatedChat = updatedChat.copyWith(description: data['description']);
      }
      if (data.containsKey('avatar')) {
        updatedChat = updatedChat.copyWith(avatar: data['avatar']);
      }
      if (data.containsKey('settings')) {
        updatedChat = updatedChat.copyWith(
          settings: ChatSettings.fromJson(data['settings']),
        );
      }

      state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
      _cacheChat(updatedChat);
    });
  }

  void _handleParticipantAdded(Map<String, dynamic> data) {
    state.whenData((chatState) {
      if (chatState.chat == null) return;

      final userId = data['user_id'] as String?;
      if (userId == null) return;

      final updatedParticipants = List<ParticipantModel>.from(
        chatState.chat!.participants,
      );

      // Check if participant already exists
      if (!updatedParticipants.any((p) => p.userId == userId)) {
        final newParticipant = ParticipantModel(
          userId: userId,
          name: data['user_name'] ?? 'User',
          joinedAt: DateTime.now(),
        );
        updatedParticipants.add(newParticipant);

        final updatedChat = chatState.chat!.copyWith(
          participants: updatedParticipants,
        );
        state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
        _cacheChat(updatedChat);
      }
    });
  }

  void _handleParticipantRemoved(Map<String, dynamic> data) {
    state.whenData((chatState) {
      if (chatState.chat == null) return;

      final userId = data['user_id'] as String?;
      if (userId == null) return;

      final updatedParticipants = chatState.chat!.participants
          .where((p) => p.userId != userId)
          .toList();

      final updatedChat = chatState.chat!.copyWith(
        participants: updatedParticipants,
      );
      state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
      _cacheChat(updatedChat);
    });
  }

  void _handleNewMessage(ChatMessage message) {
    state.whenData((chatState) {
      if (chatState.chat == null) return;

      // Update unread count and last message
      final updatedChat = chatState.chat!.copyWith(
        unreadCount: chatState.chat!.unreadCount + 1,
        // You can also update lastMessage here if needed
      );

      state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
    });
  }

  Future<void> _loadChat() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      // Try to load from cache first
      final cachedChat = await _loadChatFromCache();

      if (cachedChat != null) {
        state = AsyncValue.data(
          state.value!.copyWith(
            chat: cachedChat,
            isLoading: false,
            isInitialized: true,
          ),
        );
      }

      // Load from API
      await _loadChatFromAPI();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<ChatModel?> _loadChatFromCache() async {
    try {
      final cachedData = await _cacheService.getCachedChat(chatId);
      return cachedData != null ? ChatModel.fromJson(cachedData) : null;
    } catch (e) {
      if (kDebugMode) print('❌ Error loading chat from cache: $e');
      return null;
    }
  }

  Future<void> _loadChatFromAPI() async {
    try {
      final response = await _apiService.getChat(chatId);

      if (response.success && response.data != null) {
        final chat = response.data!;
        await _cacheChat(chat);

        state = AsyncValue.data(
          state.value!.copyWith(
            chat: chat,
            isLoading: false,
            isInitialized: true,
            lastFetchTime: DateTime.now(),
          ),
        );

        if (kDebugMode) print('✅ Loaded chat: $chatId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading chat from API: $e');

      state.whenData((chatState) {
        if (chatState.chat == null) {
          state = AsyncValue.error(e, StackTrace.current);
        } else {
          state = AsyncValue.data(
            chatState.copyWith(
              isLoading: false,
              isInitialized: true,
              error: e.toString(),
            ),
          );
        }
      });
    }
  }

  // Chat management methods
  Future<void> updateChat({
    String? name,
    String? description,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _apiService.updateChat(
        chatId,
        name: name,
        description: description,
        settings: settings,
      );

      if (response.success && response.data != null) {
        final updatedChat = response.data!;
        state.whenData((chatState) {
          state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
        });
        await _cacheChat(updatedChat);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating chat: $e');
      rethrow;
    }
  }

  Future<void> addParticipant(String userId) async {
    try {
      final response = await _apiService.addParticipant(chatId, userId);
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      if (kDebugMode) print('❌ Error adding participant: $e');
      rethrow;
    }
  }

  Future<void> removeParticipant(String userId) async {
    try {
      final response = await _apiService.removeParticipant(chatId, userId);
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      if (kDebugMode) print('❌ Error removing participant: $e');
      rethrow;
    }
  }

  Future<void> archiveChat(bool archive) async {
    try {
      final response = await _apiService.archiveChat(chatId, archive);

      if (response.success) {
        state.whenData((chatState) {
          if (chatState.chat != null) {
            final updatedChat = chatState.chat!.copyWith(isArchived: archive);
            state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
            _cacheChat(updatedChat);
          }
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error archiving chat: $e');
      rethrow;
    }
  }

  Future<void> muteChat({required bool mute, DateTime? mutedUntil}) async {
    try {
      final response = await _apiService.muteChat(
        chatId,
        mute: mute,
        mutedUntil: mutedUntil,
      );

      if (response.success) {
        state.whenData((chatState) {
          if (chatState.chat != null) {
            final updatedChat = chatState.chat!.copyWith(
              isMuted: mute,
              mutedUntil: mutedUntil,
            );
            state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
            _cacheChat(updatedChat);
          }
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error muting chat: $e');
      rethrow;
    }
  }

  Future<void> pinChat(bool pin) async {
    try {
      final response = await _apiService.pinChat(chatId, pin);

      if (response.success) {
        state.whenData((chatState) {
          if (chatState.chat != null) {
            final updatedChat = chatState.chat!.copyWith(isPinned: pin);
            state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
            _cacheChat(updatedChat);
          }
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error pinning chat: $e');
      rethrow;
    }
  }

  Future<void> markAsRead() async {
    try {
      final response = await _apiService.markChatAsRead(chatId);

      if (response.success) {
        state.whenData((chatState) {
          if (chatState.chat != null) {
            final updatedChat = chatState.chat!.copyWith(unreadCount: 0);
            state = AsyncValue.data(chatState.copyWith(chat: updatedChat));
            _cacheChat(updatedChat);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error marking chat as read: $e');
    }
  }

  Future<void> deleteChat() async {
    try {
      final response = await _apiService.deleteChat(chatId);
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  Future<void> _cacheChat(ChatModel chat) async {
    try {
      await _cacheService.cacheChat(chat.id, chat.toJson());
    } catch (e) {
      if (kDebugMode) print('❌ Error caching chat: $e');
    }
  }

  // Utility methods
  ChatModel? get chat => state.value?.chat;
  bool get isLoading => state.value?.isLoading ?? false;
  bool get hasChat => state.value?.hasChat ?? false;
  bool get isGroup => state.value?.isGroup ?? false;
  bool get isPrivate => state.value?.isPrivate ?? false;
  bool get isMuted => state.value?.isMuted ?? false;
  bool get isPinned => state.value?.isPinned ?? false;
  bool get isArchived => state.value?.isArchived ?? false;
  int get unreadCount => state.value?.unreadCount ?? 0;

  @override
  void dispose() {
    _chatUpdateSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}

// Providers
final chatProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, AsyncValue<ChatState>, String>((ref, chatId) {
      final apiService = ref.watch(apiServiceProvider);
      final chatSocketService = ref.watch(chatSocketServiceProvider);
      final cacheService = CacheService();

      return ChatNotifier(
        chatId: chatId,
        apiService: apiService,
        chatSocketService: chatSocketService,
        cacheService: cacheService,
      );
    });

// Convenience providers
final chatDataProvider = Provider.family<ChatModel?, String>((ref, chatId) {
  final chatState = ref.watch(chatProvider(chatId));
  return chatState.whenOrNull(data: (state) => state.chat);
});

final chatLoadingProvider = Provider.family<bool, String>((ref, chatId) {
  final chatState = ref.watch(chatProvider(chatId));
  return chatState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final chatNameProvider = Provider.family<String, String>((ref, chatId) {
  final chat = ref.watch(chatDataProvider(chatId));
  return chat?.name ?? 'Chat';
});

final chatTypeProvider = Provider.family<ChatType, String>((ref, chatId) {
  final chat = ref.watch(chatDataProvider(chatId));
  return chat?.type ?? ChatType.private;
});

final chatParticipantsProvider =
    Provider.family<List<ParticipantModel>, String>((ref, chatId) {
      final chat = ref.watch(chatDataProvider(chatId));
      return chat?.participants ?? [];
    });

final chatUnreadCountProvider = Provider.family<int, String>((ref, chatId) {
  final chat = ref.watch(chatDataProvider(chatId));
  return chat?.unreadCount ?? 0;
});

final isChatMutedProvider = Provider.family<bool, String>((ref, chatId) {
  final chat = ref.watch(chatDataProvider(chatId));
  return chat?.isMuted ?? false;
});

final isChatPinnedProvider = Provider.family<bool, String>((ref, chatId) {
  final chat = ref.watch(chatDataProvider(chatId));
  return chat?.isPinned ?? false;
});

final isChatArchivedProvider = Provider.family<bool, String>((ref, chatId) {
  final chat = ref.watch(chatDataProvider(chatId));
  return chat?.isArchived ?? false;
});

final chatSettingsProvider = Provider.family<ChatSettings, String>((
  ref,
  chatId,
) {
  final chat = ref.watch(chatDataProvider(chatId));
  return chat?.settings ?? ChatSettings();
});
