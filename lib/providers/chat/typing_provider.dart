import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/websocket/chat_socket.dart';
import '../../services/storage/cache_service.dart';

// Typing state for a chat
class ChatTypingState {
  final String chatId;
  final Set<String> typingUsers;
  final bool isUserTyping;
  final DateTime? lastTypingTime;

  ChatTypingState({
    required this.chatId,
    this.typingUsers = const {},
    this.isUserTyping = false,
    this.lastTypingTime,
  });

  ChatTypingState copyWith({
    String? chatId,
    Set<String>? typingUsers,
    bool? isUserTyping,
    DateTime? lastTypingTime,
  }) {
    return ChatTypingState(
      chatId: chatId ?? this.chatId,
      typingUsers: typingUsers ?? this.typingUsers,
      isUserTyping: isUserTyping ?? this.isUserTyping,
      lastTypingTime: lastTypingTime ?? this.lastTypingTime,
    );
  }

  bool get hasTypingUsers => typingUsers.isNotEmpty;
  int get typingUserCount => typingUsers.length;

  String getTypingIndicatorText() {
    if (typingUsers.isEmpty) return '';

    final userList = typingUsers.toList();
    if (userList.length == 1) {
      return '${userList.first} is typing...';
    } else if (userList.length == 2) {
      return '${userList.join(' and ')} are typing...';
    } else {
      return '${userList.take(2).join(', ')} and ${userList.length - 2} others are typing...';
    }
  }
}

// Global typing state
class TypingState {
  final Map<String, ChatTypingState> chatTypingStates;
  final bool isInitialized;

  TypingState({this.chatTypingStates = const {}, this.isInitialized = false});

