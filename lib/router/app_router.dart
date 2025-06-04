import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router_config.dart';
import 'route_names.dart';

/// Main router class for the BRO Chat application
///
/// This class provides a centralized way to access the router and navigation
/// methods throughout the application. It also includes utility methods for
/// common navigation patterns.
class AppRouter {
  // Prevent instantiation
  AppRouter._();

  /// Global router instance
  static late final GoRouter _router;

  /// Initialize the router
  static void initialize(WidgetRef ref) {
    _router = RouterConfig.createRouter(ref);
  }

  /// Get the router instance
  static GoRouter get router => _router;

  /// Get the current router delegate
  static GoRouterDelegate get routerDelegate => _router.routerDelegate;

  /// Get the current route information parser
  static GoRouteInformationParser get routeInformationParser =>
      _router.routeInformationParser;

  // ============================================================================
  // NAVIGATION METHODS
  // ============================================================================

  /// Navigate to a route by path
  static void go(String path, {Object? extra}) {
    _router.go(path, extra: extra);
  }

  /// Push a route onto the navigation stack
  static void push(String path, {Object? extra}) {
    _router.push(path, extra: extra);
  }

  /// Replace the current route
  static void replace(String path, {Object? extra}) {
    _router.replace(path, extra: extra);
  }

  /// Pop the current route
  static void pop([Object? result]) {
    _router.pop(result);
  }

  /// Check if we can pop the current route
  static bool canPop() {
    return _router.canPop();
  }

  /// Go back to a specific route by path
  static void goBack() {
    if (canPop()) {
      pop();
    } else {
      go(RouteNames.chatList);
    }
  }

  /// Clear the navigation stack and go to a route
  static void goAndClearStack(String path, {Object? extra}) {
    go(path, extra: extra);
  }

  /// Get current location
  static String get currentLocation =>
      _router.routeInformationProvider.value.uri.path;

  // ============================================================================
  // AUTHENTICATION NAVIGATION
  // ============================================================================

  /// Navigate to splash screen
  static void goToSplash() {
    go(RouteNames.splash);
  }

  /// Navigate to welcome screen
  static void goToWelcome() {
    go(RouteNames.welcome);
  }

  /// Navigate to login screen
  static void goToLogin() {
    go(RouteNames.login);
  }

  /// Navigate to register screen
  static void goToRegister() {
    go(RouteNames.register);
  }

  /// Navigate to OTP verification screen
  static void goToOtpVerification({
    required String phoneNumber,
    required String countryCode,
    bool isPasswordReset = false,
  }) {
    go(
      '${RouteNames.otpVerification}?phone=$phoneNumber&country=$countryCode&reset=$isPasswordReset',
    );
  }

  /// Navigate to password reset screen
  static void goToPasswordReset() {
    go(RouteNames.passwordReset);
  }

  /// Navigate to new password screen
  static void goToNewPassword(String token) {
    go('${RouteNames.newPassword}?token=$token');
  }

  /// Navigate to main chat list (home)
  static void goToHome() {
    go(RouteNames.chatList);
  }

  /// Log out and navigate to login
  static void logout() {
    goAndClearStack(RouteNames.login);
  }

  // ============================================================================
  // CHAT NAVIGATION
  // ============================================================================

  /// Navigate to chat screen
  static void goToChat(String chatId) {
    go(RouteNames.chatWithId(chatId));
  }

  /// Push chat screen onto stack
  static void pushChat(String chatId) {
    push(RouteNames.chatWithId(chatId));
  }

  /// Navigate to group chat screen
  static void goToGroupChat(String groupId) {
    go(RouteNames.groupChatWithId(groupId));
  }

  /// Navigate to create chat screen
  static void goToCreateChat() {
    push(RouteNames.createChat);
  }

  /// Navigate to create group screen
  static void goToCreateGroup() {
    push(RouteNames.createGroup);
  }

  /// Navigate to select contacts screen
  static void goToSelectContacts({
    List<String> selectedContacts = const [],
    int? maxSelection,
  }) {
    final path = maxSelection != null
        ? '${RouteNames.selectContacts}?max=$maxSelection'
        : RouteNames.selectContacts;
    push(path, extra: selectedContacts);
  }

  // ============================================================================
  // PROFILE & SETTINGS NAVIGATION
  // ============================================================================

  /// Navigate to user profile screen
  static void goToProfile([String? userId]) {
    if (userId != null) {
      go(RouteNames.profileWithId(userId));
    } else {
      go(RouteNames.profile);
    }
  }

  /// Navigate to edit profile screen
  static void goToEditProfile() {
    push(RouteNames.editProfile);
  }

  /// Navigate to settings screen
  static void goToSettings() {
    push(RouteNames.settings);
  }

