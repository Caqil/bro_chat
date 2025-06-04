/// Route names for the BRO Chat application
/// 
/// This file contains all the route names used throughout the app.
/// Use these constants instead of hardcoded strings for better maintainability.
class RouteNames {
  // Prevent instantiation
  RouteNames._();

  // ============================================================================
  // AUTHENTICATION ROUTES
  // ============================================================================
  
  /// Splash screen route
  static const String splash = '/splash';
  
  /// Welcome/onboarding screen route
  static const String welcome = '/welcome';
  
  /// Login screen route
  static const String login = '/login';
  
  /// Register screen route
  static const String register = '/register';
  
  /// OTP verification screen route
  static const String otpVerification = '/otp-verification';
  
  /// Password reset screen route
  static const String passwordReset = '/password-reset';
  
  /// Reset password OTP verification route
  static const String resetPasswordOtp = '/reset-password-otp';
  
  /// New password setup route
  static const String newPassword = '/new-password';

  // ============================================================================
  // MAIN APP ROUTES
  // ============================================================================
  
  /// Main chat list screen (home) route
  static const String chatList = '/';
  
  /// Individual chat screen route
  static const String chat = '/chat';
  
  /// Group chat screen route (same as chat but for groups)
  static const String groupChat = '/group-chat';
  
  /// Create new chat screen route
  static const String createChat = '/create-chat';
  
  /// Create new group screen route
  static const String createGroup = '/create-group';
  
  /// Contact selection screen route
  static const String selectContacts = '/select-contacts';

  // ============================================================================
  // PROFILE & SETTINGS ROUTES
  // ============================================================================
  
  /// User profile screen route
  static const String profile = '/profile';
  
  /// Edit profile screen route
  static const String editProfile = '/edit-profile';
  
  /// Settings main screen route
  static const String settings = '/settings';
  
  /// Language settings screen route
  static const String languageSettings = '/settings/language';
  
  /// Theme settings screen route
  static const String themeSettings = '/settings/theme';
  
  /// Privacy settings screen route
  static const String privacySettings = '/settings/privacy';
  
  /// Notification settings screen route
  static const String notificationSettings = '/settings/notifications';
  
  /// Chat settings screen route
  static const String chatSettings = '/settings/chat';
  
  /// Account settings screen route
  static const String accountSettings = '/settings/account';
  
  /// About screen route
  static const String about = '/settings/about';
  
  /// Help & Support screen route
  static const String helpSupport = '/settings/help';

  // ============================================================================
  // GROUP MANAGEMENT ROUTES
  // ============================================================================
  
  /// Group details/info screen route
  static const String groupInfo = '/group-info';
  
  /// Group settings screen route
  static const String groupSettings = '/group-settings';
  
  /// Group members screen route
  static const String groupMembers = '/group-members';
  
  /// Add group members screen route
  static const String addGroupMembers = '/group-members/add';
  
  /// Group member profile screen route
  static const String groupMemberProfile = '/group-member-profile';
  
  /// Group admin tools screen route
  static const String groupAdminTools = '/group-admin-tools';
  
  /// Group invite screen route
  static const String groupInvite = '/group-invite';
  
  /// Join group by invite route
  static const String joinGroup = '/join-group';

  // ============================================================================
  // CALL ROUTES
  // ============================================================================
  
  /// Active call screen route
  static const String call = '/call';
  
  /// Incoming call screen route
  static const String incomingCall = '/incoming-call';
  
  /// Call history screen route
  static const String callHistory = '/call-history';
  
  /// Call settings screen route
  static const String callSettings = '/call-settings';

  // ============================================================================
  // MEDIA & FILE ROUTES
  // ============================================================================
  
  /// Image viewer screen route
  static const String imageViewer = '/image-viewer';
  
  /// Video player screen route
  static const String videoPlayer = '/video-player';
  
  /// Document viewer screen route
  static const String documentViewer = '/document-viewer';
  
  /// Media gallery screen route
  static const String mediaGallery = '/media-gallery';
  
  /// File manager screen route
  static const String fileManager = '/file-manager';
  
  /// Camera screen route
  static const String camera = '/camera';
  
  /// Image editor screen route
  static const String imageEditor = '/image-editor';

  // ============================================================================
  // SEARCH & DISCOVERY ROUTES
  // ============================================================================
  
  /// Global search screen route
  static const String search = '/search';
  
  /// Search messages screen route
  static const String searchMessages = '/search-messages';
  
  /// Search contacts screen route
  static const String searchContacts = '/search-contacts';
  
  /// Search groups screen route
  static const String searchGroups = '/search-groups';
  
  /// Discover public groups screen route
  static const String discoverGroups = '/discover-groups';

  // ============================================================================
  // UTILITY ROUTES
  // ============================================================================
  
  /// QR code scanner screen route
  static const String qrScanner = '/qr-scanner';
  
  /// QR code generator screen route
  static const String qrGenerator = '/qr-generator';
  
  /// Location picker screen route
  static const String locationPicker = '/location-picker';
  
  /// Contact picker screen route
  static const String contactPicker = '/contact-picker';
  