  TypingState copyWith({
    Map<String, ChatTypingState>? chatTypingStates,
    bool? isInitialized,
  }) {
    return TypingState(
      chatTypingStates: chatTypingStates ?? this.chatTypingStates,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  ChatTypingState? getTypingState(String chatId) => chatTypingStates[chatId];
  bool isAnyoneTypingInChat(String chatId) =>
      chatTypingStates[chatId]?.hasTypingUsers ?? false;
  bool isUserTypingInChat(String chatId) =>
      chatTypingStates[chatId]?.isUserTyping ?? false;
}

class TypingNotifier extends StateNotifier<TypingState> {
  final ChatSocketService _chatSocketService;
  final CacheService _cacheService;

  final Map<String, Timer> _typingTimers = {};
  final Map<String, Timer> _cleanupTimers = {};
  StreamSubscription<TypingStatus>? _typingSubscription;

  static const Duration _typingTimeout = Duration(seconds: 3);
  static const Duration _typingCleanupTimeout = Duration(seconds: 10);

  TypingNotifier(this._chatSocketService, this._cacheService)
    : super(TypingState()) {
    _initialize();
  }

  void _initialize() {
    _setupTypingListener();
    state = state.copyWith(isInitialized: true);
  }

  void _setupTypingListener() {
    _typingSubscription = _chatSocketService.typingStatus.listen(
      _handleTypingStatus,
      onError: (error) {
        if (kDebugMode) print('❌ Error in typing status stream: $error');
      },
    );
  }

  void _handleTypingStatus(TypingStatus status) {
    try {
      final chatId = status.chatId;
      final userId = status.userId;
      final userName = status.userName ?? userId;
      final isTyping = status.isTyping;

      final currentChatState =
          state.chatTypingStates[chatId] ?? ChatTypingState(chatId: chatId);
      Set<String> updatedTypingUsers = Set.from(currentChatState.typingUsers);

      if (isTyping) {
        updatedTypingUsers.add(userName);
        _cleanupTimers['${chatId}_$userId']?.cancel();
        _cleanupTimers['${chatId}_$userId'] = Timer(_typingCleanupTimeout, () {
          _removeTypingUser(chatId, userName);
        });
      } else {
        updatedTypingUsers.remove(userName);
        _cleanupTimers.remove('${chatId}_$userId')?.cancel();
      }

      final updatedChatState = currentChatState.copyWith(
        typingUsers: updatedTypingUsers,
      );
      final updatedChatStates = Map<String, ChatTypingState>.from(
        state.chatTypingStates,
      );

      if (updatedTypingUsers.isEmpty) {
        updatedChatStates.remove(chatId);
      } else {
        updatedChatStates[chatId] = updatedChatState;
      }

      state = state.copyWith(chatTypingStates: updatedChatStates);
    } catch (e) {
      if (kDebugMode) print('❌ Error handling typing status: $e');
    }
  }

  void _removeTypingUser(String chatId, String userName) {
    final currentChatState = state.chatTypingStates[chatId];
    if (currentChatState == null) return;

    final updatedTypingUsers = Set<String>.from(currentChatState.typingUsers)
      ..remove(userName);
    final updatedChatStates = Map<String, ChatTypingState>.from(
      state.chatTypingStates,
    );

    if (updatedTypingUsers.isEmpty) {
      updatedChatStates.remove(chatId);
    } else {
      updatedChatStates[chatId] = currentChatState.copyWith(
        typingUsers: updatedTypingUsers,
      );
    }

    state = state.copyWith(chatTypingStates: updatedChatStates);
  }

  void startTyping(String chatId) {
    try {
      final currentChatState =
          state.chatTypingStates[chatId] ?? ChatTypingState(chatId: chatId);

      if (!currentChatState.isUserTyping) {
        final updatedChatState = currentChatState.copyWith(
          isUserTyping: true,
          lastTypingTime: DateTime.now(),
        );

        final updatedChatStates = Map<String, ChatTypingState>.from(
          state.chatTypingStates,
        );
        updatedChatStates[chatId] = updatedChatState;
        state = state.copyWith(chatTypingStates: updatedChatStates);

        _chatSocketService.startTyping(chatId);
      }

      _typingTimers[chatId]?.cancel();
      _typingTimers[chatId] = Timer(_typingTimeout, () => stopTyping(chatId));
    } catch (e) {
      if (kDebugMode) print('❌ Error starting typing: $e');
    }
  }

  void stopTyping(String chatId) {
    try {
      final currentChatState = state.chatTypingStates[chatId];
      if (currentChatState?.isUserTyping == true) {
        final updatedChatState = currentChatState!.copyWith(
          isUserTyping: false,
        );
        final updatedChatStates = Map<String, ChatTypingState>.from(
          state.chatTypingStates,
        );

        if (updatedChatState.typingUsers.isEmpty) {
          updatedChatStates.remove(chatId);
        } else {
          updatedChatStates[chatId] = updatedChatState;
        }

        state = state.copyWith(chatTypingStates: updatedChatStates);
        _chatSocketService.stopTyping(chatId);
      }

      _typingTimers[chatId]?.cancel();
    } catch (e) {
      if (kDebugMode) print('❌ Error stopping typing: $e');
    }
  }

  void onTextChanged(String chatId, String text) {
    if (text.isNotEmpty) {
      startTyping(chatId);
    } else {
      stopTyping(chatId);
    }
  }

  void clearTypingState(String chatId) {
    final updatedChatStates = Map<String, ChatTypingState>.from(
      state.chatTypingStates,
    );
    updatedChatStates.remove(chatId);
    state = state.copyWith(chatTypingStates: updatedChatStates);

    _typingTimers[chatId]?.cancel();
    _typingTimers.remove(chatId);

    final keysToRemove = _cleanupTimers.keys
        .where((key) => key.startsWith('${chatId}_'))
        .toList();
    for (final key in keysToRemove) {
      _cleanupTimers.remove(key)?.cancel();
    }
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    for (final timer in _typingTimers.values) timer.cancel();
    for (final timer in _cleanupTimers.values) timer.cancel();
    _typingTimers.clear();
    _cleanupTimers.clear();
    super.dispose();
  }
}

// Providers
final typingProvider = StateNotifierProvider<TypingNotifier, TypingState>((
  ref,
) {
  final chatSocketService = ref.watch(chatSocketServiceProvider);
  final cacheService = CacheService();
  return TypingNotifier(chatSocketService, cacheService);
});

final chatTypingProvider = Provider.family<ChatTypingState?, String>((
  ref,
  chatId,
) {
  final typingState = ref.watch(typingProvider);
  return typingState.getTypingState(chatId);
});

final isAnyoneTypingProvider = Provider.family<bool, String>((ref, chatId) {
  final typingState = ref.watch(typingProvider);
  return typingState.isAnyoneTypingInChat(chatId);
});

final isUserTypingProvider = Provider.family<bool, String>((ref, chatId) {
  final typingState = ref.watch(typingProvider);
  return typingState.isUserTypingInChat(chatId);
});

final typingIndicatorTextProvider = Provider.family<String, String>((
  ref,
  chatId,
) {
  final chatTypingState = ref.watch(chatTypingProvider(chatId));
  return chatTypingState?.getTypingIndicatorText() ?? '';
});
