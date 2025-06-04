import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../models/chat/chat_model.dart';
import '../../models/common/api_response.dart';
import '../../models/common/pagination_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/dio_config.dart';
import '../../services/storage/cache_service.dart';
import '../../services/storage/local_storage.dart';
import '../../services/websocket/chat_socket.dart';

class ChatListState {
  final List<ChatModel> chats;
  final List<ChatModel> archivedChats;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final String? searchQuery;
  final ChatListFilter filter;

  const ChatListState({
    this.chats = const [],
    this.archivedChats = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
    this.searchQuery,
    this.filter = ChatListFilter.all,
  });

  ChatListState copyWith({
    List<ChatModel>? chats,
    List<ChatModel>? archivedChats,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
    String? searchQuery,
    ChatListFilter? filter,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      archivedChats: archivedChats ?? this.archivedChats,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  List<ChatModel> get filteredChats {
    switch (filter) {
      case ChatListFilter.all:
        return chats;
      case ChatListFilter.unread:
        return chats.where((chat) => chat.unreadCount > 0).toList();
      case ChatListFilter.groups:
        return chats.where((chat) => chat.type == ChatType.group).toList();
      case ChatListFilter.private:
        return chats.where((chat) => chat.type == ChatType.private).toList();
      case ChatListFilter.pinned:
        return chats.where((chat) => chat.isPinned).toList();
      case ChatListFilter.muted:
        return chats.where((chat) => chat.isMuted).toList();
    }
  }

  List<ChatModel> get searchResults {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return filteredChats;
    }

    final query = searchQuery!.toLowerCase();
    return filteredChats.where((chat) {
      return chat.name.toLowerCase().contains(query) ||
          (chat.lastMessage?.content.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  int get totalUnreadCount {
    return chats.fold(0, (total, chat) => total + chat.unreadCount);
  }

  int get unreadChatsCount {
    return chats.where((chat) => chat.unreadCount > 0).length;
  }
}

enum ChatListFilter { all, unread, groups, private, pinned, muted }

class ChatListNotifier extends StateNotifier<ChatListState> {
  final Dio _dio;
  final CacheService _cacheService;
  final LocalStorage _localStorage;
  final ChatSocketService _chatSocketService;

  ChatListNotifier(
    this._dio,
    this._cacheService,
    this._localStorage,
    this._chatSocketService,
  ) : super(const ChatListState()) {
    _loadInitialData();
    _listenToChatUpdates();
  }

  Future<void> _loadInitialData() async {
    // Load from cache first
    final cachedChats = await _cacheService.getCachedChats();
    if (cachedChats.isNotEmpty) {
      final chats = cachedChats
          .map((data) => ChatModel.fromJson(data))
          .where((chat) => !chat.isArchived)
          .toList();
      final archivedChats = cachedChats
          .map((data) => ChatModel.fromJson(data))
          .where((chat) => chat.isArchived)
          .toList();

      state = state.copyWith(chats: chats, archivedChats: archivedChats);
    }

    // Then fetch fresh data
    await loadChats(refresh: true);
  }

  void _listenToChatUpdates() {
    _chatSocketService.chatUpdates.listen((update) {
      switch (update.type) {
        case ChatUpdateType.chatCreated:
          _handleChatCreated(update);
          break;
        case ChatUpdateType.chatUpdated:
          _handleChatUpdated(update);
          break;
        case ChatUpdateType.chatDeleted:
          _handleChatDeleted(update);
          break;
        case ChatUpdateType.participantAdded:
        case ChatUpdateType.participantRemoved:
          _handleParticipantChange(update);
          break;
        default:
          break;
      }
    });

    _chatSocketService.messageReceived.listen((message) {
      _handleNewMessage(message);
    });
  }

  void _handleChatCreated(ChatUpdate update) {
    final chatData = update.data;
    final chat = ChatModel.fromJson(chatData);

    if (!chat.isArchived) {
      state = state.copyWith(chats: [chat, ...state.chats]);
    } else {
      state = state.copyWith(archivedChats: [chat, ...state.archivedChats]);
    }

    // Cache the new chat
    _cacheService.cacheChat(chat.id, chatData);
  }

  void _handleChatUpdated(ChatUpdate update) {
    final chatId = update.chatId;
    final updateData = update.data;

    // Update in regular chats
    final chatIndex = state.chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final updatedChat = state.chats[chatIndex].copyWith(
        name: updateData['name'] ?? state.chats[chatIndex].name,
        description:
            updateData['description'] ?? state.chats[chatIndex].description,
        avatar: updateData['avatar'] ?? state.chats[chatIndex].avatar,
        isArchived:
            updateData['is_archived'] ?? state.chats[chatIndex].isArchived,
        isMuted: updateData['is_muted'] ?? state.chats[chatIndex].isMuted,
        isPinned: updateData['is_pinned'] ?? state.chats[chatIndex].isPinned,
      );

      final newChats = List<ChatModel>.from(state.chats);
      newChats[chatIndex] = updatedChat;

      state = state.copyWith(chats: newChats);

      // Cache the updated chat
      _cacheService.cacheChat(chatId, updatedChat.toJson());
      return;
    }

    // Update in archived chats
    final archivedIndex = state.archivedChats.indexWhere(
      (chat) => chat.id == chatId,
    );
    if (archivedIndex != -1) {
      final updatedChat = state.archivedChats[archivedIndex].copyWith(
        name: updateData['name'] ?? state.archivedChats[archivedIndex].name,
        description:
            updateData['description'] ??
            state.archivedChats[archivedIndex].description,
        avatar:
            updateData['avatar'] ?? state.archivedChats[archivedIndex].avatar,
        isArchived:
            updateData['is_archived'] ??
            state.archivedChats[archivedIndex].isArchived,
        isMuted:
            updateData['is_muted'] ??
            state.archivedChats[archivedIndex].isMuted,
        isPinned:
            updateData['is_pinned'] ??
            state.archivedChats[archivedIndex].isPinned,
      );

      final newArchivedChats = List<ChatModel>.from(state.archivedChats);
      newArchivedChats[archivedIndex] = updatedChat;

      state = state.copyWith(archivedChats: newArchivedChats);

      // Cache the updated chat
      _cacheService.cacheChat(chatId, updatedChat.toJson());
    }
  }

  void _handleChatDeleted(ChatUpdate update) {
    final chatId = update.chatId;

    state = state.copyWith(
      chats: state.chats.where((chat) => chat.id != chatId).toList(),
      archivedChats: state.archivedChats
          .where((chat) => chat.id != chatId)
          .toList(),
    );

    // Remove from cache
    _cacheService.deleteCacheEntry(chatId, 'chats');
  }

  void _handleParticipantChange(ChatUpdate update) {
    final chatId = update.chatId;

    // Refresh the specific chat to get updated participant info
    _refreshSingleChat(chatId);
  }

  void _handleNewMessage(ChatMessage message) {
    final chatId = message.chatId;

    // Update the chat with the new last message
    final chatIndex = state.chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = state.chats[chatIndex];
      final updatedChat = chat.copyWith(
        lastMessage: MessageModel(
          id: message.id,
          content: message.content,
          type: MessageType.values.firstWhere(
            (type) => type.name == message.type,
            orElse: () => MessageType.text,
          ),
          createdAt: message.createdAt,
          senderId: message.senderId,
          chatId: message.chatId,
        ),
        lastMessageAt: message.createdAt,
        unreadCount: message.isFromCurrentUser
            ? chat.unreadCount
            : chat.unreadCount + 1,
      );

      // Move to top of list
      final newChats = List<ChatModel>.from(state.chats);
      newChats.removeAt(chatIndex);
      newChats.insert(0, updatedChat);

      state = state.copyWith(chats: newChats);

      // Cache the updated chat
      _cacheService.cacheChat(chatId, updatedChat.toJson());
    }
  }

  Future<void> loadChats({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
      );
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _dio.get(
        ApiConstants.getUserChats,
        queryParameters: {
          'page': refresh ? 1 : state.currentPage,
          'limit': 20,
          'archived': false,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => PaginationModel<ChatModel>.fromJson(
          data,
          (item) => ChatModel.fromJson(item),
        ),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final paginatedData = apiResponse.data!;
        final newChats = paginatedData.items;

        // Cache the chats
        for (final chat in newChats) {
          await _cacheService.cacheChat(chat.id, chat.toJson());
        }

        if (refresh) {
          state = state.copyWith(
            chats: newChats,
            isLoading: false,
            hasMore: paginatedData.hasNextPage,
            currentPage: 2,
          );
        } else {
          state = state.copyWith(
            chats: [...state.chats, ...newChats],
            isLoading: false,
            hasMore: paginatedData.hasNextPage,
            currentPage: state.currentPage + 1,
          );
        }
      } else {
        state = state.copyWith(isLoading: false, error: apiResponse.message);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load chats: $e',
      );
    }
  }

  Future<void> loadArchivedChats() async {
    try {
      final response = await _dio.get(
        ApiConstants.getUserChats,
        queryParameters: {'archived': true, 'limit': 100},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => PaginationModel<ChatModel>.fromJson(
          data,
          (item) => ChatModel.fromJson(item),
        ),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final archivedChats = apiResponse.data!.items;

        // Cache archived chats
        for (final chat in archivedChats) {
          await _cacheService.cacheChat(chat.id, chat.toJson());
        }

        state = state.copyWith(archivedChats: archivedChats);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load archived chats: $e');
    }
  }

  Future<bool> createChat({
    required ChatType type,
    required List<String> participantIds,
    String? name,
    String? description,
    String? avatar,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createChat,
        data: {
          'type': type.name,
          'participants': participantIds,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (avatar != null) 'avatar': avatar,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final newChat = apiResponse.data!;

        state = state.copyWith(chats: [newChat, ...state.chats]);

        // Cache the new chat
        await _cacheService.cacheChat(newChat.id, newChat.toJson());

        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create chat: $e');
      return false;
    }
  }

  Future<bool> archiveChat(String chatId, bool archive) async {
    try {
      final response = await _dio.put(
        ApiConstants.archiveChat(chatId),
        queryParameters: {'archive': archive},
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        if (archive) {
          // Move from chats to archived
          final chatIndex = state.chats.indexWhere((chat) => chat.id == chatId);
          if (chatIndex != -1) {
            final chat = state.chats[chatIndex].copyWith(isArchived: true);
            final newChats = List<ChatModel>.from(state.chats);
            newChats.removeAt(chatIndex);

            state = state.copyWith(
              chats: newChats,
              archivedChats: [chat, ...state.archivedChats],
            );
          }
        } else {
          // Move from archived to chats
          final archivedIndex = state.archivedChats.indexWhere(
            (chat) => chat.id == chatId,
          );
          if (archivedIndex != -1) {
            final chat = state.archivedChats[archivedIndex].copyWith(
              isArchived: false,
            );
            final newArchivedChats = List<ChatModel>.from(state.archivedChats);
            newArchivedChats.removeAt(archivedIndex);

            state = state.copyWith(
              chats: [chat, ...state.chats],
              archivedChats: newArchivedChats,
            );
          }
        }

        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to ${archive ? 'archive' : 'unarchive'} chat: $e',
      );
      return false;
    }
  }

  Future<bool> pinChat(String chatId, bool pin) async {
    try {
      final response = await _dio.put(
        ApiConstants.pinChat(chatId),
        queryParameters: {'pin': pin},
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        _updateChatProperty(chatId, (chat) => chat.copyWith(isPinned: pin));
        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to ${pin ? 'pin' : 'unpin'} chat: $e',
      );
      return false;
    }
  }

  Future<bool> muteChat(
    String chatId,
    bool mute, {
    DateTime? mutedUntil,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.muteChat(chatId),
        data: {
          'mute': mute,
          if (mutedUntil != null) 'muted_until': mutedUntil.toIso8601String(),
        },
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        _updateChatProperty(
          chatId,
          (chat) => chat.copyWith(isMuted: mute, mutedUntil: mutedUntil),
        );
        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to ${mute ? 'mute' : 'unmute'} chat: $e',
      );
      return false;
    }
  }

  Future<bool> markChatAsRead(String chatId) async {
    try {
      final response = await _dio.put(ApiConstants.markChatAsRead(chatId));

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        _updateChatProperty(chatId, (chat) => chat.copyWith(unreadCount: 0));

        // Update last seen timestamp
        await _localStorage.setLastSeenChat(chatId, DateTime.now());

        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark chat as read: $e');
      return false;
    }
  }

  Future<bool> deleteChat(String chatId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteChat(chatId));

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        state = state.copyWith(
          chats: state.chats.where((chat) => chat.id != chatId).toList(),
          archivedChats: state.archivedChats
              .where((chat) => chat.id != chatId)
              .toList(),
        );

        // Remove from cache
        await _cacheService.deleteCacheEntry(chatId, 'chats');

        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete chat: $e');
      return false;
    }
  }

  void _updateChatProperty(
    String chatId,
    ChatModel Function(ChatModel) updater,
  ) {
    final chatIndex = state.chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final updatedChat = updater(state.chats[chatIndex]);
      final newChats = List<ChatModel>.from(state.chats);
      newChats[chatIndex] = updatedChat;

      state = state.copyWith(chats: newChats);

      // Cache the updated chat
      _cacheService.cacheChat(chatId, updatedChat.toJson());
    }
  }

  Future<void> _refreshSingleChat(String chatId) async {
    try {
      final response = await _dio.get(ApiConstants.getChat(chatId));

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final updatedChat = apiResponse.data!;
        _updateChatProperty(chatId, (_) => updatedChat);
      }
    } catch (e) {
      // Silently fail for background refresh
    }
  }