  /// Emoji picker screen route (if needed as separate screen)
  static const String emojiPicker = '/emoji-picker';

  // ============================================================================
  // STATUS & STORIES ROUTES (if implementing stories feature)
  // ============================================================================
  
  /// Status/Stories main screen route
  static const String status = '/status';
  
  /// Create status screen route
  static const String createStatus = '/create-status';
  
  /// View status screen route
  static const String viewStatus = '/view-status';
  
  /// Status privacy settings route
  static const String statusPrivacy = '/status-privacy';

  // ============================================================================
  // ARCHIVED & SPECIAL CHATS ROUTES
  // ============================================================================
  
  /// Archived chats screen route
  static const String archivedChats = '/archived-chats';
  
  /// Pinned chats screen route
  static const String pinnedChats = '/pinned-chats';
  
  /// Blocked contacts screen route
  static const String blockedContacts = '/blocked-contacts';

  // ============================================================================
  // ERROR & FALLBACK ROUTES
  // ============================================================================
  
  /// Error screen route
  static const String error = '/error';
  
  /// No internet connection screen route
  static const String noInternet = '/no-internet';
  
  /// Maintenance screen route
  static const String maintenance = '/maintenance';

  // ============================================================================
  // ROUTE PARAMETERS
  // ============================================================================
  
  /// Route parameter names
  static const String chatIdParam = 'chatId';
  static const String groupIdParam = 'groupId';
  static const String userIdParam = 'userId';
  static const String messageIdParam = 'messageId';
  static const String fileIdParam = 'fileId';
  static const String callIdParam = 'callId';
  static const String inviteCodeParam = 'inviteCode';
  static const String imageUrlParam = 'imageUrl';
  static const String videoUrlParam = 'videoUrl';
  static const String documentUrlParam = 'documentUrl';
  static const String indexParam = 'index';
  static const String typeParam = 'type';
  static const String sourceParam = 'source';
  static const String queryParam = 'query';
  static const String statusIdParam = 'statusId';

  // ============================================================================
  // ROUTE HELPERS
  // ============================================================================
  
  /// Generate chat route with chat ID
  static String chatWithId(String chatId) => '$chat/$chatId';
  
  /// Generate group chat route with group ID
  static String groupChatWithId(String groupId) => '$groupChat/$groupId';
  
  /// Generate group info route with group ID
  static String groupInfoWithId(String groupId) => '$groupInfo/$groupId';
  
  /// Generate group settings route with group ID
  static String groupSettingsWithId(String groupId) => '$groupSettings/$groupId';
  
  /// Generate group members route with group ID
  static String groupMembersWithId(String groupId) => '$groupMembers/$groupId';
  
  /// Generate call route with call ID
  static String callWithId(String callId) => '$call/$callId';
  
  /// Generate image viewer route with image URL
  static String imageViewerWithUrl(String imageUrl) => '$imageViewer?url=$imageUrl';
  
  /// Generate video player route with video URL
  static String videoPlayerWithUrl(String videoUrl) => '$videoPlayer?url=$videoUrl';
  
  /// Generate document viewer route with document URL
  static String documentViewerWithUrl(String documentUrl) => '$documentViewer?url=$documentUrl';
  
  /// Generate join group route with invite code
  static String joinGroupWithCode(String inviteCode) => '$joinGroup/$inviteCode';
  
  /// Generate search route with query
  static String searchWithQuery(String query) => '$search?q=$query';
  
  /// Generate user profile route with user ID
  static String profileWithId(String userId) => '$profile/$userId';

  // ============================================================================
  // ROUTE VALIDATION
  // ============================================================================
  
  /// List of all authenticated routes (require login)
  static const List<String> authenticatedRoutes = [
    chatList,
    chat,
    groupChat,
    createChat,
    createGroup,
    profile,
    editProfile,
    settings,
    languageSettings,
    themeSettings,
    privacySettings,
    notificationSettings,
    chatSettings,
    accountSettings,
    groupInfo,
    groupSettings,
    groupMembers,
    addGroupMembers,
    groupMemberProfile,
    groupAdminTools,
    groupInvite,
    call,
    incomingCall,
    callHistory,
    callSettings,
    imageViewer,
    videoPlayer,
    documentViewer,
    mediaGallery,
    fileManager,
    camera,
    imageEditor,
    search,
    searchMessages,
    searchContacts,
    searchGroups,
    discoverGroups,
    qrScanner,
    qrGenerator,
    locationPicker,
    contactPicker,
    status,
    createStatus,
    viewStatus,
    statusPrivacy,
    archivedChats,
    pinnedChats,
    blockedContacts,
  ];
  
  /// List of all public routes (don't require login)
  static const List<String> publicRoutes = [
    splash,
    welcome,
    login,
    register,
    otpVerification,
    passwordReset,
    resetPasswordOtp,
    newPassword,
    joinGroup,
    error,
    noInternet,
    maintenance,
  ];
  
  /// Check if a route requires authentication
  static bool requiresAuth(String route) {
    return authenticatedRoutes.contains(route);
  }
  
  /// Check if a route is public
  static bool isPublic(String route) {
    return publicRoutes.contains(route);
  }
}