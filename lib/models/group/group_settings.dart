import 'group_member.dart';

class GroupSettings {
  final bool allowMemberInvites;
  final bool requireApprovalToJoin;
  final bool allowMembershipRequests;
  final bool showMemberList;
  final bool allowMentionAll;
  final bool muteNewMembers;
  final Duration? newMemberMuteDuration;
  final int maxWarningsBeforeBan;
  final bool autoDeleteExpiredInvites;
  final Duration inviteCodeValidDuration;
  final int maxInviteUses;
  final bool enableReadReceipts;
  final bool enableTypingIndicators;
  final bool allowMediaSharing;
  final bool allowFileSharing;
  final bool allowVoiceMessages;
  final bool allowLocationSharing;
  final bool allowPolls;
  final List<String> restrictedFileTypes;
  final int maxFileSize;

  GroupSettings({
    this.allowMemberInvites = true,
    this.requireApprovalToJoin = false,
    this.allowMembershipRequests = true,
    this.showMemberList = true,
    this.allowMentionAll = true,
    this.muteNewMembers = false,
    this.newMemberMuteDuration,
    this.maxWarningsBeforeBan = 3,
    this.autoDeleteExpiredInvites = true,
    this.inviteCodeValidDuration = const Duration(days: 7),
    this.maxInviteUses = 100,
    this.enableReadReceipts = true,
    this.enableTypingIndicators = true,
    this.allowMediaSharing = true,
    this.allowFileSharing = true,
    this.allowVoiceMessages = true,
    this.allowLocationSharing = true,
    this.allowPolls = true,
    this.restrictedFileTypes = const [],
    this.maxFileSize = 50 * 1024 * 1024, // 50MB
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      allowMemberInvites: json['allow_member_invites'] ?? true,
      requireApprovalToJoin: json['require_approval_to_join'] ?? false,
      allowMembershipRequests: json['allow_membership_requests'] ?? true,
      showMemberList: json['show_member_list'] ?? true,
      allowMentionAll: json['allow_mention_all'] ?? true,
      muteNewMembers: json['mute_new_members'] ?? false,
      newMemberMuteDuration: json['new_member_mute_duration'] != null
          ? Duration(seconds: json['new_member_mute_duration'])
          : null,
      maxWarningsBeforeBan: json['max_warnings_before_ban'] ?? 3,
      autoDeleteExpiredInvites: json['auto_delete_expired_invites'] ?? true,
      inviteCodeValidDuration: Duration(
        seconds: json['invite_code_valid_duration'] ?? 604800, // 7 days
      ),
      maxInviteUses: json['max_invite_uses'] ?? 100,
      enableReadReceipts: json['enable_read_receipts'] ?? true,
      enableTypingIndicators: json['enable_typing_indicators'] ?? true,
      allowMediaSharing: json['allow_media_sharing'] ?? true,
      allowFileSharing: json['allow_file_sharing'] ?? true,
      allowVoiceMessages: json['allow_voice_messages'] ?? true,
      allowLocationSharing: json['allow_location_sharing'] ?? true,
      allowPolls: json['allow_polls'] ?? true,
      restrictedFileTypes: List<String>.from(
        json['restricted_file_types'] ?? [],
      ),
      maxFileSize: json['max_file_size'] ?? 50 * 1024 * 1024,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_member_invites': allowMemberInvites,
      'require_approval_to_join': requireApprovalToJoin,
      'allow_membership_requests': allowMembershipRequests,
      'show_member_list': showMemberList,
      'allow_mention_all': allowMentionAll,
      'mute_new_members': muteNewMembers,
      if (newMemberMuteDuration != null)
        'new_member_mute_duration': newMemberMuteDuration!.inSeconds,
      'max_warnings_before_ban': maxWarningsBeforeBan,
      'auto_delete_expired_invites': autoDeleteExpiredInvites,
      'invite_code_valid_duration': inviteCodeValidDuration.inSeconds,
      'max_invite_uses': maxInviteUses,
      'enable_read_receipts': enableReadReceipts,
      'enable_typing_indicators': enableTypingIndicators,
      'allow_media_sharing': allowMediaSharing,
      'allow_file_sharing': allowFileSharing,
      'allow_voice_messages': allowVoiceMessages,
      'allow_location_sharing': allowLocationSharing,
      'allow_polls': allowPolls,
      'restricted_file_types': restrictedFileTypes,
      'max_file_size': maxFileSize,
    };
  }
}

class GroupPermissions {
  final GroupRole whoCanSendMessages;
  final GroupRole whoCanEditGroupInfo;
  final GroupRole whoCanAddMembers;
  final GroupRole whoCanRemoveMembers;
  final GroupRole whoCanMuteMembers;
  final GroupRole whoCanBanMembers;
  final GroupRole whoCanCreatePolls;
  final GroupRole whoCanPinMessages;
  final GroupRole whoCanDeleteMessages;

  GroupPermissions({
    this.whoCanSendMessages = GroupRole.member,
    this.whoCanEditGroupInfo = GroupRole.admin,
    this.whoCanAddMembers = GroupRole.admin,
    this.whoCanRemoveMembers = GroupRole.admin,
    this.whoCanMuteMembers = GroupRole.moderator,
    this.whoCanBanMembers = GroupRole.admin,
    this.whoCanCreatePolls = GroupRole.member,
    this.whoCanPinMessages = GroupRole.moderator,
    this.whoCanDeleteMessages = GroupRole.moderator,
  });

  factory GroupPermissions.fromJson(Map<String, dynamic> json) {
    return GroupPermissions(
      whoCanSendMessages: GroupRole.fromString(json['who_can_send_messages']),
      whoCanEditGroupInfo: GroupRole.fromString(
        json['who_can_edit_group_info'],
      ),
      whoCanAddMembers: GroupRole.fromString(json['who_can_add_members']),
      whoCanRemoveMembers: GroupRole.fromString(json['who_can_remove_members']),
      whoCanMuteMembers: GroupRole.fromString(json['who_can_mute_members']),
      whoCanBanMembers: GroupRole.fromString(json['who_can_ban_members']),
      whoCanCreatePolls: GroupRole.fromString(json['who_can_create_polls']),
      whoCanPinMessages: GroupRole.fromString(json['who_can_pin_messages']),
      whoCanDeleteMessages: GroupRole.fromString(
        json['who_can_delete_messages'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'who_can_send_messages': whoCanSendMessages.value,
      'who_can_edit_group_info': whoCanEditGroupInfo.value,
      'who_can_add_members': whoCanAddMembers.value,
      'who_can_remove_members': whoCanRemoveMembers.value,
      'who_can_mute_members': whoCanMuteMembers.value,
      'who_can_ban_members': whoCanBanMembers.value,
      'who_can_create_polls': whoCanCreatePolls.value,
      'who_can_pin_messages': whoCanPinMessages.value,
      'who_can_delete_messages': whoCanDeleteMessages.value,
    };
  }

  bool canPerformAction(GroupRole userRole, GroupRole requiredRole) {
    final roleHierarchy = {
      GroupRole.member: 0,
      GroupRole.moderator: 1,
      GroupRole.admin: 2,
      GroupRole.owner: 3,
    };

    return (roleHierarchy[userRole] ?? 0) >= (roleHierarchy[requiredRole] ?? 0);
  }
}