  void setFilter(ChatListFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  ChatModel? getChatById(String chatId) {
    try {
      return state.chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      try {
        return state.archivedChats.firstWhere((chat) => chat.id == chatId);
      } catch (e) {
        return null;
      }
    }
  }

  List<ChatModel> getChatsByType(ChatType type) {
    return state.chats.where((chat) => chat.type == type).toList();
  }

  List<ChatModel> getPinnedChats() {
    return state.chats.where((chat) => chat.isPinned).toList();
  }

  List<ChatModel> getUnreadChats() {
    return state.chats.where((chat) => chat.unreadCount > 0).toList();
  }

  List<ChatModel> getMutedChats() {
    return state.chats.where((chat) => chat.isMuted).toList();
  }
}

// Providers
final chatListProvider = StateNotifierProvider<ChatListNotifier, ChatListState>(
  (ref) {
    final dio = ref.watch(dioProvider);
    final cacheService = CacheService();
    final localStorage = LocalStorage();
    final chatSocketService = ChatSocketService();
    return ChatListNotifier(dio, cacheService, localStorage, chatSocketService);
  },
);

// Convenience providers
final chatsProvider = Provider<List<ChatModel>>((ref) {
  return ref.watch(chatListProvider).searchResults;
});

final archivedChatsProvider = Provider<List<ChatModel>>((ref) {
  return ref.watch(chatListProvider).archivedChats;
});

final chatListLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatListProvider).isLoading;
});

