import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/api/api_service.dart';
import '../../services/storage/cache_service.dart';
import '../../models/chat/message_model.dart';
import '../../models/common/api_response.dart';
import '../../services/websocket/chat_socket.dart';
import '../../services/websocket/websocket_event_types.dart';
import '../../core/config/dio_config.dart';

// Message state for a specific chat
class ChatMessageState {
  final String chatId;
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isInitialized;
  final DateTime? lastFetchTime;
  final String? beforeMessageId;

  ChatMessageState({
    required this.chatId,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isInitialized = false,
    this.lastFetchTime,
    this.beforeMessageId,
  });

  ChatMessageState copyWith({
    String? chatId,
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isInitialized,
    DateTime? lastFetchTime,
    String? beforeMessageId,
  }) {
    return ChatMessageState(
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      beforeMessageId: beforeMessageId ?? this.beforeMessageId,
    );
  }

  MessageModel? getMessage(String messageId) {
    try {
      return messages.firstWhere((msg) => msg.id == messageId);
    } catch (e) {
      return null;
    }
  }

  int getMessageIndex(String messageId) {
    return messages.indexWhere((msg) => msg.id == messageId);
  }

  List<MessageModel> getUnreadMessages() {
    return messages
        .where((msg) => msg.status != MessageStatusType.read)
        .toList();
  }

  int get unreadCount => getUnreadMessages().length;
}

class MessageNotifier extends StateNotifier<AsyncValue<ChatMessageState>> {
  final String chatId;
  final ApiService _apiService;
  final ChatSocketService _chatSocketService;
  final CacheService _cacheService;

  StreamSubscription<MessageModel>? _messageSubscription;
  StreamSubscription<MessageStatusUpdate>? _statusSubscription;
  StreamSubscription<MessageReactionEvent>? _reactionSubscription;
  StreamSubscription<ChatUpdate>? _updateSubscription;

  Timer? _sendDebounceTimer;
  final Map<String, Completer<MessageModel>> _sendingMessages = {};

  static const int _messagesPerPage = 50;

  MessageNotifier({
    required this.chatId,
    required ApiService apiService,
    required ChatSocketService chatSocketService,
    required CacheService cacheService,
  }) : _apiService = apiService,
       _chatSocketService = chatSocketService,
       _cacheService = cacheService,
       super(AsyncValue.data(ChatMessageState(chatId: chatId))) {
    _initialize();
  }

  void _initialize() async {
    _setupSubscriptions();
    await _loadInitialMessages();
  }

  void _setupSubscriptions() {
    _messageSubscription = _chatSocketService
        .getMessagesForChat(chatId)
        .listen(_handleNewMessage);

    _statusSubscription = _chatSocketService.messageStatus
        .where((status) => _hasMessageWithId(status.messageId))
        .listen(_handleMessageStatus);

    _reactionSubscription = _chatSocketService.reactions
        .where((reaction) => _hasMessageWithId(reaction.messageId))
        .listen(_handleMessageReaction);

    _updateSubscription = _chatSocketService
        .getUpdatesForChat(chatId)
        .listen(_handleChatUpdate);
  }

  bool _hasMessageWithId(String messageId) {
    return state.whenOrNull(
          data: (messageState) => messageState.getMessage(messageId) != null,
        ) ??
        false;
  }

  void _handleNewMessage(MessageModel message) {
    state.whenData((messageState) {
      if (messageState.getMessage(message.id) != null) return;

      final updatedMessages = [message, ...messageState.messages];

      state = AsyncValue.data(messageState.copyWith(messages: updatedMessages));
      _cacheMessage(message);
    });
  }

  void _handleMessageStatus(MessageStatusUpdate status) {
    state.whenData((messageState) {
      final messageIndex = messageState.getMessageIndex(status.messageId);
      if (messageIndex == -1) return;

      final updatedMessages = List<MessageModel>.from(messageState.messages);
      final message = updatedMessages[messageIndex];

      List<MessageReadReceipt> updatedReadReceipts = List.from(
        message.readReceipts,
      );

      if (status.status == MessageStatusType.read && status.userId != null) {
        final existingReceiptIndex = updatedReadReceipts.indexWhere(
          (receipt) => receipt.userId == status.userId!,
        );

        if (existingReceiptIndex == -1) {
          updatedReadReceipts.add(
            MessageReadReceipt(
              userId: status.userId!,
              userName: status.userId!, // You might want to get actual name
              readAt: status.timestamp,
            ),
          );
        }
      }

      updatedMessages[messageIndex] = message.copyWith(
        status: status.status,
        readReceipts: updatedReadReceipts,
      );

      state = AsyncValue.data(messageState.copyWith(messages: updatedMessages));
    });
  }

