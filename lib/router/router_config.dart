import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth/auth_provider.dart';
import '../providers/auth/user_provider.dart';
import '../providers/common/connectivity_provider.dart';
import 'route_names.dart';
import 'route_transitions.dart';

/// Router configuration for the BRO Chat application
///
/// This file configures the GoRouter with all routes, authentication guards,
/// redirects, and error handling.
class RouterConfig {
  // Prevent instantiation
  RouterConfig._();

  /// Create the router configuration
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      // Initial location
      initialLocation: RouteNames.splash,

      // Error page builder
      errorPageBuilder: (context, state) => RouteTransitions.fadeIn(
        ErrorScreen(error: state.error?.toString() ?? 'Unknown error'),
        state,
      ),

      // Redirect logic for authentication
      redirect: (context, state) {
        return _handleRedirect(ref, state);
      },

      // Route configuration
      routes: [
        // ======================================================================
        // AUTHENTICATION ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.splash,
          pageBuilder: (context, state) =>
              RouteTransitions.fadeIn(const SplashScreen(), state),
        ),

        GoRoute(
          path: RouteNames.welcome,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const WelcomeScreen(), state),
        ),

        GoRoute(
          path: RouteNames.login,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const LoginScreen(), state),
        ),

        GoRoute(
          path: RouteNames.register,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const RegisterScreen(), state),
        ),

        GoRoute(
          path: RouteNames.otpVerification,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            OtpVerificationScreen(
              phoneNumber: state.uri.queryParameters['phone'] ?? '',
              countryCode: state.uri.queryParameters['country'] ?? '',
              isPasswordReset: state.uri.queryParameters['reset'] == 'true',
            ),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.passwordReset,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const PasswordResetScreen(),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.newPassword,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            NewPasswordScreen(token: state.uri.queryParameters['token'] ?? ''),
            state,
          ),
        ),

        // ======================================================================
        // MAIN APP ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.chatList,
          pageBuilder: (context, state) =>
              RouteTransitions.fadeIn(const ChatListScreen(), state),
        ),

        GoRoute(
          path: '${RouteNames.chat}/:${RouteNames.chatIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            ChatScreen(chatId: state.pathParameters[RouteNames.chatIdParam]!),
            state,
          ),
        ),

        GoRoute(
          path: '${RouteNames.groupChat}/:${RouteNames.groupIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            GroupChatScreen(
              groupId: state.pathParameters[RouteNames.groupIdParam]!,
            ),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.createChat,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromBottom(const CreateChatScreen(), state),
        ),

        GoRoute(
          path: RouteNames.createGroup,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            const CreateGroupScreen(),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.selectContacts,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            SelectContactsScreen(
              selectedContacts: state.extra as List<String>? ?? [],
              maxSelection: int.tryParse(
                state.uri.queryParameters['max'] ?? '',
              ),
            ),
            state,
          ),
        ),

        // ======================================================================
        // PROFILE & SETTINGS ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.profile,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const ProfileScreen(), state),
          routes: [
            GoRoute(
              path: ':${RouteNames.userIdParam}',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                UserProfileScreen(
                  userId: state.pathParameters[RouteNames.userIdParam]!,
                ),
                state,
              ),
            ),
          ],
        ),

        GoRoute(
          path: RouteNames.editProfile,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const EditProfileScreen(), state),
        ),

        GoRoute(
          path: RouteNames.settings,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const SettingsScreen(), state),
          routes: [
            GoRoute(
              path: 'language',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                const LanguageSettingsScreen(),
                state,
              ),
            ),
            GoRoute(
              path: 'theme',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                const ThemeSettingsScreen(),
                state,
              ),
            ),
            GoRoute(
              path: 'privacy',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                const PrivacySettingsScreen(),
                state,
              ),
            ),
            GoRoute(
              path: 'notifications',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                const NotificationSettingsScreen(),
                state,
              ),
            ),
            GoRoute(
              path: 'chat',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                const ChatSettingsScreen(),
                state,
              ),
            ),
            GoRoute(
              path: 'account',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                const AccountSettingsScreen(),
                state,
              ),
            ),
            GoRoute(
              path: 'about',
              pageBuilder: (context, state) =>
                  RouteTransitions.slideFromRight(const AboutScreen(), state),
            ),
            GoRoute(
              path: 'help',
              pageBuilder: (context, state) => RouteTransitions.slideFromRight(
                const HelpSupportScreen(),
                state,
              ),
            ),
          ],
        ),

        // ======================================================================
        // GROUP MANAGEMENT ROUTES
        // ======================================================================
        GoRoute(
          path: '${RouteNames.groupInfo}/:${RouteNames.groupIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            GroupInfoScreen(
              groupId: state.pathParameters[RouteNames.groupIdParam]!,
            ),
            state,
          ),
        ),

        GoRoute(
          path: '${RouteNames.groupSettings}/:${RouteNames.groupIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            GroupSettingsScreen(
              groupId: state.pathParameters[RouteNames.groupIdParam]!,
            ),
            state,
          ),
        ),

        GoRoute(
          path: '${RouteNames.groupMembers}/:${RouteNames.groupIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            GroupMembersScreen(
              groupId: state.pathParameters[RouteNames.groupIdParam]!,
            ),
            state,
          ),
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
                AddGroupMembersScreen(
                  groupId: state.pathParameters[RouteNames.groupIdParam]!,
                ),
                state,
              ),
            ),
          ],
        ),

        GoRoute(
          path:
              '${RouteNames.groupMemberProfile}/:${RouteNames.groupIdParam}/:${RouteNames.userIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            GroupMemberProfileScreen(
              groupId: state.pathParameters[RouteNames.groupIdParam]!,
              userId: state.pathParameters[RouteNames.userIdParam]!,
            ),
            state,
          ),
        ),

        GoRoute(
          path: '${RouteNames.groupAdminTools}/:${RouteNames.groupIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            GroupAdminToolsScreen(
              groupId: state.pathParameters[RouteNames.groupIdParam]!,
            ),
            state,
          ),
        ),

        GoRoute(
          path: '${RouteNames.groupInvite}/:${RouteNames.groupIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            GroupInviteScreen(
              groupId: state.pathParameters[RouteNames.groupIdParam]!,
            ),
            state,
          ),
        ),

        GoRoute(
          path: '${RouteNames.joinGroup}/:${RouteNames.inviteCodeParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            JoinGroupScreen(
              inviteCode: state.pathParameters[RouteNames.inviteCodeParam]!,
            ),
            state,
          ),
        ),

        // ======================================================================
        // CALL ROUTES
        // ======================================================================
        GoRoute(
          path: '${RouteNames.call}/:${RouteNames.callIdParam}',
          pageBuilder: (context, state) => RouteTransitions.fadeInWithScale(
            CallScreen(callId: state.pathParameters[RouteNames.callIdParam]!),
            state,
            duration: RouteTransitions.fastDuration,
          ),
        ),

        GoRoute(
          path: '${RouteNames.incomingCall}/:${RouteNames.callIdParam}',
          pageBuilder: (context, state) => RouteTransitions.slideFromTop(
            IncomingCallScreen(
              callId: state.pathParameters[RouteNames.callIdParam]!,
            ),
            state,
            duration: RouteTransitions.fastDuration,
          ),
        ),

        GoRoute(
          path: RouteNames.callHistory,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const CallHistoryScreen(), state),
        ),

        GoRoute(
          path: RouteNames.callSettings,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const CallSettingsScreen(),
            state,
          ),
        ),

        // ======================================================================
        // MEDIA & FILE ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.imageViewer,
          pageBuilder: (context, state) => RouteTransitions.fadeIn(
            ImageViewerScreen(
              imageUrl: state.uri.queryParameters['url'] ?? '',
              heroTag: state.uri.queryParameters['hero'],
              images: state.extra as List<String>? ?? [],
              initialIndex:
                  int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0,
            ),
            state,
            duration: RouteTransitions.fastDuration,
          ),
        ),

        GoRoute(
          path: RouteNames.videoPlayer,
          pageBuilder: (context, state) => RouteTransitions.fadeIn(
            VideoPlayerScreen(
              videoUrl: state.uri.queryParameters['url'] ?? '',
              title: state.uri.queryParameters['title'],
            ),
            state,
            duration: RouteTransitions.fastDuration,
          ),
        ),

        GoRoute(
          path: RouteNames.documentViewer,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            DocumentViewerScreen(
              documentUrl: state.uri.queryParameters['url'] ?? '',
              title: state.uri.queryParameters['title'],
            ),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.mediaGallery,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            MediaGalleryScreen(
              chatId: state.uri.queryParameters['chatId'],
              type: state.uri.queryParameters['type'],
            ),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.fileManager,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const FileManagerScreen(), state),
        ),

        GoRoute(
          path: RouteNames.camera,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            CameraScreen(mode: state.uri.queryParameters['mode'] ?? 'photo'),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.imageEditor,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            ImageEditorScreen(
              imagePath: state.uri.queryParameters['path'] ?? '',
            ),
            state,
          ),
        ),

        // ======================================================================
        // SEARCH & DISCOVERY ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.search,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            SearchScreen(initialQuery: state.uri.queryParameters['q']),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.searchMessages,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            SearchMessagesScreen(
              chatId: state.uri.queryParameters['chatId'],
              initialQuery: state.uri.queryParameters['q'],
            ),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.searchContacts,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const SearchContactsScreen(),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.searchGroups,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const SearchGroupsScreen(),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.discoverGroups,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const DiscoverGroupsScreen(),
            state,
          ),
        ),

        // ======================================================================
        // UTILITY ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.qrScanner,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromBottom(const QrScannerScreen(), state),
        ),

        GoRoute(
          path: RouteNames.qrGenerator,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            QrGeneratorScreen(
              data: state.uri.queryParameters['data'] ?? '',
              title: state.uri.queryParameters['title'],
            ),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.locationPicker,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            const LocationPickerScreen(),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.contactPicker,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            const ContactPickerScreen(),
            state,
          ),
        ),

        // ======================================================================
        // STATUS & STORIES ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.status,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const StatusScreen(), state),
        ),

        GoRoute(
          path: RouteNames.createStatus,
          pageBuilder: (context, state) => RouteTransitions.slideFromBottom(
            const CreateStatusScreen(),
            state,
          ),
        ),

        GoRoute(
          path: '${RouteNames.viewStatus}/:${RouteNames.statusIdParam}',
          pageBuilder: (context, state) => RouteTransitions.fadeInWithScale(
            ViewStatusScreen(
              statusId: state.pathParameters[RouteNames.statusIdParam]!,
            ),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.statusPrivacy,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const StatusPrivacyScreen(),
            state,
          ),
        ),

        // ======================================================================
        // ARCHIVED & SPECIAL CHATS ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.archivedChats,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const ArchivedChatsScreen(),
            state,
          ),
        ),

        GoRoute(
          path: RouteNames.pinnedChats,
          pageBuilder: (context, state) =>
              RouteTransitions.slideFromRight(const PinnedChatsScreen(), state),
        ),

        GoRoute(
          path: RouteNames.blockedContacts,
          pageBuilder: (context, state) => RouteTransitions.slideFromRight(
            const BlockedContactsScreen(),
            state,
          ),
        ),

        // ======================================================================
        // ERROR & FALLBACK ROUTES
        // ======================================================================
        GoRoute(
          path: RouteNames.noInternet,
          pageBuilder: (context, state) =>
              RouteTransitions.fadeIn(const NoInternetScreen(), state),
        ),

        GoRoute(
          path: RouteNames.maintenance,
          pageBuilder: (context, state) =>
              RouteTransitions.fadeIn(const MaintenanceScreen(), state),
        ),
      ],
    );
  }

  /// Handle redirect logic for authentication and other guards
  static String? _handleRedirect(WidgetRef ref, GoRouterState state) {
    final authState = ref.read(authProvider);
    final connectivityState = ref.read(connectivityProvider);

    // Check for no internet connection
    if (!connectivityState.isConnected &&
        !RouteNames.publicRoutes.contains(state.matchedLocation)) {
      return RouteNames.noInternet;
    }

    return authState.when(
      initial: () => null, // Stay on current route during initialization
      loading: () => null, // Stay on current route while loading
      unauthenticated: () => _handleUnauthenticatedRedirect(state),
      authenticated: (user, _, __) => _handleAuthenticatedRedirect(state, user),
      error: (message) => _handleErrorRedirect(state, message),
    );
  }

  /// Handle redirect when user is not authenticated
  static String? _handleUnauthenticatedRedirect(GoRouterState state) {
    final currentLocation = state.matchedLocation;

    // Allow access to public routes
    if (RouteNames.isPublic(currentLocation)) {
      return null;
    }

    // Redirect to login for protected routes
    return RouteNames.login;
  }

  /// Handle redirect when user is authenticated
  static String? _handleAuthenticatedRedirect(
    GoRouterState state,
    dynamic user,
  ) {
    final currentLocation = state.matchedLocation;

    // Redirect from auth pages to home if already authenticated
    if (RouteNames.publicRoutes.contains(currentLocation) &&
        currentLocation != RouteNames.splash) {
      return RouteNames.chatList;
    }

    // Check if user profile is complete
    if (_isProfileIncomplete(user) &&
        currentLocation != RouteNames.editProfile) {
      return RouteNames.editProfile;
    }

    return null;
  }

  /// Handle redirect on authentication error
  static String? _handleErrorRedirect(GoRouterState state, String message) {
    // You might want to show an error dialog or redirect to login
    if (!RouteNames.isPublic(state.matchedLocation)) {
      return RouteNames.login;
    }

    return null;
  }

  /// Check if user profile is incomplete
  static bool _isProfileIncomplete(dynamic user) {
    // Add your logic to check if user profile needs to be completed
    // For example, check if name, avatar, or other required fields are missing
    return false;
  }

  /// Get the router refresh listenable
  static Listenable getRefreshListenable(WidgetRef ref) {
    return RouterRefreshStream([
      ref.read(authProvider.notifier).stream,
      ref.read(connectivityProvider.notifier).stream,
    ]);
  }
}

/// Custom refresh stream for GoRouter
class RouterRefreshStream extends ChangeNotifier {
  RouterRefreshStream(List<Stream> streams) {
    for (final stream in streams) {
      stream.listen((_) => notifyListeners());
    }
  }
}
