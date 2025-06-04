import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/api/api_service.dart';
import '../../services/websocket/chat_socket.dart';
import '../../services/storage/cache_service.dart';
import '../../models/chat/chat_model.dart';
import '../../models/common/api_response.dart';

// Chat list filter
enum ChatListFilter { all, unread, archived, pinned, muted }

// Chat list sort
enum ChatListSort { lastMessage, name, createdAt, unreadCount }

// Chat list state
class ChatListState {
  final List<ChatModel> chats;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isInitialized;
  final DateTime? lastFetchTime;
  final ChatListFilter filter;
  final ChatListSort sort;
  final String searchQuery;
  final int page;

  ChatListState({
    this.chats = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isInitialized = false,
    this.lastFetchTime,
    this.filter = ChatListFilter.all,
    this.sort = ChatListSort.lastMessage,
    this.searchQuery = '',
    this.page = 1,
  });

  ChatListState copyWith({
    List<ChatModel>? chats,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isInitialized,
    DateTime? lastFetchTime,
    ChatListFilter? filter,
    ChatListSort? sort,
    String? searchQuery,
    int? page,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
    );
  }

  List<ChatModel> get filteredChats {
    List<ChatModel> filtered = chats;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((chat) {
        return chat.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            chat.description?.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ==
                true;
      }).toList();
    }

    // Apply status filter
    switch (filter) {
      case ChatListFilter.unread:
        filtered = filtered.where((chat) => chat.hasUnreadMessages).toList();
        break;
      case ChatListFilter.archived:
        filtered = filtered.where((chat) => chat.isArchived).toList();
        break;
      case ChatListFilter.pinned:
        filtered = filtered.where((chat) => chat.isPinned).toList();
        break;
      case ChatListFilter.muted:
        filtered = filtered.where((chat) => chat.isMuted).toList();
        break;
      case ChatListFilter.all:
      default:
        filtered = filtered.where((chat) => !chat.isArchived).toList();
        break;
    }

    // Apply sorting
    switch (sort) {
      case ChatListSort.lastMessage:
        filtered.sort((a, b) {
          final aTime = a.updatedAt;
          final bTime = b.updatedAt;
          return bTime.compareTo(aTime);
        });
        break;
      case ChatListSort.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ChatListSort.createdAt:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ChatListSort.unreadCount:
        filtered.sort((a, b) => b.unreadCount.compareTo(a.unreadCount));
        break;
    }

    // Pinned chats always at top
    final pinnedChats = filtered.where((chat) => chat.isPinned).toList();
    final unpinnedChats = filtered.where((chat) => !chat.isPinned).toList();