  /// Navigate to language settings
  static void goToLanguageSettings() {
    push(RouteNames.languageSettings);
  }

  /// Navigate to theme settings
  static void goToThemeSettings() {
    push(RouteNames.themeSettings);
  }

  /// Navigate to privacy settings
  static void goToPrivacySettings() {
    push(RouteNames.privacySettings);
  }

  /// Navigate to notification settings
  static void goToNotificationSettings() {
    push(RouteNames.notificationSettings);
  }

  /// Navigate to chat settings
  static void goToChatSettings() {
    push(RouteNames.chatSettings);
  }

  /// Navigate to account settings
  static void goToAccountSettings() {
    push(RouteNames.accountSettings);
  }

  /// Navigate to about screen
  static void goToAbout() {
    push(RouteNames.about);
  }

  /// Navigate to help & support screen
  static void goToHelpSupport() {
    push(RouteNames.helpSupport);
  }

  // ============================================================================
  // GROUP NAVIGATION
  // ============================================================================

  /// Navigate to group info screen
  static void goToGroupInfo(String groupId) {
    push(RouteNames.groupInfoWithId(groupId));
  }

  /// Navigate to group settings screen
  static void goToGroupSettings(String groupId) {
    push(RouteNames.groupSettingsWithId(groupId));
  }

  /// Navigate to group members screen
  static void goToGroupMembers(String groupId) {
    push(RouteNames.groupMembersWithId(groupId));
  }

  /// Navigate to add group members screen
  static void goToAddGroupMembers(String groupId) {
    push('${RouteNames.groupMembersWithId(groupId)}/add');
  }

  /// Navigate to group member profile screen
  static void goToGroupMemberProfile(String groupId, String userId) {
    push('${RouteNames.groupMemberProfile}/$groupId/$userId');
  }

  /// Navigate to group admin tools screen
  static void goToGroupAdminTools(String groupId) {
    push('${RouteNames.groupAdminTools}/$groupId');
  }

  /// Navigate to group invite screen
  static void goToGroupInvite(String groupId) {
    push('${RouteNames.groupInvite}/$groupId');
  }

  /// Navigate to join group screen
  static void goToJoinGroup(String inviteCode) {
    push(RouteNames.joinGroupWithCode(inviteCode));
  }

  // ============================================================================
  // CALL NAVIGATION
  // ============================================================================

  /// Navigate to call screen
  static void goToCall(String callId) {
    go(RouteNames.callWithId(callId));
  }

  /// Navigate to incoming call screen
  static void goToIncomingCall(String callId) {
    go('${RouteNames.incomingCall}/$callId');
  }

  /// Navigate to call history screen
  static void goToCallHistory() {
    push(RouteNames.callHistory);
  }

  /// Navigate to call settings screen
  static void goToCallSettings() {
    push(RouteNames.callSettings);
  }

  // ============================================================================
  // MEDIA & FILE NAVIGATION
  // ============================================================================

  /// Navigate to image viewer
  static void goToImageViewer({
    required String imageUrl,
    String? heroTag,
    List<String> images = const [],
    int initialIndex = 0,
  }) {
    var path = '${RouteNames.imageViewer}?url=${Uri.encodeComponent(imageUrl)}';
    if (heroTag != null) {
      path += '&hero=${Uri.encodeComponent(heroTag)}';
    }
    if (initialIndex > 0) {
      path += '&index=$initialIndex';
    }
    push(path, extra: images);
  }

  /// Navigate to video player
  static void goToVideoPlayer({required String videoUrl, String? title}) {
    var path = '${RouteNames.videoPlayer}?url=${Uri.encodeComponent(videoUrl)}';
    if (title != null) {
      path += '&title=${Uri.encodeComponent(title)}';
    }
    push(path);
  }

  /// Navigate to document viewer
  static void goToDocumentViewer({required String documentUrl, String? title}) {
    var path =
        '${RouteNames.documentViewer}?url=${Uri.encodeComponent(documentUrl)}';
    if (title != null) {
      path += '&title=${Uri.encodeComponent(title)}';
    }
    push(path);
  }

  /// Navigate to media gallery
  static void goToMediaGallery({String? chatId, String? type}) {
    var path = RouteNames.mediaGallery;
    final params = <String>[];
    if (chatId != null) params.add('chatId=$chatId');
    if (type != null) params.add('type=$type');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    push(path);
  }

  /// Navigate to file manager
  static void goToFileManager() {
    push(RouteNames.fileManager);
  }

  /// Navigate to camera screen
  static void goToCamera({String mode = 'photo'}) {
    push('${RouteNames.camera}?mode=$mode');
  }