final chatListErrorProvider = Provider<String?>((ref) {
  return ref.watch(chatListProvider).error;
});

final totalUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(chatListProvider).totalUnreadCount;
});

final unreadChatsCountProvider = Provider<int>((ref) {
  return ref.watch(chatListProvider).unreadChatsCount;
});

final chatListFilterProvider = Provider<ChatListFilter>((ref) {
  return ref.watch(chatListProvider).filter;
});

final chatListSearchQueryProvider = Provider<String?>((ref) {
  return ref.watch(chatListProvider).searchQuery;
});

// Family providers
final chatByIdProvider = Provider.family<ChatModel?, String>((ref, chatId) {
  final notifier = ref.watch(chatListProvider.notifier);
  return notifier.getChatById(chatId);
});

final chatsByTypeProvider = Provider.family<List<ChatModel>, ChatType>((
  ref,
  type,
) {
  final notifier = ref.watch(chatListProvider.notifier);
  return notifier.getChatsByType(type);
});

final pinnedChatsProvider = Provider<List<ChatModel>>((ref) {
  final notifier = ref.watch(chatListProvider.notifier);
  return notifier.getPinnedChats();
});

final unreadChatsProvider = Provider<List<ChatModel>>((ref) {
  final notifier = ref.watch(chatListProvider.notifier);
  return notifier.getUnreadChats();
});

final mutedChatsProvider = Provider<List<ChatModel>>((ref) {
  final notifier = ref.watch(chatListProvider.notifier);
  return notifier.getMutedChats();
});
