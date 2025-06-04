class ApiConstants {
  // Base API path
  static const String apiVersion = 'v1';
  static const String basePath = '/api/$apiVersion';

  // Authentication Endpoints
  static const String auth = '/auth';
  static const String authRegister = '$auth/register';
  static const String authVerifyOTP = '$auth/verify-otp';
  static const String authLogin = '$auth/login';
  static const String authRefresh = '$auth/refresh';
  static const String authResendOTP = '$auth/resend-otp';
  static const String authProfile = '$auth/profile';
  static const String authChangePassword = '$auth/change-password';
  static const String authLogout = '$auth/logout';
  static const String authValidate = '$auth/validate';
  static const String authDevices = '$auth/devices';

  // Chat Endpoints
  static const String chats = '/chats';
  static const String createChat = chats;
  static const String getUserChats = chats;
  static const String getChatStats = '$chats/stats';

  // Dynamic chat endpoints (require chatId parameter)
  static String getChat(String chatId) => '$chats/$chatId';
  static String updateChat(String chatId) => '$chats/$chatId';
  static String deleteChat(String chatId) => '$chats/$chatId';
  static String addParticipant(String chatId) => '$chats/$chatId/participants';
  static String removeParticipant(String chatId, String userId) =>
      '$chats/$chatId/participants/$userId';
  static String archiveChat(String chatId) => '$chats/$chatId/archive';
  static String muteChat(String chatId) => '$chats/$chatId/mute';
  static String pinChat(String chatId) => '$chats/$chatId/pin';
  static String markChatAsRead(String chatId) => '$chats/$chatId/read';
  static String setChatDraft(String chatId) => '$chats/$chatId/draft';
  static String getChatDraft(String chatId) => '$chats/$chatId/draft';
  static String clearChatDraft(String chatId) => '$chats/$chatId/draft';

  // Message Endpoints
  static const String messages = '/messages';
  static const String sendMessage = messages;
  static const String getMessages = messages;
  static const String searchMessages = '$messages/search';
  static const String markMultipleAsRead = '$messages/read';
  static const String bulkDeleteMessages = '$messages/bulk';
  static const String getMessageStats = '$messages/stats';

  // Dynamic message endpoints (require messageId parameter)
  static String getMessage(String messageId) => '$messages/$messageId';
  static String updateMessage(String messageId) => '$messages/$messageId';
  static String deleteMessage(String messageId) => '$messages/$messageId';
  static String addReaction(String messageId) =>
      '$messages/$messageId/reactions';
  static String removeReaction(String messageId) =>
      '$messages/$messageId/reactions';
  static String markMessageAsRead(String messageId) =>
      '$messages/$messageId/read';
  static String forwardMessage(String messageId) =>
      '$messages/$messageId/forward';

  // Group Endpoints
  static const String groups = '/groups';
  static const String createGroup = groups;
  static const String searchGroups = '$groups/search';
  static const String getPublicGroups = '$groups/public';
  static const String getMyGroups = '$groups/my';

  // Dynamic group endpoints (require groupId parameter)
  static String getGroup(String groupId) => '$groups/$groupId';
  static String updateGroup(String groupId) => '$groups/$groupId';
  static String deleteGroup(String groupId) => '$groups/$groupId';
  static String getGroupMembers(String groupId) => '$groups/$groupId/members';
  static String addGroupMember(String groupId) => '$groups/$groupId/members';
  static String updateMemberRole(String groupId, String userId) =>
      '$groups/$groupId/members/$userId';
  static String removeGroupMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId';
  static String leaveGroup(String groupId) => '$groups/$groupId/leave';
  static String getGroupStats(String groupId) => '$groups/$groupId/stats';
  static String getGroupSettings(String groupId) => '$groups/$groupId/settings';
  static String updateGroupSettings(String groupId) =>
      '$groups/$groupId/settings';

  // Group member management
  static String muteMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/mute';
  static String unmuteMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/mute';
  static String warnMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/warn';
  static String banMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/ban';
  static String unbanMember(String groupId, String userId) =>
      '$groups/$groupId/members/$userId/ban';

  // Group join requests
  static String getJoinRequests(String groupId) => '$groups/$groupId/requests';
  static String requestToJoin(String groupId) => '$groups/$groupId/join';
  static String approveJoinRequest(String groupId, String userId) =>
      '$groups/$groupId/requests/$userId/approve';
  static String rejectJoinRequest(String groupId, String userId) =>
      '$groups/$groupId/requests/$userId/reject';

  // Group invitations
  static String inviteUsers(String groupId) => '$groups/$groupId/invite';
  static String getPendingInvites(String groupId) => '$groups/$groupId/invites';
  static String acceptInvite(String inviteId) =>
      '$groups/invites/$inviteId/accept';
  static String declineInvite(String inviteId) =>
      '$groups/invites/$inviteId/decline';
  static String generateInviteLink(String groupId) =>
      '$groups/$groupId/invite-link';
  static String joinByInviteCode(String inviteCode) =>
      '$groups/join/$inviteCode';

  // Group content
  static String getAnnouncements(String groupId) =>
      '$groups/$groupId/announcements';
  static String createAnnouncement(String groupId) =>
      '$groups/$groupId/announcements';
  static String updateAnnouncement(String groupId, String announcementId) =>
      '$groups/$groupId/announcements/$announcementId';
  static String deleteAnnouncement(String groupId, String announcementId) =>
      '$groups/$groupId/announcements/$announcementId';

  static String getGroupRules(String groupId) => '$groups/$groupId/rules';
  static String createGroupRule(String groupId) => '$groups/$groupId/rules';
  static String updateGroupRule(String groupId, String ruleId) =>
      '$groups/$groupId/rules/$ruleId';
  static String deleteGroupRule(String groupId, String ruleId) =>
      '$groups/$groupId/rules/$ruleId';

  static String getGroupEvents(String groupId) => '$groups/$groupId/events';
  static String createGroupEvent(String groupId) => '$groups/$groupId/events';
  static String updateGroupEvent(String groupId, String eventId) =>
      '$groups/$groupId/events/$eventId';
  static String deleteGroupEvent(String groupId, String eventId) =>
      '$groups/$groupId/events/$eventId';
  static String attendEvent(String groupId, String eventId) =>
      '$groups/$groupId/events/$eventId/attend';

  // Call Endpoints
  static const String calls = '/calls';
  static const String initiateCall = '$calls/initiate';
  static const String getCallHistory = '$calls/history';
  static const String getCallStats = '$calls/stats';

  // Dynamic call endpoints (require callId parameter)
  static String answerCall(String callId) => '$calls/$callId/answer';
  static String endCall(String callId) => '$calls/$callId/end';
  static String joinCall(String callId) => '$calls/$callId/join';
  static String leaveCall(String callId) => '$calls/$callId/leave';
  static String getCall(String callId) => '$calls/$callId';
  static String updateMediaState(String callId) => '$calls/$callId/media';
  static String updateQualityMetrics(String callId) => '$calls/$callId/quality';

  // Call recording
  static String startRecording(String callId) =>
      '$calls/$callId/recording/start';
  static String stopRecording(String callId) => '$calls/$callId/recording/stop';

  // WebRTC endpoints
  static const String webrtc = '/webrtc';
  static const String getTurnServers = '$webrtc/turn-servers';

  // File Endpoints
  static const String files = '/files';
  static const String uploadFile = '$files/upload';
  static const String getUserFiles = files;
  static const String searchFiles = '$files/search';
  static const String getFileStats = '$files/stats';

  // Dynamic file endpoints (require fileId parameter)
  static String downloadFile(String fileId) => '$files/$fileId';
  static String getFileDownload(String fileId) => '$files/$fileId/download';
  static String getFileInfo(String fileId) => '$files/$fileId/info';
  static String getFileThumbnail(String fileId) => '$files/$fileId/thumbnail';
  static String deleteFile(String fileId) => '$files/$fileId';

  // Chat files
  static String getChatFiles(String chatId) => '$files/chat/$chatId';

  // Admin Endpoints (for future use)
  static const String admin = '/admin';
  static const String adminDashboard = '$admin/dashboard';
  static const String adminAnalytics = '$admin/analytics';
  static const String adminStats = '$admin/stats';
  static const String adminUsers = '$admin/users';
  static const String adminModeration = '$admin/moderation';
  static const String adminSystem = '$admin/system';
  static const String adminFiles = '$admin/files';
  static const String adminCalls = '$admin/calls';
  static const String adminSecurity = '$admin/security';

  // WebSocket Events (for reference)
  static const String wsConnect = '/ws';

  // Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusConflict = 409;
  static const int statusUnprocessableEntity = 422;
  static const int statusTooManyRequests = 429;
  static const int statusInternalServerError = 500;
  static const int statusServiceUnavailable = 503;

  // HTTP Methods
  static const String methodGet = 'GET';
  static const String methodPost = 'POST';
  static const String methodPut = 'PUT';
  static const String methodDelete = 'DELETE';
  static const String methodPatch = 'PATCH';

  // Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
  static const String contentTypeUrlEncoded =
      'application/x-www-form-urlencoded';

  // File Upload Purposes
  static const String purposeMessage = 'message';
  static const String purposeAvatar = 'avatar';
  static const String purposeGroupAvatar = 'group_avatar';
  static const String purposeDocument = 'document';
  static const String purposeVoiceNote = 'voice_note';
  static const String purposeStatus = 'status';

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVideo = 'video';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeDocument = 'document';
  static const String messageTypeVoiceNote = 'voice_note';
  static const String messageTypeLocation = 'location';
  static const String messageTypeContact = 'contact';
  static const String messageTypeSticker = 'sticker';
  static const String messageTypeGIF = 'gif';
  static const String messageTypeGroupCreated = 'group_created';
  static const String messageTypeGroupDeleted = 'group_deleted';
  static const String messageTypeMemberAdded = 'member_added';
  static const String messageTypeMemberRemoved = 'member_removed';
  static const String messageTypeCallStarted = 'call_started';
  static const String messageTypeCallEnded = 'call_ended';

  // Chat Types
  static const String chatTypePrivate = 'private';
  static const String chatTypeGroup = 'group';
  static const String chatTypeBroadcast = 'broadcast';
  static const String chatTypeBot = 'bot';
  static const String chatTypeSupport = 'support';

  // Call Types
  static const String callTypeVoice = 'voice';
  static const String callTypeVideo = 'video';
  static const String callTypeGroup = 'group';
  static const String callTypeConference = 'conference';

  // Group Roles
  static const String groupRoleOwner = 'owner';
  static const String groupRoleAdmin = 'admin';
  static const String groupRoleModerator = 'moderator';
  static const String groupRoleMember = 'member';

  // User Roles
  static const String userRoleUser = 'user';
  static const String userRoleModerator = 'moderator';
  static const String userRoleAdmin = 'admin';
  static const String userRoleSuper = 'super';

  // End Reasons
  static const String endReasonNormal = 'normal';
  static const String endReasonBusy = 'busy';
  static const String endReasonDeclined = 'declined';
  static const String endReasonTimeout = 'timeout';
  static const String endReasonNetworkError = 'network_error';
  static const String endReasonServerError = 'server_error';

  // Thumbnail Sizes
  static const String thumbnailSizeSmall = 'small';
  static const String thumbnailSizeMedium = 'medium';
  static const String thumbnailSizeLarge = 'large';

  // Query Parameters
  static const String paramPage = 'page';
  static const String paramLimit = 'limit';
  static const String paramSearch = 'q';
  static const String paramType = 'type';
  static const String paramStatus = 'status';
  static const String paramChatId = 'chat_id';
  static const String paramSenderId = 'sender_id';
  static const String paramBefore = 'before';
  static const String paramAfter = 'after';
  static const String paramDateFrom = 'date_from';
  static const String paramDateTo = 'date_to';
  static const String paramForEveryone = 'for_everyone';
  static const String paramArchive = 'archive';
  static const String paramPin = 'pin';
  static const String paramMute = 'mute';
  static const String paramPurpose = 'purpose';
  static const String paramPublic = 'public';
  static const String paramSize = 'size';

  // Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerUserAgent = 'User-Agent';
  static const String headerAppVersion = 'X-App-Version';
  static const String headerPlatform = 'X-Platform';
  static const String headerOSVersion = 'X-OS-Version';
  static const String headerDeviceId = 'X-Device-ID';

  // Error Codes
  static const String errorCodeRequired = 'required';
  static const String errorCodeInvalidFormat = 'invalid_format';
  static const String errorCodeTooLong = 'too_long';
  static const String errorCodeTooShort = 'too_short';
  static const String errorCodeTooLarge = 'too_large';
  static const String errorCodeTooSmall = 'too_small';
  static const String errorCodeInvalidObjectId = 'invalid_object_id';
  static const String errorCodeInvalidDate = 'invalid_date';
  static const String errorCodeOutOfRange = 'out_of_range';
  static const String errorCodePasswordTooWeak = 'password_too_weak';
  static const String errorCodeFileTooBig = 'file_too_big';
  static const String errorCodeQuotaExceeded = 'quota_exceeded';

  // Response Fields
  static const String fieldSuccess = 'success';
  static const String fieldMessage = 'message';
  static const String fieldData = 'data';
  static const String fieldError = 'error';
  static const String fieldCode = 'code';
  static const String fieldMeta = 'meta';
  static const String fieldPage = 'page';
  static const String fieldLimit = 'limit';
  static const String fieldTotal = 'total';
  static const String fieldTotalPages = 'total_pages';
  static const String fieldHasNext = 'has_next';
  static const String fieldHasPrev = 'has_prev';
}