  void _handleMessageReaction(MessageReactionEvent reactionEvent) {
    state.whenData((messageState) {
      final messageIndex = messageState.getMessageIndex(
        reactionEvent.messageId,
      );
      if (messageIndex == -1) return;

      final updatedMessages = List<MessageModel>.from(messageState.messages);
      final message = updatedMessages[messageIndex];
      final updatedReactions = List<MessageReaction>.from(message.reactions);

      if (reactionEvent.action == ReactionAction.add) {
        updatedReactions.removeWhere((r) => r.userId == reactionEvent.userId);
        updatedReactions.add(
          MessageReaction(
            emoji: reactionEvent.emoji,
            userId: reactionEvent.userId,
            userName: reactionEvent.userName,
            createdAt: reactionEvent.timestamp,
          ),
        );
      } else {
        updatedReactions.removeWhere(
          (r) =>
              r.userId == reactionEvent.userId &&
              r.emoji == reactionEvent.emoji,
        );
      }

      updatedMessages[messageIndex] = message.copyWith(
        reactions: updatedReactions,
      );
      state = AsyncValue.data(messageState.copyWith(messages: updatedMessages));
    });
  }

  void _handleChatUpdate(ChatUpdate update) {
    switch (update.type) {
      case ChatUpdateType.messageDeleted:
        _handleMessageDeleted(update.data);
        break;
      case ChatUpdateType.messageEdited:
        _handleMessageEdited(update.data);
        break;
      default:
        break;
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String?;
    if (messageId == null) return;

    state.whenData((messageState) {
      final messageIndex = messageState.getMessageIndex(messageId);
      if (messageIndex == -1) return;

      final forEveryone = data['for_everyone'] as bool? ?? false;

      if (forEveryone) {
        final updatedMessages = List<MessageModel>.from(messageState.messages)
          ..removeAt(messageIndex);
        state = AsyncValue.data(
          messageState.copyWith(messages: updatedMessages),
        );
      } else {
        final updatedMessages = List<MessageModel>.from(messageState.messages);
        updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
          isDeleted: true,
          content: 'This message was deleted',
        );
        state = AsyncValue.data(
          messageState.copyWith(messages: updatedMessages),
        );
      }
    });
  }