  /// Navigate to image editor
  static void goToImageEditor(String imagePath) {
    push('${RouteNames.imageEditor}?path=${Uri.encodeComponent(imagePath)}');
  }

  // ============================================================================
  // SEARCH NAVIGATION
  // ============================================================================

  /// Navigate to search screen
  static void goToSearch([String? query]) {
    if (query != null) {
      push(RouteNames.searchWithQuery(query));
    } else {
      push(RouteNames.search);
    }
  }

  /// Navigate to search messages screen
  static void goToSearchMessages({String? chatId, String? query}) {
    var path = RouteNames.searchMessages;
    final params = <String>[];
    if (chatId != null) params.add('chatId=$chatId');
    if (query != null) params.add('q=${Uri.encodeComponent(query)}');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    push(path);
  }

  /// Navigate to search contacts screen
  static void goToSearchContacts() {
    push(RouteNames.searchContacts);
  }

  /// Navigate to search groups screen
  static void goToSearchGroups() {
    push(RouteNames.searchGroups);
  }

  /// Navigate to discover groups screen
  static void goToDiscoverGroups() {
    push(RouteNames.discoverGroups);
  }

  // ============================================================================
  // UTILITY NAVIGATION
  // ============================================================================

  /// Navigate to QR scanner
  static void goToQrScanner() {
    push(RouteNames.qrScanner);
  }

  /// Navigate to QR generator
  static void goToQrGenerator({required String data, String? title}) {
    var path = '${RouteNames.qrGenerator}?data=${Uri.encodeComponent(data)}';
    if (title != null) {
      path += '&title=${Uri.encodeComponent(title)}';
    }
    push(path);
  }

  /// Navigate to location picker
  static void goToLocationPicker() {
    push(RouteNames.locationPicker);
  }

  /// Navigate to contact picker
  static void goToContactPicker() {
    push(RouteNames.contactPicker);
  }

  // ============================================================================
  // STATUS NAVIGATION
  // ============================================================================

  /// Navigate to status screen
  static void goToStatus() {
    push(RouteNames.status);
  }

  /// Navigate to create status screen
  static void goToCreateStatus() {
    push(RouteNames.createStatus);
  }

  /// Navigate to view status screen
  static void goToViewStatus(String statusId) {
    push('${RouteNames.viewStatus}/$statusId');
  }

  /// Navigate to status privacy screen
  static void goToStatusPrivacy() {
    push(RouteNames.statusPrivacy);
  }

  // ============================================================================
  // ARCHIVED & SPECIAL CHATS NAVIGATION
  // ============================================================================

  /// Navigate to archived chats
  static void goToArchivedChats() {
    push(RouteNames.archivedChats);
  }

  /// Navigate to pinned chats
  static void goToPinnedChats() {
    push(RouteNames.pinnedChats);
  }

  /// Navigate to blocked contacts
  static void goToBlockedContacts() {
    push(RouteNames.blockedContacts);
  }

  // ============================================================================
  // ERROR & SPECIAL NAVIGATION
  // ============================================================================

  /// Navigate to error screen
  static void goToError([String? error]) {
    go(
      '${RouteNames.error}${error != null ? '?message=${Uri.encodeComponent(error)}' : ''}',
    );
  }

  /// Navigate to no internet screen
  static void goToNoInternet() {
    go(RouteNames.noInternet);
  }

  /// Navigate to maintenance screen
  static void goToMaintenance() {
    go(RouteNames.maintenance);
  }

  // ============================================================================
  // DIALOG & MODAL HELPERS
  // ============================================================================

  /// Show a dialog with custom content
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      builder: (context) => child,
    );
  }

  /// Show a bottom sheet with custom content
  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      builder: (context) => child,
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if current route matches given route
  static bool isCurrentRoute(String route) {
    return currentLocation == route;
  }

  /// Check if current route contains given string
  static bool currentRouteContains(String substring) {
    return currentLocation.contains(substring);
  }

  /// Get route parameters from current location
  static Map<String, String> getCurrentRouteParams() {
    return _router.routeInformationProvider.value.uri.queryParameters;
  }

  /// Get current route path parameters
  static Map<String, String> getCurrentPathParams() {
    // This would need to be implemented based on current route matching
    // For now, return empty map
    return {};
  }

  /// Clear and rebuild the router (useful for theme changes, etc.)
  static void refresh() {
    // Force router to rebuild
    _router.refresh();
  }
}

/// Provider for the router instance
final routerProvider = Provider<GoRouter>((ref) {
  return RouterConfig.createRouter(ref);
});

/// Provider for listening to router changes
final routerListenableProvider = Provider<Listenable>((ref) {
  return RouterConfig.getRefreshListenable(ref);
});
