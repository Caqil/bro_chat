import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config/dio_config.dart';
import '../../models/auth/user_model.dart';
import '../../models/common/api_response.dart';
import '../../core/constants/api_constants.dart';
import 'auth_provider.dart';

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Dio _dio;

  UserNotifier(this._dio) : super(const AsyncValue.loading());

  Future<void> loadCurrentUser() async {
    state = const AsyncValue.loading();

    try {
      final response = await _dio.get(ApiConstants.authProfile);
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        state = AsyncValue.data(apiResponse.data);
      } else {
        state = AsyncValue.error(apiResponse.message, StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? username,
    String? bio,
    String? avatar,
  }) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return false;

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (avatar != null) updateData['avatar'] = avatar;

      final response = await _dio.put(
        ApiConstants.authProfile,
        data: updateData,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        state = AsyncValue.data(apiResponse.data);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePrivacySettings(UserPrivacySettings settings) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return false;

      final response = await _dio.put(
        ApiConstants.authProfile,
        data: {'privacy_settings': settings.toJson()},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        state = AsyncValue.data(apiResponse.data);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateOnlineStatus(bool isOnline) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) return false;

      // Update local state immediately for better UX
      final updatedUser = currentUser.copyWith(
        isOnline: isOnline,
        lastSeen: isOnline ? null : DateTime.now(),
      );
      state = AsyncValue.data(updatedUser);

      // Send to server
      await _dio.put(
        '${ApiConstants.authProfile}/status',
        data: {
          'is_online': isOnline,
          if (!isOnline) 'last_seen': DateTime.now().toIso8601String(),
        },
      );

      return true;
    } catch (e) {
      // Revert on error
      await loadCurrentUser();
      return false;
    }
  }

  void updateUserFromAuth(UserModel user) {
    state = AsyncValue.data(user);
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
      final dio = ref.watch(dioProvider);
      return UserNotifier(dio);
    });

// Auto-sync user when auth changes
final userSyncProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  final userNotifier = ref.read(userProvider.notifier);

  authState.whenOrNull(
    authenticated: (user, _, __) => userNotifier.updateUserFromAuth(user),
    unauthenticated: () => userNotifier.state = const AsyncValue.data(null),
  );
});

// Convenience providers
final userDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider).value;
  return user?.name ?? user?.username ?? 'Unknown User';
});

final userAvatarProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider).value;
  return user?.avatar;
});

final userOnlineStatusProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider).value;
  return user?.isOnline ?? false;
});