    return [...pinnedChats, ...unpinnedChats];
  }

  ChatModel? getChat(String chatId) {
    try {
      return chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  int get totalUnreadCount =>
      chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  int get unreadChatsCount =>
      chats.where((chat) => chat.hasUnreadMessages).length;
  int get pinnedChatsCount => chats.where((chat) => chat.isPinned).length;
  int get archivedChatsCount => chats.where((chat) => chat.isArchived).length;
}

class ChatListNotifier extends StateNotifier<AsyncValue<ChatListState>> {
  final ApiService _apiService;
  final ChatSocketService _chatSocketService;
  final CacheService _cacheService;

  StreamSubscription<ChatUpdate>? _chatUpdateSubscription;
  StreamSubscription<ChatMessage>? _messageSubscription;

  Timer? _refreshTimer;
  Timer? _searchDebounceTimer;

  static const int _chatsPerPage = 20;
  static const Duration _cacheExpiry = Duration(minutes: 15);
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);

  ChatListNotifier({
    required ApiService apiService,
    required ChatSocketService chatSocketService,
    required CacheService cacheService,
  }) : _apiService = apiService,
       _chatSocketService = chatSocketService,
       _cacheService = cacheService,
       super(AsyncValue.data(ChatListState())) {
    _initialize();
  }

  void _initialize() async {
    _setupSubscriptions();
    _setupPeriodicRefresh();
    await _loadChats();
  }

  void _setupSubscriptions() {
    // Listen to chat updates
    _chatUpdateSubscription = _chatSocketService.chatUpdates.listen(
      _handleChatUpdate,
    );

    // Listen to new messages to update chat list order
    _messageSubscription = _chatSocketService.messageReceived.listen(
      _handleNewMessage,
    );
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => refreshChats());
  }

  void _handleChatUpdate(ChatUpdate update) {
    switch (update.type) {
      case ChatUpdateType.chatCreated:
        _handleChatCreated(update.data);
        break;
      case ChatUpdateType.chatDeleted:
        _handleChatDeleted(update.data);
        break;
      case ChatUpdateType.chatUpdated:
        _handleChatUpdated(update.data);
        break;
      default:
        break;
    }
  }

  void _handleChatCreated(Map<String, dynamic> data) {
    state.whenData((chatListState) {
      final chatData = data['chat'] as Map<String, dynamic>?;
      if (chatData != null) {
        final newChat = ChatModel.fromJson(chatData);
        final updatedChats = [newChat, ...chatListState.chats];
        state = AsyncValue.data(chatListState.copyWith(chats: updatedChats));
        _cacheChats(updatedChats);
      }
    });
  }

  void _handleChatDeleted(Map<String, dynamic> data) {
    final chatId = data['chat_id'] as String?;
    if (chatId == null) return;

    state.whenData((chatListState) {
      final updatedChats = chatListState.chats
          .where((chat) => chat.id != chatId)
          .toList();
      state = AsyncValue.data(chatListState.copyWith(chats: updatedChats));
      _cacheChats(updatedChats);
    });
  }

  void _handleChatUpdated(Map<String, dynamic> data) {
    final chatId = data['chat_id'] as String?;
    if (chatId == null) return;

    state.whenData((chatListState) {
      final chatIndex = chatListState.chats.indexWhere(
        (chat) => chat.id == chatId,
      );
      if (chatIndex == -1) return;

      final updatedChats = List<ChatModel>.from(chatListState.chats);
      ChatModel updatedChat = updatedChats[chatIndex];

      // Update chat properties based on data
      if (data.containsKey('name')) {
        updatedChat = updatedChat.copyWith(name: data['name']);
      }
      if (data.containsKey('description')) {
        updatedChat = updatedChat.copyWith(description: data['description']);
      }
      if (data.containsKey('avatar')) {
        updatedChat = updatedChat.copyWith(avatar: data['avatar']);
      }
      if (data.containsKey('is_muted')) {
        updatedChat = updatedChat.copyWith(isMuted: data['is_muted']);
      }
      if (data.containsKey('is_pinned')) {
        updatedChat = updatedChat.copyWith(isPinned: data['is_pinned']);
      }
      if (data.containsKey('is_archived')) {
        updatedChat = updatedChat.copyWith(isArchived: data['is_archived']);
      }

      updatedChats[chatIndex] = updatedChat;
      state = AsyncValue.data(chatListState.copyWith(chats: updatedChats));
      _cacheChats(updatedChats);
    });
  }

  void _handleNewMessage(ChatMessage message) {
    state.whenData((chatListState) {
      final chatIndex = chatListState.chats.indexWhere(
        (chat) => chat.id == message.chatId,
      );
      if (chatIndex == -1) return;

      final updatedChats = List<ChatModel>.from(chatListState.chats);
      final chat = updatedChats[chatIndex];

      // Move chat to top and update unread count
      final updatedChat = chat.copyWith(
        unreadCount: message.isFromCurrentUser
            ? chat.unreadCount
            : chat.unreadCount + 1,
        updatedAt: message.createdAt,
        // You can add lastMessage here if your ChatModel supports it
      );

      updatedChats.removeAt(chatIndex);
      updatedChats.insert(0, updatedChat);

      state = AsyncValue.data(chatListState.copyWith(chats: updatedChats));
    });
  }

  Future<void> _loadChats() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      // Try to load from cache first
      final cachedChats = await _loadChatsFromCache();

      if (cachedChats.isNotEmpty) {
        state = AsyncValue.data(
          state.value!.copyWith(
            chats: cachedChats,
            isLoading: false,
            isInitialized: true,
          ),
        );
      }

      // Load from API
      await _loadChatsFromAPI();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<ChatModel>> _loadChatsFromCache() async {
    try {
      final cachedData = await _cacheService.getCachedChats();
      return cachedData.map((data) => ChatModel.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading chats from cache: $e');
      return [];
    }
  }

  Future<void> _loadChatsFromAPI() async {
    try {
      final currentState = state.value!;

      final response = await _apiService.getUserChats(
        page: 1,
        limit: _chatsPerPage,
        archived: currentState.filter == ChatListFilter.archived,
      );

      if (response.success && response.data != null) {
        final apiChats = response.data!;
        await _cacheChats(apiChats);

        state = AsyncValue.data(
          currentState.copyWith(
            chats: apiChats,
            isLoading: false,
            isInitialized: true,
            lastFetchTime: DateTime.now(),
            hasMore: apiChats.length >= _chatsPerPage,
            page: 1,
          ),
        );

        if (kDebugMode) print('✅ Loaded ${apiChats.length} chats');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading chats from API: $e');

      state.whenData((chatListState) {
        if (chatListState.chats.isEmpty) {
          state = AsyncValue.error(e, StackTrace.current);
        } else {
          state = AsyncValue.data(
            chatListState.copyWith(
              isLoading: false,
              isInitialized: true,
              error: e.toString(),
            ),
          );
        }
      });
    }
  }

  Future<void> loadMoreChats() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _apiService.getUserChats(
        page: currentState.page + 1,
        limit: _chatsPerPage,
        archived: currentState.filter == ChatListFilter.archived,
      );

      if (response.success && response.data != null) {
        final newChats = response.data!;
        final allChats = [...currentState.chats, ...newChats];

        await _cacheChats(allChats);

        state = AsyncValue.data(
          currentState.copyWith(
            chats: allChats,
            isLoadingMore: false,
            hasMore: newChats.length >= _chatsPerPage,
            page: currentState.page + 1,
          ),
        );

        if (kDebugMode) print('✅ Loaded ${newChats.length} more chats');
      }
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  Future<void> refreshChats() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoading) return;

    try {
      final response = await _apiService.getUserChats(
        page: 1,
        limit: _chatsPerPage * currentState.page,
        archived: currentState.filter == ChatListFilter.archived,
      );

      if (response.success && response.data != null) {
        final refreshedChats = response.data!;
        await _cacheChats(refreshedChats);

        state = AsyncValue.data(
          currentState.copyWith(
            chats: refreshedChats,
            lastFetchTime: DateTime.now(),
            error: null,
          ),
        );

        if (kDebugMode) print('✅ Refreshed ${refreshedChats.length} chats');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error refreshing chats: $e');
    }
  }

  // Filter and search methods
  void setFilter(ChatListFilter filter) {
    state.whenData((chatListState) {
      if (chatListState.filter != filter) {
        state = AsyncValue.data(
          chatListState.copyWith(filter: filter, page: 1),
        );
        _loadChatsFromAPI(); // Reload with new filter
      }
    });
  }

  void setSort(ChatListSort sort) {
    state.whenData((chatListState) {
      state = AsyncValue.data(chatListState.copyWith(sort: sort));
    });
  }

  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      state.whenData((chatListState) {
        state = AsyncValue.data(chatListState.copyWith(searchQuery: query));
      });
    });
  }

  // Chat management methods
  Future<ChatModel> createChat({
    required String type,
    required List<String> participants,
    String? name,
    String? description,
  }) async {
    try {
      final response = await _apiService.createChat(
        type: type,
        participants: participants,
        name: name,
        description: description,
      );

      if (response.success && response.data != null) {
        final newChat = response.data!;

        state.whenData((chatListState) {
          final updatedChats = [newChat, ...chatListState.chats];
          state = AsyncValue.data(chatListState.copyWith(chats: updatedChats));
        });

        return newChat;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating chat: $e');
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final response = await _apiService.deleteChat(chatId);

      if (response.success) {
        state.whenData((chatListState) {
          final updatedChats = chatListState.chats
              .where((chat) => chat.id != chatId)
              .toList();
          state = AsyncValue.data(chatListState.copyWith(chats: updatedChats));
          _cacheChats(updatedChats);
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  Future<void> archiveChat(String chatId, bool archive) async {
    try {
      final response = await _apiService.archiveChat(chatId, archive);

      if (response.success) {
        state.whenData((chatListState) {
          final chatIndex = chatListState.chats.indexWhere(
            (chat) => chat.id == chatId,
          );
          if (chatIndex != -1) {
            final updatedChats = List<ChatModel>.from(chatListState.chats);
            updatedChats[chatIndex] = updatedChats[chatIndex].copyWith(
              isArchived: archive,
            );
            state = AsyncValue.data(
              chatListState.copyWith(chats: updatedChats),
            );
            _cacheChats(updatedChats);
          }
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pinChat(String chatId, bool pin) async {
    try {
      final response = await _apiService.pinChat(chatId, pin);

      if (response.success) {
        state.whenData((chatListState) {
          final chatIndex = chatListState.chats.indexWhere(
            (chat) => chat.id == chatId,
          );
          if (chatIndex != -1) {
            final updatedChats = List<ChatModel>.from(chatListState.chats);
            updatedChats[chatIndex] = updatedChats[chatIndex].copyWith(
              isPinned: pin,
            );
            state = AsyncValue.data(
              chatListState.copyWith(chats: updatedChats),
            );
            _cacheChats(updatedChats);
          }
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> muteChat(
    String chatId, {
    required bool mute,
    DateTime? mutedUntil,
  }) async {
    try {
      final response = await _apiService.muteChat(
        chatId,
        mute: mute,
        mutedUntil: mutedUntil,
      );

      if (response.success) {
        state.whenData((chatListState) {
          final chatIndex = chatListState.chats.indexWhere(
            (chat) => chat.id == chatId,
          );
          if (chatIndex != -1) {
            final updatedChats = List<ChatModel>.from(chatListState.chats);
            updatedChats[chatIndex] = updatedChats[chatIndex].copyWith(
              isMuted: mute,
              mutedUntil: mutedUntil,
            );
            state = AsyncValue.data(
              chatListState.copyWith(chats: updatedChats),
            );
            _cacheChats(updatedChats);
          }
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      final response = await _apiService.markChatAsRead(chatId);

      if (response.success) {
        state.whenData((chatListState) {
          final chatIndex = chatListState.chats.indexWhere(
            (chat) => chat.id == chatId,
          );
          if (chatIndex != -1) {
            final updatedChats = List<ChatModel>.from(chatListState.chats);
            updatedChats[chatIndex] = updatedChats[chatIndex].copyWith(
              unreadCount: 0,
            );
            state = AsyncValue.data(
              chatListState.copyWith(chats: updatedChats),
            );
            _cacheChats(updatedChats);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error marking chat as read: $e');
    }
  }

  Future<void> _cacheChats(List<ChatModel> chats) async {
    try {
      final chatData = chats.map((chat) => chat.toJson()).toList();
      await _cacheService.cacheChats(chatData);
    } catch (e) {
      if (kDebugMode) print('❌ Error caching chats: $e');
    }
  }

  // Utility methods
  List<ChatModel> get chats => state.value?.chats ?? [];
  List<ChatModel> get filteredChats => state.value?.filteredChats ?? [];
  bool get isLoading => state.value?.isLoading ?? false;
  bool get isLoadingMore => state.value?.isLoadingMore ?? false;
  bool get hasMore => state.value?.hasMore ?? false;
  int get totalUnreadCount => state.value?.totalUnreadCount ?? 0;
  int get unreadChatsCount => state.value?.unreadChatsCount ?? 0;
  ChatListFilter get currentFilter => state.value?.filter ?? ChatListFilter.all;
  ChatListSort get currentSort => state.value?.sort ?? ChatListSort.lastMessage;
  String get searchQuery => state.value?.searchQuery ?? '';

  ChatModel? getChat(String chatId) => state.value?.getChat(chatId);

  @override
  void dispose() {
    _chatUpdateSubscription?.cancel();
    _messageSubscription?.cancel();
    _refreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}

// Providers
final chatListProvider =
    StateNotifierProvider<ChatListNotifier, AsyncValue<ChatListState>>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      final chatSocketService = ref.watch(chatSocketServiceProvider);
      final cacheService = CacheService();

      return ChatListNotifier(
        apiService: apiService,
        chatSocketService: chatSocketService,
        cacheService: cacheService,
      );
    });

// Convenience providers
final chatsProvider = Provider<List<ChatModel>>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.whenOrNull(data: (state) => state.chats) ?? [];
});

final filteredChatsProvider = Provider<List<ChatModel>>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.whenOrNull(data: (state) => state.filteredChats) ?? [];
});

final chatListLoadingProvider = Provider<bool>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final totalUnreadCountProvider = Provider<int>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.whenOrNull(data: (state) => state.totalUnreadCount) ?? 0;
});

final unreadChatsCountProvider = Provider<int>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.whenOrNull(data: (state) => state.unreadChatsCount) ?? 0;
});

final chatListFilterProvider = Provider<ChatListFilter>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.whenOrNull(data: (state) => state.filter) ??
      ChatListFilter.all;
});

final chatListSearchQueryProvider = Provider<String>((ref) {
  final chatListState = ref.watch(chatListProvider);
  return chatListState.whenOrNull(data: (state) => state.searchQuery) ?? '';
});

final specificChatProvider = Provider.family<ChatModel?, String>((ref, chatId) {
  final chats = ref.watch(chatsProvider);
  try {
    return chats.firstWhere((chat) => chat.id == chatId);
  } catch (e) {
    return null;
  }
});