  void _handleMessageEdited(Map<String, dynamic> data) {
    final messageId = data['message_id'] as String?;
    final newContent = data['content'] as String?;

    if (messageId == null || newContent == null) return;

    state.whenData((messageState) {
      final messageIndex = messageState.getMessageIndex(messageId);
      if (messageIndex == -1) return;

      final updatedMessages = List<MessageModel>.from(messageState.messages);
      updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
        content: newContent,
        isEdited: true,
      );

      state = AsyncValue.data(messageState.copyWith(messages: updatedMessages));
    });
  }

  Future<void> _loadInitialMessages() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final cachedMessages = await _loadMessagesFromCache();

      if (cachedMessages.isNotEmpty) {
        state = AsyncValue.data(
          state.value!.copyWith(
            messages: cachedMessages,
            isLoading: false,
            isInitialized: true,
          ),
        );
      }

      await _loadMessagesFromAPI();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<MessageModel>> _loadMessagesFromCache() async {
    try {
      final cachedData = await _cacheService.getCachedMessages(
        chatId,
        limit: _messagesPerPage,
      );
      return cachedData.map((data) => MessageModel.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading messages from cache: $e');
      return [];
    }
  }

  Future<void> _loadMessagesFromAPI() async {
    try {
      final response = await _apiService.getMessages(
        chatId: chatId,
        limit: _messagesPerPage,
      );

      if (response.success && response.data != null) {
        final apiMessages = response.data!;
        await _cacheMessages(apiMessages);

        state = AsyncValue.data(
          state.value!.copyWith(
            messages: apiMessages,
            isLoading: false,
            isInitialized: true,
            lastFetchTime: DateTime.now(),
            hasMore: apiMessages.length >= _messagesPerPage,
          ),
        );
      }
    } catch (e) {
      state.whenData((messageState) {
        if (messageState.messages.isEmpty) {
          state = AsyncValue.error(e, StackTrace.current);
        } else {
          state = AsyncValue.data(
            messageState.copyWith(
              isLoading: false,
              isInitialized: true,
              error: e.toString(),
            ),
          );
        }
      });
    }
  }

  Future<void> loadMoreMessages() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        currentState.messages.isEmpty) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final oldestMessage = currentState.messages.last;

      final response = await _apiService.getMessages(
        chatId: chatId,
        limit: _messagesPerPage,
        before: oldestMessage.id,
      );

      if (response.success && response.data != null) {
        final newMessages = response.data!;
        await _cacheMessages(newMessages);

        final allMessages = [...currentState.messages, ...newMessages];

        state = AsyncValue.data(
          currentState.copyWith(
            messages: allMessages,
            isLoadingMore: false,
            hasMore: newMessages.length >= _messagesPerPage,
          ),
        );
      }
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  Future<MessageModel> sendMessage({
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
    DateTime? scheduledAt,
  }) async {
    try {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = MessageModel(
        id: tempId,
        chatId: chatId,
        senderId: 'current_user',
        type: type,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        replyToId: replyToId,
        mentions: mentions ?? [],
        status: MessageStatusType.sending,
      );

      // Add to UI immediately
      state.whenData((messageState) {
        final updatedMessages = [tempMessage, ...messageState.messages];
        state = AsyncValue.data(
          messageState.copyWith(messages: updatedMessages),
        );
      });

      final completer = Completer<MessageModel>();
      _sendingMessages[tempId] = completer;

      final response = await _apiService.sendMessage(
        chatId: chatId,
        type: type.value,
        content: content,
        replyToId: replyToId,
        mentions: mentions,
        metadata: metadata,
        scheduledAt: scheduledAt,
      );

      if (response.success && response.data != null) {
        final sentMessage = response.data!;

        state.whenData((messageState) {
          final updatedMessages = messageState.messages.map((msg) {
            if (msg.id == tempId) {
              return sentMessage.copyWith(status: MessageStatusType.sent);
            }
            return msg;
          }).toList();

          state = AsyncValue.data(
            messageState.copyWith(messages: updatedMessages),
          );
        });

        await _cacheMessage(sentMessage);
        _sendingMessages.remove(tempId);
        completer.complete(sentMessage);

        return sentMessage;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      // Update message status to failed
      state.whenData((messageState) {
        final updatedMessages = messageState.messages.map((msg) {
          if (msg.id.startsWith('temp_')) {
            return msg.copyWith(status: MessageStatusType.failed);
          }
          return msg;
        }).toList();

        state = AsyncValue.data(
          messageState.copyWith(messages: updatedMessages),
        );
      });

      rethrow;
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      final response = await _apiService.updateMessage(
        messageId,
        content: newContent,
      );
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMessage(
    String messageId, {
    bool forEveryone = false,
  }) async {
    try {
      final response = await _apiService.deleteMessage(
        messageId,
        forEveryone: forEveryone,
      );
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addReaction(String messageId, String emoji) async {
    try {
      final response = await _apiService.addReaction(messageId, emoji);
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeReaction(String messageId) async {
    try {
      final response = await _apiService.removeReaction(messageId);
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(List<String> messageIds) async {
    try {
      final response = await _apiService.markMultipleAsRead(messageIds);
      if (response.success) {
        state.whenData((messageState) {
          final updatedMessages = messageState.messages.map((msg) {
            if (messageIds.contains(msg.id)) {
              return msg.copyWith(status: MessageStatusType.read);
            }
            return msg;
          }).toList();

          state = AsyncValue.data(
            messageState.copyWith(messages: updatedMessages),
          );
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error marking messages as read: $e');
    }
  }

  Future<void> forwardMessage(String messageId, String toChatId) async {
    try {
      final response = await _apiService.forwardMessage(messageId, toChatId);
      if (!response.success) throw Exception(response.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheMessage(MessageModel message) async {
    try {
      await _cacheService.cacheMessage(message.id, message.toJson());
    } catch (e) {
      if (kDebugMode) print('❌ Error caching message: $e');
    }
  }

  Future<void> _cacheMessages(List<MessageModel> messages) async {
    try {
      final messageData = messages.map((msg) => msg.toJson()).toList();
      await _cacheService.cacheMessages(messageData);
    } catch (e) {
      if (kDebugMode) print('❌ Error caching messages: $e');
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _reactionSubscription?.cancel();
    _updateSubscription?.cancel();
    _sendDebounceTimer?.cancel();

    for (final completer in _sendingMessages.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Provider disposed'));
      }
    }
    _sendingMessages.clear();

    super.dispose();
  }
}

// Providers
final messageProvider = StateNotifierProvider.autoDispose
    .family<MessageNotifier, AsyncValue<ChatMessageState>, String>((
      ref,
      chatId,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      final chatSocketService = ref.watch(chatSocketServiceProvider);
      final cacheService = CacheService();

      return MessageNotifier(
        chatId: chatId,
        apiService: apiService,
        chatSocketService: chatSocketService,
        cacheService: cacheService,
      );
    });

// Convenience providers
final messagesProvider = Provider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  final messageState = ref.watch(messageProvider(chatId));
  return messageState.whenOrNull(data: (state) => state.messages) ?? [];
});

final messageLoadingProvider = Provider.family<bool, String>((ref, chatId) {
  final messageState = ref.watch(messageProvider(chatId));
  return messageState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final messageCountProvider = Provider.family<int, String>((ref, chatId) {
  final messages = ref.watch(messagesProvider(chatId));
  return messages.length;
});

final unreadMessageCountProvider = Provider.family<int, String>((ref, chatId) {
  final messageState = ref.watch(messageProvider(chatId));
  return messageState.whenOrNull(data: (state) => state.unreadCount) ?? 0;
});

final specificMessageProvider =
    Provider.family<MessageModel?, (String, String)>((ref, params) {
      final chatId = params.$1;
      final messageId = params.$2;
      final messages = ref.watch(messagesProvider(chatId));

      try {
        return messages.firstWhere((msg) => msg.id == messageId);
      } catch (e) {
        return null;
      }
    });
