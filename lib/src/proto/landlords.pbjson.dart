// This is a generated file - do not edit.
//
// Generated from landlords.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use errorCodeDescriptor instead')
const ErrorCode$json = {
  '1': 'ErrorCode',
  '2': [
    {'1': 'ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'ERROR_CODE_INVALID_REQUEST', '2': 1},
    {'1': 'ERROR_CODE_AUTH_FAILED', '2': 2},
    {'1': 'ERROR_CODE_ALREADY_EXISTS', '2': 3},
    {'1': 'ERROR_CODE_NOT_FOUND', '2': 4},
    {'1': 'ERROR_CODE_MATCH_STATE_INVALID', '2': 5},
    {'1': 'ERROR_CODE_GAME_STATE_INVALID', '2': 6},
    {'1': 'ERROR_CODE_INTERNAL', '2': 7},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode(
    'CglFcnJvckNvZGUSGgoWRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEh4KGkVSUk9SX0NPREVfSU'
    '5WQUxJRF9SRVFVRVNUEAESGgoWRVJST1JfQ09ERV9BVVRIX0ZBSUxFRBACEh0KGUVSUk9SX0NP'
    'REVfQUxSRUFEWV9FWElTVFMQAxIYChRFUlJPUl9DT0RFX05PVF9GT1VORBAEEiIKHkVSUk9SX0'
    'NPREVfTUFUQ0hfU1RBVEVfSU5WQUxJRBAFEiEKHUVSUk9SX0NPREVfR0FNRV9TVEFURV9JTlZB'
    'TElEEAYSFwoTRVJST1JfQ09ERV9JTlRFUk5BTBAH');

@$core.Deprecated('Use matchModeDescriptor instead')
const MatchMode$json = {
  '1': 'MatchMode',
  '2': [
    {'1': 'MATCH_MODE_UNSPECIFIED', '2': 0},
    {'1': 'MATCH_MODE_VS_BOT', '2': 1},
    {'1': 'MATCH_MODE_PVP', '2': 2},
  ],
};

/// Descriptor for `MatchMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List matchModeDescriptor = $convert.base64Decode(
    'CglNYXRjaE1vZGUSGgoWTUFUQ0hfTU9ERV9VTlNQRUNJRklFRBAAEhUKEU1BVENIX01PREVfVl'
    'NfQk9UEAESEgoOTUFUQ0hfTU9ERV9QVlAQAg==');

@$core.Deprecated('Use botDifficultyDescriptor instead')
const BotDifficulty$json = {
  '1': 'BotDifficulty',
  '2': [
    {'1': 'BOT_DIFFICULTY_UNSPECIFIED', '2': 0},
    {'1': 'BOT_DIFFICULTY_EASY', '2': 1},
    {'1': 'BOT_DIFFICULTY_NORMAL', '2': 2},
    {'1': 'BOT_DIFFICULTY_HARD', '2': 3},
  ],
};

/// Descriptor for `BotDifficulty`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List botDifficultyDescriptor = $convert.base64Decode(
    'Cg1Cb3REaWZmaWN1bHR5Eh4KGkJPVF9ESUZGSUNVTFRZX1VOU1BFQ0lGSUVEEAASFwoTQk9UX0'
    'RJRkZJQ1VMVFlfRUFTWRABEhkKFUJPVF9ESUZGSUNVTFRZX05PUk1BTBACEhcKE0JPVF9ESUZG'
    'SUNVTFRZX0hBUkQQAw==');

@$core.Deprecated('Use playerRoleDescriptor instead')
const PlayerRole$json = {
  '1': 'PlayerRole',
  '2': [
    {'1': 'PLAYER_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'PLAYER_ROLE_FARMER', '2': 1},
    {'1': 'PLAYER_ROLE_LANDLORD', '2': 2},
  ],
};

/// Descriptor for `PlayerRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List playerRoleDescriptor = $convert.base64Decode(
    'CgpQbGF5ZXJSb2xlEhsKF1BMQVlFUl9ST0xFX1VOU1BFQ0lGSUVEEAASFgoSUExBWUVSX1JPTE'
    'VfRkFSTUVSEAESGAoUUExBWUVSX1JPTEVfTEFORExPUkQQAg==');

@$core.Deprecated('Use roomPhaseDescriptor instead')
const RoomPhase$json = {
  '1': 'RoomPhase',
  '2': [
    {'1': 'ROOM_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'ROOM_PHASE_PREPARING', '2': 1},
    {'1': 'ROOM_PHASE_WAITING', '2': 2},
    {'1': 'ROOM_PHASE_PLAYING', '2': 3},
    {'1': 'ROOM_PHASE_FINISHED', '2': 4},
  ],
};

/// Descriptor for `RoomPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List roomPhaseDescriptor = $convert.base64Decode(
    'CglSb29tUGhhc2USGgoWUk9PTV9QSEFTRV9VTlNQRUNJRklFRBAAEhgKFFJPT01fUEhBU0VfUF'
    'JFUEFSSU5HEAESFgoSUk9PTV9QSEFTRV9XQUlUSU5HEAISFgoSUk9PTV9QSEFTRV9QTEFZSU5H'
    'EAMSFwoTUk9PTV9QSEFTRV9GSU5JU0hFRBAE');

@$core.Deprecated('Use actionTypeDescriptor instead')
const ActionType$json = {
  '1': 'ActionType',
  '2': [
    {'1': 'ACTION_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'ACTION_TYPE_PLAY', '2': 1},
    {'1': 'ACTION_TYPE_PASS', '2': 2},
  ],
};

/// Descriptor for `ActionType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List actionTypeDescriptor = $convert.base64Decode(
    'CgpBY3Rpb25UeXBlEhsKF0FDVElPTl9UWVBFX1VOU1BFQ0lGSUVEEAASFAoQQUNUSU9OX1RZUE'
    'VfUExBWRABEhQKEEFDVElPTl9UWVBFX1BBU1MQAg==');

@$core.Deprecated('Use patternTypeDescriptor instead')
const PatternType$json = {
  '1': 'PatternType',
  '2': [
    {'1': 'PATTERN_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'PATTERN_TYPE_SINGLE', '2': 1},
    {'1': 'PATTERN_TYPE_PAIR', '2': 2},
    {'1': 'PATTERN_TYPE_TRIPLE', '2': 3},
    {'1': 'PATTERN_TYPE_TRIPLE_WITH_SINGLE', '2': 4},
    {'1': 'PATTERN_TYPE_TRIPLE_WITH_PAIR', '2': 5},
    {'1': 'PATTERN_TYPE_STRAIGHT', '2': 6},
    {'1': 'PATTERN_TYPE_STRAIGHT_PAIR', '2': 7},
    {'1': 'PATTERN_TYPE_AIRPLANE', '2': 8},
    {'1': 'PATTERN_TYPE_AIRPLANE_WITH_SINGLE', '2': 9},
    {'1': 'PATTERN_TYPE_AIRPLANE_WITH_PAIR', '2': 10},
    {'1': 'PATTERN_TYPE_BOMB', '2': 11},
    {'1': 'PATTERN_TYPE_FOUR_WITH_TWO_SINGLES', '2': 12},
    {'1': 'PATTERN_TYPE_FOUR_WITH_TWO_PAIRS', '2': 13},
    {'1': 'PATTERN_TYPE_ROCKET', '2': 14},
  ],
};

/// Descriptor for `PatternType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List patternTypeDescriptor = $convert.base64Decode(
    'CgtQYXR0ZXJuVHlwZRIcChhQQVRURVJOX1RZUEVfVU5TUEVDSUZJRUQQABIXChNQQVRURVJOX1'
    'RZUEVfU0lOR0xFEAESFQoRUEFUVEVSTl9UWVBFX1BBSVIQAhIXChNQQVRURVJOX1RZUEVfVFJJ'
    'UExFEAMSIwofUEFUVEVSTl9UWVBFX1RSSVBMRV9XSVRIX1NJTkdMRRAEEiEKHVBBVFRFUk5fVF'
    'lQRV9UUklQTEVfV0lUSF9QQUlSEAUSGQoVUEFUVEVSTl9UWVBFX1NUUkFJR0hUEAYSHgoaUEFU'
    'VEVSTl9UWVBFX1NUUkFJR0hUX1BBSVIQBxIZChVQQVRURVJOX1RZUEVfQUlSUExBTkUQCBIlCi'
    'FQQVRURVJOX1RZUEVfQUlSUExBTkVfV0lUSF9TSU5HTEUQCRIjCh9QQVRURVJOX1RZUEVfQUlS'
    'UExBTkVfV0lUSF9QQUlSEAoSFQoRUEFUVEVSTl9UWVBFX0JPTUIQCxImCiJQQVRURVJOX1RZUE'
    'VfRk9VUl9XSVRIX1RXT19TSU5HTEVTEAwSJAogUEFUVEVSTl9UWVBFX0ZPVVJfV0lUSF9UV09f'
    'UEFJUlMQDRIXChNQQVRURVJOX1RZUEVfUk9DS0VUEA4=');

@$core.Deprecated('Use invitationResultDescriptor instead')
const InvitationResult$json = {
  '1': 'InvitationResult',
  '2': [
    {'1': 'INVITATION_RESULT_UNSPECIFIED', '2': 0},
    {'1': 'INVITATION_RESULT_ACCEPTED', '2': 1},
    {'1': 'INVITATION_RESULT_REJECTED', '2': 2},
    {'1': 'INVITATION_RESULT_FAILED', '2': 3},
    {'1': 'INVITATION_RESULT_EXPIRED', '2': 4},
  ],
};

/// Descriptor for `InvitationResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List invitationResultDescriptor = $convert.base64Decode(
    'ChBJbnZpdGF0aW9uUmVzdWx0EiEKHUlOVklUQVRJT05fUkVTVUxUX1VOU1BFQ0lGSUVEEAASHg'
    'oaSU5WSVRBVElPTl9SRVNVTFRfQUNDRVBURUQQARIeChpJTlZJVEFUSU9OX1JFU1VMVF9SRUpF'
    'Q1RFRBACEhwKGElOVklUQVRJT05fUkVTVUxUX0ZBSUxFRBADEh0KGUlOVklUQVRJT05fUkVTVU'
    'xUX0VYUElSRUQQBA==');

@$core.Deprecated('Use friendRequestStatusDescriptor instead')
const FriendRequestStatus$json = {
  '1': 'FriendRequestStatus',
  '2': [
    {'1': 'FRIEND_REQUEST_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'FRIEND_REQUEST_STATUS_PENDING', '2': 1},
    {'1': 'FRIEND_REQUEST_STATUS_ACCEPTED', '2': 2},
    {'1': 'FRIEND_REQUEST_STATUS_REJECTED', '2': 3},
  ],
};

/// Descriptor for `FriendRequestStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List friendRequestStatusDescriptor = $convert.base64Decode(
    'ChNGcmllbmRSZXF1ZXN0U3RhdHVzEiUKIUZSSUVORF9SRVFVRVNUX1NUQVRVU19VTlNQRUNJRk'
    'lFRBAAEiEKHUZSSUVORF9SRVFVRVNUX1NUQVRVU19QRU5ESU5HEAESIgoeRlJJRU5EX1JFUVVF'
    'U1RfU1RBVFVTX0FDQ0VQVEVEEAISIgoeRlJJRU5EX1JFUVVFU1RfU1RBVFVTX1JFSkVDVEVEEA'
    'M=');

@$core.Deprecated('Use userProfileDescriptor instead')
const UserProfile$json = {
  '1': 'UserProfile',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'account', '3': 2, '4': 1, '5': 9, '10': 'account'},
    {'1': 'nickname', '3': 3, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'total_score', '3': 4, '4': 1, '5': 5, '10': 'totalScore'},
    {'1': 'landlord_wins', '3': 5, '4': 1, '5': 5, '10': 'landlordWins'},
    {'1': 'landlord_games', '3': 6, '4': 1, '5': 5, '10': 'landlordGames'},
    {'1': 'farmer_wins', '3': 7, '4': 1, '5': 5, '10': 'farmerWins'},
    {'1': 'farmer_games', '3': 8, '4': 1, '5': 5, '10': 'farmerGames'},
    {
      '1': 'online_landlord_wins',
      '3': 9,
      '4': 1,
      '5': 5,
      '10': 'onlineLandlordWins'
    },
    {
      '1': 'online_landlord_games',
      '3': 10,
      '4': 1,
      '5': 5,
      '10': 'onlineLandlordGames'
    },
    {
      '1': 'online_farmer_wins',
      '3': 11,
      '4': 1,
      '5': 5,
      '10': 'onlineFarmerWins'
    },
    {
      '1': 'online_farmer_games',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'onlineFarmerGames'
    },
    {
      '1': 'bot_landlord_wins',
      '3': 13,
      '4': 1,
      '5': 5,
      '10': 'botLandlordWins'
    },
    {
      '1': 'bot_landlord_games',
      '3': 14,
      '4': 1,
      '5': 5,
      '10': 'botLandlordGames'
    },
    {'1': 'bot_farmer_wins', '3': 15, '4': 1, '5': 5, '10': 'botFarmerWins'},
    {'1': 'bot_farmer_games', '3': 16, '4': 1, '5': 5, '10': 'botFarmerGames'},
  ],
};

/// Descriptor for `UserProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userProfileDescriptor = $convert.base64Decode(
    'CgtVc2VyUHJvZmlsZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSGAoHYWNjb3VudBgCIAEoCV'
    'IHYWNjb3VudBIaCghuaWNrbmFtZRgDIAEoCVIIbmlja25hbWUSHwoLdG90YWxfc2NvcmUYBCAB'
    'KAVSCnRvdGFsU2NvcmUSIwoNbGFuZGxvcmRfd2lucxgFIAEoBVIMbGFuZGxvcmRXaW5zEiUKDm'
    'xhbmRsb3JkX2dhbWVzGAYgASgFUg1sYW5kbG9yZEdhbWVzEh8KC2Zhcm1lcl93aW5zGAcgASgF'
    'UgpmYXJtZXJXaW5zEiEKDGZhcm1lcl9nYW1lcxgIIAEoBVILZmFybWVyR2FtZXMSMAoUb25saW'
    '5lX2xhbmRsb3JkX3dpbnMYCSABKAVSEm9ubGluZUxhbmRsb3JkV2lucxIyChVvbmxpbmVfbGFu'
    'ZGxvcmRfZ2FtZXMYCiABKAVSE29ubGluZUxhbmRsb3JkR2FtZXMSLAoSb25saW5lX2Zhcm1lcl'
    '93aW5zGAsgASgFUhBvbmxpbmVGYXJtZXJXaW5zEi4KE29ubGluZV9mYXJtZXJfZ2FtZXMYDCAB'
    'KAVSEW9ubGluZUZhcm1lckdhbWVzEioKEWJvdF9sYW5kbG9yZF93aW5zGA0gASgFUg9ib3RMYW'
    '5kbG9yZFdpbnMSLAoSYm90X2xhbmRsb3JkX2dhbWVzGA4gASgFUhBib3RMYW5kbG9yZEdhbWVz'
    'EiYKD2JvdF9mYXJtZXJfd2lucxgPIAEoBVINYm90RmFybWVyV2lucxIoChBib3RfZmFybWVyX2'
    'dhbWVzGBAgASgFUg5ib3RGYXJtZXJHYW1lcw==');

@$core.Deprecated('Use onlineUserDescriptor instead')
const OnlineUser$json = {
  '1': 'OnlineUser',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'account', '3': 2, '4': 1, '5': 9, '10': 'account'},
    {'1': 'nickname', '3': 3, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'online', '3': 4, '4': 1, '5': 8, '10': 'online'},
  ],
};

/// Descriptor for `OnlineUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List onlineUserDescriptor = $convert.base64Decode(
    'CgpPbmxpbmVVc2VyEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIYCgdhY2NvdW50GAIgASgJUg'
    'dhY2NvdW50EhoKCG5pY2tuYW1lGAMgASgJUghuaWNrbmFtZRIWCgZvbmxpbmUYBCABKAhSBm9u'
    'bGluZQ==');

@$core.Deprecated('Use friendRequestEntryDescriptor instead')
const FriendRequestEntry$json = {
  '1': 'FriendRequestEntry',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'requester_user_id', '3': 2, '4': 1, '5': 9, '10': 'requesterUserId'},
    {
      '1': 'requester_account',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'requesterAccount'
    },
    {
      '1': 'requester_nickname',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'requesterNickname'
    },
    {'1': 'receiver_user_id', '3': 5, '4': 1, '5': 9, '10': 'receiverUserId'},
    {'1': 'receiver_account', '3': 6, '4': 1, '5': 9, '10': 'receiverAccount'},
    {
      '1': 'receiver_nickname',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'receiverNickname'
    },
    {
      '1': 'status',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.FriendRequestStatus',
      '10': 'status'
    },
    {'1': 'created_at_ms', '3': 9, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'updated_at_ms', '3': 10, '4': 1, '5': 3, '10': 'updatedAtMs'},
  ],
};

/// Descriptor for `FriendRequestEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendRequestEntryDescriptor = $convert.base64Decode(
    'ChJGcmllbmRSZXF1ZXN0RW50cnkSHQoKcmVxdWVzdF9pZBgBIAEoCVIJcmVxdWVzdElkEioKEX'
    'JlcXVlc3Rlcl91c2VyX2lkGAIgASgJUg9yZXF1ZXN0ZXJVc2VySWQSKwoRcmVxdWVzdGVyX2Fj'
    'Y291bnQYAyABKAlSEHJlcXVlc3RlckFjY291bnQSLQoScmVxdWVzdGVyX25pY2tuYW1lGAQgAS'
    'gJUhFyZXF1ZXN0ZXJOaWNrbmFtZRIoChByZWNlaXZlcl91c2VyX2lkGAUgASgJUg5yZWNlaXZl'
    'clVzZXJJZBIpChByZWNlaXZlcl9hY2NvdW50GAYgASgJUg9yZWNlaXZlckFjY291bnQSKwoRcm'
    'VjZWl2ZXJfbmlja25hbWUYByABKAlSEHJlY2VpdmVyTmlja25hbWUSPwoGc3RhdHVzGAggASgO'
    'MicubGFuZGxvcmRzLnByb3RvY29sLkZyaWVuZFJlcXVlc3RTdGF0dXNSBnN0YXR1cxIiCg1jcm'
    'VhdGVkX2F0X21zGAkgASgDUgtjcmVhdGVkQXRNcxIiCg11cGRhdGVkX2F0X21zGAogASgDUgt1'
    'cGRhdGVkQXRNcw==');

@$core.Deprecated('Use friendCenterSnapshotDescriptor instead')
const FriendCenterSnapshot$json = {
  '1': 'FriendCenterSnapshot',
  '2': [
    {
      '1': 'friends',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.OnlineUser',
      '10': 'friends'
    },
    {
      '1': 'pending_requests',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.FriendRequestEntry',
      '10': 'pendingRequests'
    },
    {
      '1': 'history_requests',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.FriendRequestEntry',
      '10': 'historyRequests'
    },
    {
      '1': 'pending_request_count',
      '3': 4,
      '4': 1,
      '5': 5,
      '10': 'pendingRequestCount'
    },
  ],
};

/// Descriptor for `FriendCenterSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendCenterSnapshotDescriptor = $convert.base64Decode(
    'ChRGcmllbmRDZW50ZXJTbmFwc2hvdBI4CgdmcmllbmRzGAEgAygLMh4ubGFuZGxvcmRzLnByb3'
    'RvY29sLk9ubGluZVVzZXJSB2ZyaWVuZHMSUQoQcGVuZGluZ19yZXF1ZXN0cxgCIAMoCzImLmxh'
    'bmRsb3Jkcy5wcm90b2NvbC5GcmllbmRSZXF1ZXN0RW50cnlSD3BlbmRpbmdSZXF1ZXN0cxJRCh'
    'BoaXN0b3J5X3JlcXVlc3RzGAMgAygLMiYubGFuZGxvcmRzLnByb3RvY29sLkZyaWVuZFJlcXVl'
    'c3RFbnRyeVIPaGlzdG9yeVJlcXVlc3RzEjIKFXBlbmRpbmdfcmVxdWVzdF9jb3VudBgEIAEoBV'
    'ITcGVuZGluZ1JlcXVlc3RDb3VudA==');

@$core.Deprecated('Use systemStatsSnapshotDescriptor instead')
const SystemStatsSnapshot$json = {
  '1': 'SystemStatsSnapshot',
  '2': [
    {
      '1': 'support_like_count',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'supportLikeCount'
    },
  ],
};

/// Descriptor for `SystemStatsSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemStatsSnapshotDescriptor = $convert.base64Decode(
    'ChNTeXN0ZW1TdGF0c1NuYXBzaG90EiwKEnN1cHBvcnRfbGlrZV9jb3VudBgBIAEoBVIQc3VwcG'
    '9ydExpa2VDb3VudA==');

@$core.Deprecated('Use registerRequestDescriptor instead')
const RegisterRequest$json = {
  '1': 'RegisterRequest',
  '2': [
    {'1': 'nickname', '3': 1, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'account', '3': 2, '4': 1, '5': 9, '10': 'account'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `RegisterRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerRequestDescriptor = $convert.base64Decode(
    'Cg9SZWdpc3RlclJlcXVlc3QSGgoIbmlja25hbWUYASABKAlSCG5pY2tuYW1lEhgKB2FjY291bn'
    'QYAiABKAlSB2FjY291bnQSGgoIcGFzc3dvcmQYAyABKAlSCHBhc3N3b3Jk');

@$core.Deprecated('Use registerResponseDescriptor instead')
const RegisterResponse$json = {
  '1': 'RegisterResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'profile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.UserProfile',
      '10': 'profile'
    },
  ],
};

/// Descriptor for `RegisterResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerResponseDescriptor = $convert.base64Decode(
    'ChBSZWdpc3RlclJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZR'
    'gCIAEoCVIHbWVzc2FnZRI5Cgdwcm9maWxlGAMgASgLMh8ubGFuZGxvcmRzLnByb3RvY29sLlVz'
    'ZXJQcm9maWxlUgdwcm9maWxl');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'account', '3': 1, '4': 1, '5': 9, '10': 'account'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSGAoHYWNjb3VudBgBIAEoCVIHYWNjb3VudBIaCghwYXNzd29yZBgCIA'
    'EoCVIIcGFzc3dvcmQ=');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'profile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.UserProfile',
      '10': 'profile'
    },
    {'1': 'session_token', '3': 4, '4': 1, '5': 9, '10': 'sessionToken'},
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode(
    'Cg1Mb2dpblJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZRgCIA'
    'EoCVIHbWVzc2FnZRI5Cgdwcm9maWxlGAMgASgLMh8ubGFuZGxvcmRzLnByb3RvY29sLlVzZXJQ'
    'cm9maWxlUgdwcm9maWxlEiMKDXNlc3Npb25fdG9rZW4YBCABKAlSDHNlc3Npb25Ub2tlbg==');

@$core.Deprecated('Use resetPasswordRequestDescriptor instead')
const ResetPasswordRequest$json = {
  '1': 'ResetPasswordRequest',
  '2': [
    {'1': 'account', '3': 1, '4': 1, '5': 9, '10': 'account'},
    {'1': 'new_password', '3': 2, '4': 1, '5': 9, '10': 'newPassword'},
  ],
};

/// Descriptor for `ResetPasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordRequestDescriptor = $convert.base64Decode(
    'ChRSZXNldFBhc3N3b3JkUmVxdWVzdBIYCgdhY2NvdW50GAEgASgJUgdhY2NvdW50EiEKDG5ld1'
    '9wYXNzd29yZBgCIAEoCVILbmV3UGFzc3dvcmQ=');

@$core.Deprecated('Use resetPasswordResponseDescriptor instead')
const ResetPasswordResponse$json = {
  '1': 'ResetPasswordResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ResetPasswordResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordResponseDescriptor = $convert.base64Decode(
    'ChVSZXNldFBhc3N3b3JkUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZX'
    'NzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use changePasswordRequestDescriptor instead')
const ChangePasswordRequest$json = {
  '1': 'ChangePasswordRequest',
  '2': [
    {'1': 'current_password', '3': 1, '4': 1, '5': 9, '10': 'currentPassword'},
    {'1': 'new_password', '3': 2, '4': 1, '5': 9, '10': 'newPassword'},
  ],
};

/// Descriptor for `ChangePasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePasswordRequestDescriptor = $convert.base64Decode(
    'ChVDaGFuZ2VQYXNzd29yZFJlcXVlc3QSKQoQY3VycmVudF9wYXNzd29yZBgBIAEoCVIPY3Vycm'
    'VudFBhc3N3b3JkEiEKDG5ld19wYXNzd29yZBgCIAEoCVILbmV3UGFzc3dvcmQ=');

@$core.Deprecated('Use changePasswordResponseDescriptor instead')
const ChangePasswordResponse$json = {
  '1': 'ChangePasswordResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ChangePasswordResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List changePasswordResponseDescriptor =
    $convert.base64Decode(
        'ChZDaGFuZ2VQYXNzd29yZFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbW'
        'Vzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use updateNicknameRequestDescriptor instead')
const UpdateNicknameRequest$json = {
  '1': 'UpdateNicknameRequest',
  '2': [
    {'1': 'nickname', '3': 1, '4': 1, '5': 9, '10': 'nickname'},
  ],
};

/// Descriptor for `UpdateNicknameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateNicknameRequestDescriptor =
    $convert.base64Decode(
        'ChVVcGRhdGVOaWNrbmFtZVJlcXVlc3QSGgoIbmlja25hbWUYASABKAlSCG5pY2tuYW1l');

@$core.Deprecated('Use updateNicknameResponseDescriptor instead')
const UpdateNicknameResponse$json = {
  '1': 'UpdateNicknameResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'profile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.UserProfile',
      '10': 'profile'
    },
  ],
};

/// Descriptor for `UpdateNicknameResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateNicknameResponseDescriptor = $convert.base64Decode(
    'ChZVcGRhdGVOaWNrbmFtZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbW'
    'Vzc2FnZRgCIAEoCVIHbWVzc2FnZRI5Cgdwcm9maWxlGAMgASgLMh8ubGFuZGxvcmRzLnByb3Rv'
    'Y29sLlVzZXJQcm9maWxlUgdwcm9maWxl');

@$core.Deprecated('Use fetchSystemStatsRequestDescriptor instead')
const FetchSystemStatsRequest$json = {
  '1': 'FetchSystemStatsRequest',
};

/// Descriptor for `FetchSystemStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchSystemStatsRequestDescriptor =
    $convert.base64Decode('ChdGZXRjaFN5c3RlbVN0YXRzUmVxdWVzdA==');

@$core.Deprecated('Use fetchSystemStatsResponseDescriptor instead')
const FetchSystemStatsResponse$json = {
  '1': 'FetchSystemStatsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'stats',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.SystemStatsSnapshot',
      '10': 'stats'
    },
  ],
};

/// Descriptor for `FetchSystemStatsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchSystemStatsResponseDescriptor = $convert.base64Decode(
    'ChhGZXRjaFN5c3RlbVN0YXRzUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCg'
    'dtZXNzYWdlGAIgASgJUgdtZXNzYWdlEj0KBXN0YXRzGAMgASgLMicubGFuZGxvcmRzLnByb3Rv'
    'Y29sLlN5c3RlbVN0YXRzU25hcHNob3RSBXN0YXRz');

@$core.Deprecated('Use submitSupportLikeRequestDescriptor instead')
const SubmitSupportLikeRequest$json = {
  '1': 'SubmitSupportLikeRequest',
};

/// Descriptor for `SubmitSupportLikeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitSupportLikeRequestDescriptor =
    $convert.base64Decode('ChhTdWJtaXRTdXBwb3J0TGlrZVJlcXVlc3Q=');

@$core.Deprecated('Use submitSupportLikeResponseDescriptor instead')
const SubmitSupportLikeResponse$json = {
  '1': 'SubmitSupportLikeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'stats',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.SystemStatsSnapshot',
      '10': 'stats'
    },
  ],
};

/// Descriptor for `SubmitSupportLikeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List submitSupportLikeResponseDescriptor = $convert.base64Decode(
    'ChlTdWJtaXRTdXBwb3J0TGlrZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGA'
    'oHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZRI9CgVzdGF0cxgDIAEoCzInLmxhbmRsb3Jkcy5wcm90'
    'b2NvbC5TeXN0ZW1TdGF0c1NuYXBzaG90UgVzdGF0cw==');

@$core.Deprecated('Use claimSupportLikeRewardRequestDescriptor instead')
const ClaimSupportLikeRewardRequest$json = {
  '1': 'ClaimSupportLikeRewardRequest',
};

/// Descriptor for `ClaimSupportLikeRewardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List claimSupportLikeRewardRequestDescriptor =
    $convert.base64Decode('Ch1DbGFpbVN1cHBvcnRMaWtlUmV3YXJkUmVxdWVzdA==');

@$core.Deprecated('Use claimSupportLikeRewardResponseDescriptor instead')
const ClaimSupportLikeRewardResponse$json = {
  '1': 'ClaimSupportLikeRewardResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'profile',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.UserProfile',
      '10': 'profile'
    },
    {
      '1': 'stats',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.SystemStatsSnapshot',
      '10': 'stats'
    },
    {'1': 'reward_coins', '3': 5, '4': 1, '5': 5, '10': 'rewardCoins'},
  ],
};

/// Descriptor for `ClaimSupportLikeRewardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List claimSupportLikeRewardResponseDescriptor = $convert.base64Decode(
    'Ch5DbGFpbVN1cHBvcnRMaWtlUmV3YXJkUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2'
    'VzcxIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdlEjkKB3Byb2ZpbGUYAyABKAsyHy5sYW5kbG9y'
    'ZHMucHJvdG9jb2wuVXNlclByb2ZpbGVSB3Byb2ZpbGUSPQoFc3RhdHMYBCABKAsyJy5sYW5kbG'
    '9yZHMucHJvdG9jb2wuU3lzdGVtU3RhdHNTbmFwc2hvdFIFc3RhdHMSIQoMcmV3YXJkX2NvaW5z'
    'GAUgASgFUgtyZXdhcmRDb2lucw==');

@$core.Deprecated('Use matchRequestDescriptor instead')
const MatchRequest$json = {
  '1': 'MatchRequest',
  '2': [
    {
      '1': 'mode',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.MatchMode',
      '10': 'mode'
    },
    {
      '1': 'bot_difficulty',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.BotDifficulty',
      '10': 'botDifficulty'
    },
  ],
};

/// Descriptor for `MatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchRequestDescriptor = $convert.base64Decode(
    'CgxNYXRjaFJlcXVlc3QSMQoEbW9kZRgBIAEoDjIdLmxhbmRsb3Jkcy5wcm90b2NvbC5NYXRjaE'
    '1vZGVSBG1vZGUSSAoOYm90X2RpZmZpY3VsdHkYAiABKA4yIS5sYW5kbG9yZHMucHJvdG9jb2wu'
    'Qm90RGlmZmljdWx0eVINYm90RGlmZmljdWx0eQ==');

@$core.Deprecated('Use createRoomRequestDescriptor instead')
const CreateRoomRequest$json = {
  '1': 'CreateRoomRequest',
};

/// Descriptor for `CreateRoomRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createRoomRequestDescriptor =
    $convert.base64Decode('ChFDcmVhdGVSb29tUmVxdWVzdA==');

@$core.Deprecated('Use joinRoomRequestDescriptor instead')
const JoinRoomRequest$json = {
  '1': 'JoinRoomRequest',
  '2': [
    {'1': 'room_code', '3': 1, '4': 1, '5': 9, '10': 'roomCode'},
  ],
};

/// Descriptor for `JoinRoomRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List joinRoomRequestDescriptor = $convert.base64Decode(
    'Cg9Kb2luUm9vbVJlcXVlc3QSGwoJcm9vbV9jb2RlGAEgASgJUghyb29tQ29kZQ==');

@$core.Deprecated('Use leaveRoomRequestDescriptor instead')
const LeaveRoomRequest$json = {
  '1': 'LeaveRoomRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
  ],
};

/// Descriptor for `LeaveRoomRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveRoomRequestDescriptor = $convert.base64Decode(
    'ChBMZWF2ZVJvb21SZXF1ZXN0EhcKB3Jvb21faWQYASABKAlSBnJvb21JZA==');

@$core.Deprecated('Use roomReadyRequestDescriptor instead')
const RoomReadyRequest$json = {
  '1': 'RoomReadyRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {'1': 'ready', '3': 2, '4': 1, '5': 8, '10': 'ready'},
  ],
};

/// Descriptor for `RoomReadyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomReadyRequestDescriptor = $convert.base64Decode(
    'ChBSb29tUmVhZHlSZXF1ZXN0EhcKB3Jvb21faWQYASABKAlSBnJvb21JZBIUCgVyZWFkeRgCIA'
    'EoCFIFcmVhZHk=');

@$core.Deprecated('Use addBotRequestDescriptor instead')
const AddBotRequest$json = {
  '1': 'AddBotRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {
      '1': 'bot_difficulty',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.BotDifficulty',
      '10': 'botDifficulty'
    },
    {'1': 'seat_index', '3': 3, '4': 1, '5': 5, '10': 'seatIndex'},
  ],
};

/// Descriptor for `AddBotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addBotRequestDescriptor = $convert.base64Decode(
    'Cg1BZGRCb3RSZXF1ZXN0EhcKB3Jvb21faWQYASABKAlSBnJvb21JZBJICg5ib3RfZGlmZmljdW'
    'x0eRgCIAEoDjIhLmxhbmRsb3Jkcy5wcm90b2NvbC5Cb3REaWZmaWN1bHR5Ug1ib3REaWZmaWN1'
    'bHR5Eh0KCnNlYXRfaW5kZXgYAyABKAVSCXNlYXRJbmRleA==');

@$core.Deprecated('Use removePlayerRequestDescriptor instead')
const RemovePlayerRequest$json = {
  '1': 'RemovePlayerRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {'1': 'player_id', '3': 2, '4': 1, '5': 9, '10': 'playerId'},
  ],
};

/// Descriptor for `RemovePlayerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removePlayerRequestDescriptor = $convert.base64Decode(
    'ChNSZW1vdmVQbGF5ZXJSZXF1ZXN0EhcKB3Jvb21faWQYASABKAlSBnJvb21JZBIbCglwbGF5ZX'
    'JfaWQYAiABKAlSCHBsYXllcklk');

@$core.Deprecated('Use listFriendsRequestDescriptor instead')
const ListFriendsRequest$json = {
  '1': 'ListFriendsRequest',
};

/// Descriptor for `ListFriendsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFriendsRequestDescriptor =
    $convert.base64Decode('ChJMaXN0RnJpZW5kc1JlcXVlc3Q=');

@$core.Deprecated('Use listFriendsResponseDescriptor instead')
const ListFriendsResponse$json = {
  '1': 'ListFriendsResponse',
  '2': [
    {
      '1': 'users',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.OnlineUser',
      '10': 'users'
    },
    {
      '1': 'snapshot',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendCenterSnapshot',
      '10': 'snapshot'
    },
  ],
};

/// Descriptor for `ListFriendsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFriendsResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0RnJpZW5kc1Jlc3BvbnNlEjQKBXVzZXJzGAEgAygLMh4ubGFuZGxvcmRzLnByb3RvY2'
    '9sLk9ubGluZVVzZXJSBXVzZXJzEkQKCHNuYXBzaG90GAIgASgLMigubGFuZGxvcmRzLnByb3Rv'
    'Y29sLkZyaWVuZENlbnRlclNuYXBzaG90UghzbmFwc2hvdA==');

@$core.Deprecated('Use addFriendRequestDescriptor instead')
const AddFriendRequest$json = {
  '1': 'AddFriendRequest',
  '2': [
    {'1': 'account', '3': 1, '4': 1, '5': 9, '10': 'account'},
  ],
};

/// Descriptor for `AddFriendRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addFriendRequestDescriptor = $convert.base64Decode(
    'ChBBZGRGcmllbmRSZXF1ZXN0EhgKB2FjY291bnQYASABKAlSB2FjY291bnQ=');

@$core.Deprecated('Use addFriendResponseDescriptor instead')
const AddFriendResponse$json = {
  '1': 'AddFriendResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'request',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendRequestEntry',
      '10': 'request'
    },
    {
      '1': 'snapshot',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendCenterSnapshot',
      '10': 'snapshot'
    },
  ],
};

/// Descriptor for `AddFriendResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addFriendResponseDescriptor = $convert.base64Decode(
    'ChFBZGRGcmllbmRSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2USQAoHcmVxdWVzdBgDIAEoCzImLmxhbmRsb3Jkcy5wcm90b2NvbC5G'
    'cmllbmRSZXF1ZXN0RW50cnlSB3JlcXVlc3QSRAoIc25hcHNob3QYBCABKAsyKC5sYW5kbG9yZH'
    'MucHJvdG9jb2wuRnJpZW5kQ2VudGVyU25hcHNob3RSCHNuYXBzaG90');

@$core.Deprecated('Use respondFriendRequestRequestDescriptor instead')
const RespondFriendRequestRequest$json = {
  '1': 'RespondFriendRequestRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'accept', '3': 2, '4': 1, '5': 8, '10': 'accept'},
  ],
};

/// Descriptor for `RespondFriendRequestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respondFriendRequestRequestDescriptor =
    $convert.base64Decode(
        'ChtSZXNwb25kRnJpZW5kUmVxdWVzdFJlcXVlc3QSHQoKcmVxdWVzdF9pZBgBIAEoCVIJcmVxdW'
        'VzdElkEhYKBmFjY2VwdBgCIAEoCFIGYWNjZXB0');

@$core.Deprecated('Use respondFriendRequestResponseDescriptor instead')
const RespondFriendRequestResponse$json = {
  '1': 'RespondFriendRequestResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'request',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendRequestEntry',
      '10': 'request'
    },
    {
      '1': 'snapshot',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendCenterSnapshot',
      '10': 'snapshot'
    },
  ],
};

/// Descriptor for `RespondFriendRequestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respondFriendRequestResponseDescriptor = $convert.base64Decode(
    'ChxSZXNwb25kRnJpZW5kUmVxdWVzdFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3'
    'MSGAoHbWVzc2FnZRgCIAEoCVIHbWVzc2FnZRJACgdyZXF1ZXN0GAMgASgLMiYubGFuZGxvcmRz'
    'LnByb3RvY29sLkZyaWVuZFJlcXVlc3RFbnRyeVIHcmVxdWVzdBJECghzbmFwc2hvdBgEIAEoCz'
    'IoLmxhbmRsb3Jkcy5wcm90b2NvbC5GcmllbmRDZW50ZXJTbmFwc2hvdFIIc25hcHNob3Q=');

@$core.Deprecated('Use deleteFriendRequestDescriptor instead')
const DeleteFriendRequest$json = {
  '1': 'DeleteFriendRequest',
  '2': [
    {'1': 'friend_user_id', '3': 1, '4': 1, '5': 9, '10': 'friendUserId'},
  ],
};

/// Descriptor for `DeleteFriendRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFriendRequestDescriptor = $convert.base64Decode(
    'ChNEZWxldGVGcmllbmRSZXF1ZXN0EiQKDmZyaWVuZF91c2VyX2lkGAEgASgJUgxmcmllbmRVc2'
    'VySWQ=');

@$core.Deprecated('Use deleteFriendResponseDescriptor instead')
const DeleteFriendResponse$json = {
  '1': 'DeleteFriendResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'snapshot',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendCenterSnapshot',
      '10': 'snapshot'
    },
  ],
};

/// Descriptor for `DeleteFriendResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteFriendResponseDescriptor = $convert.base64Decode(
    'ChREZWxldGVGcmllbmRSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2USRAoIc25hcHNob3QYAyABKAsyKC5sYW5kbG9yZHMucHJvdG9j'
    'b2wuRnJpZW5kQ2VudGVyU25hcHNob3RSCHNuYXBzaG90');

@$core.Deprecated('Use invitePlayerRequestDescriptor instead')
const InvitePlayerRequest$json = {
  '1': 'InvitePlayerRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {'1': 'invitee_account', '3': 2, '4': 1, '5': 9, '10': 'inviteeAccount'},
    {'1': 'seat_index', '3': 3, '4': 1, '5': 5, '10': 'seatIndex'},
  ],
};

/// Descriptor for `InvitePlayerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invitePlayerRequestDescriptor = $convert.base64Decode(
    'ChNJbnZpdGVQbGF5ZXJSZXF1ZXN0EhcKB3Jvb21faWQYASABKAlSBnJvb21JZBInCg9pbnZpdG'
    'VlX2FjY291bnQYAiABKAlSDmludml0ZWVBY2NvdW50Eh0KCnNlYXRfaW5kZXgYAyABKAVSCXNl'
    'YXRJbmRleA==');

@$core.Deprecated('Use invitePlayerResponseDescriptor instead')
const InvitePlayerResponse$json = {
  '1': 'InvitePlayerResponse',
  '2': [
    {'1': 'accepted', '3': 1, '4': 1, '5': 8, '10': 'accepted'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `InvitePlayerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invitePlayerResponseDescriptor = $convert.base64Decode(
    'ChRJbnZpdGVQbGF5ZXJSZXNwb25zZRIaCghhY2NlcHRlZBgBIAEoCFIIYWNjZXB0ZWQSGAoHbW'
    'Vzc2FnZRgCIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use roomInvitationPushDescriptor instead')
const RoomInvitationPush$json = {
  '1': 'RoomInvitationPush',
  '2': [
    {'1': 'invitation_id', '3': 1, '4': 1, '5': 9, '10': 'invitationId'},
    {'1': 'room_id', '3': 2, '4': 1, '5': 9, '10': 'roomId'},
    {'1': 'room_code', '3': 3, '4': 1, '5': 9, '10': 'roomCode'},
    {'1': 'inviter_user_id', '3': 4, '4': 1, '5': 9, '10': 'inviterUserId'},
    {'1': 'inviter_account', '3': 5, '4': 1, '5': 9, '10': 'inviterAccount'},
    {'1': 'inviter_nickname', '3': 6, '4': 1, '5': 9, '10': 'inviterNickname'},
    {'1': 'seat_index', '3': 7, '4': 1, '5': 5, '10': 'seatIndex'},
  ],
};

/// Descriptor for `RoomInvitationPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomInvitationPushDescriptor = $convert.base64Decode(
    'ChJSb29tSW52aXRhdGlvblB1c2gSIwoNaW52aXRhdGlvbl9pZBgBIAEoCVIMaW52aXRhdGlvbk'
    'lkEhcKB3Jvb21faWQYAiABKAlSBnJvb21JZBIbCglyb29tX2NvZGUYAyABKAlSCHJvb21Db2Rl'
    'EiYKD2ludml0ZXJfdXNlcl9pZBgEIAEoCVINaW52aXRlclVzZXJJZBInCg9pbnZpdGVyX2FjY2'
    '91bnQYBSABKAlSDmludml0ZXJBY2NvdW50EikKEGludml0ZXJfbmlja25hbWUYBiABKAlSD2lu'
    'dml0ZXJOaWNrbmFtZRIdCgpzZWF0X2luZGV4GAcgASgFUglzZWF0SW5kZXg=');

@$core.Deprecated('Use respondRoomInvitationRequestDescriptor instead')
const RespondRoomInvitationRequest$json = {
  '1': 'RespondRoomInvitationRequest',
  '2': [
    {'1': 'invitation_id', '3': 1, '4': 1, '5': 9, '10': 'invitationId'},
    {'1': 'accept', '3': 2, '4': 1, '5': 8, '10': 'accept'},
  ],
};

/// Descriptor for `RespondRoomInvitationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respondRoomInvitationRequestDescriptor =
    $convert.base64Decode(
        'ChxSZXNwb25kUm9vbUludml0YXRpb25SZXF1ZXN0EiMKDWludml0YXRpb25faWQYASABKAlSDG'
        'ludml0YXRpb25JZBIWCgZhY2NlcHQYAiABKAhSBmFjY2VwdA==');

@$core.Deprecated('Use respondRoomInvitationResponseDescriptor instead')
const RespondRoomInvitationResponse$json = {
  '1': 'RespondRoomInvitationResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'snapshot',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RoomSnapshot',
      '10': 'snapshot'
    },
  ],
};

/// Descriptor for `RespondRoomInvitationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List respondRoomInvitationResponseDescriptor =
    $convert.base64Decode(
        'Ch1SZXNwb25kUm9vbUludml0YXRpb25SZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZX'
        'NzEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USPAoIc25hcHNob3QYAyABKAsyIC5sYW5kbG9y'
        'ZHMucHJvdG9jb2wuUm9vbVNuYXBzaG90UghzbmFwc2hvdA==');

@$core.Deprecated('Use roomInvitationResultPushDescriptor instead')
const RoomInvitationResultPush$json = {
  '1': 'RoomInvitationResultPush',
  '2': [
    {'1': 'invitation_id', '3': 1, '4': 1, '5': 9, '10': 'invitationId'},
    {
      '1': 'result',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.InvitationResult',
      '10': 'result'
    },
    {'1': 'invitee_user_id', '3': 3, '4': 1, '5': 9, '10': 'inviteeUserId'},
    {'1': 'invitee_account', '3': 4, '4': 1, '5': 9, '10': 'inviteeAccount'},
    {'1': 'invitee_nickname', '3': 5, '4': 1, '5': 9, '10': 'inviteeNickname'},
    {'1': 'message', '3': 6, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `RoomInvitationResultPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomInvitationResultPushDescriptor = $convert.base64Decode(
    'ChhSb29tSW52aXRhdGlvblJlc3VsdFB1c2gSIwoNaW52aXRhdGlvbl9pZBgBIAEoCVIMaW52aX'
    'RhdGlvbklkEjwKBnJlc3VsdBgCIAEoDjIkLmxhbmRsb3Jkcy5wcm90b2NvbC5JbnZpdGF0aW9u'
    'UmVzdWx0UgZyZXN1bHQSJgoPaW52aXRlZV91c2VyX2lkGAMgASgJUg1pbnZpdGVlVXNlcklkEi'
    'cKD2ludml0ZWVfYWNjb3VudBgEIAEoCVIOaW52aXRlZUFjY291bnQSKQoQaW52aXRlZV9uaWNr'
    'bmFtZRgFIAEoCVIPaW52aXRlZU5pY2tuYW1lEhgKB21lc3NhZ2UYBiABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use friendCenterPushDescriptor instead')
const FriendCenterPush$json = {
  '1': 'FriendCenterPush',
  '2': [
    {
      '1': 'snapshot',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendCenterSnapshot',
      '10': 'snapshot'
    },
  ],
};

/// Descriptor for `FriendCenterPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List friendCenterPushDescriptor = $convert.base64Decode(
    'ChBGcmllbmRDZW50ZXJQdXNoEkQKCHNuYXBzaG90GAEgASgLMigubGFuZGxvcmRzLnByb3RvY2'
    '9sLkZyaWVuZENlbnRlclNuYXBzaG90UghzbmFwc2hvdA==');

@$core.Deprecated('Use matchResponseDescriptor instead')
const MatchResponse$json = {
  '1': 'MatchResponse',
  '2': [
    {'1': 'accepted', '3': 1, '4': 1, '5': 8, '10': 'accepted'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `MatchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchResponseDescriptor = $convert.base64Decode(
    'Cg1NYXRjaFJlc3BvbnNlEhoKCGFjY2VwdGVkGAEgASgIUghhY2NlcHRlZBIYCgdtZXNzYWdlGA'
    'IgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use matchFoundPushDescriptor instead')
const MatchFoundPush$json = {
  '1': 'MatchFoundPush',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.MatchMode',
      '10': 'mode'
    },
    {
      '1': 'players',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.RoomPlayer',
      '10': 'players'
    },
  ],
};

/// Descriptor for `MatchFoundPush`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchFoundPushDescriptor = $convert.base64Decode(
    'Cg5NYXRjaEZvdW5kUHVzaBIXCgdyb29tX2lkGAEgASgJUgZyb29tSWQSMQoEbW9kZRgCIAEoDj'
    'IdLmxhbmRsb3Jkcy5wcm90b2NvbC5NYXRjaE1vZGVSBG1vZGUSOAoHcGxheWVycxgDIAMoCzIe'
    'LmxhbmRsb3Jkcy5wcm90b2NvbC5Sb29tUGxheWVyUgdwbGF5ZXJz');

@$core.Deprecated('Use roomPlayerDescriptor instead')
const RoomPlayer$json = {
  '1': 'RoomPlayer',
  '2': [
    {'1': 'player_id', '3': 1, '4': 1, '5': 9, '10': 'playerId'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'is_bot', '3': 3, '4': 1, '5': 8, '10': 'isBot'},
    {
      '1': 'role',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.PlayerRole',
      '10': 'role'
    },
    {'1': 'cards_left', '3': 5, '4': 1, '5': 5, '10': 'cardsLeft'},
    {'1': 'round_score', '3': 6, '4': 1, '5': 5, '10': 'roundScore'},
    {'1': 'seat_index', '3': 7, '4': 1, '5': 5, '10': 'seatIndex'},
    {'1': 'ready', '3': 8, '4': 1, '5': 8, '10': 'ready'},
    {'1': 'occupied', '3': 9, '4': 1, '5': 8, '10': 'occupied'},
  ],
};

/// Descriptor for `RoomPlayer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomPlayerDescriptor = $convert.base64Decode(
    'CgpSb29tUGxheWVyEhsKCXBsYXllcl9pZBgBIAEoCVIIcGxheWVySWQSIQoMZGlzcGxheV9uYW'
    '1lGAIgASgJUgtkaXNwbGF5TmFtZRIVCgZpc19ib3QYAyABKAhSBWlzQm90EjIKBHJvbGUYBCAB'
    'KA4yHi5sYW5kbG9yZHMucHJvdG9jb2wuUGxheWVyUm9sZVIEcm9sZRIdCgpjYXJkc19sZWZ0GA'
    'UgASgFUgljYXJkc0xlZnQSHwoLcm91bmRfc2NvcmUYBiABKAVSCnJvdW5kU2NvcmUSHQoKc2Vh'
    'dF9pbmRleBgHIAEoBVIJc2VhdEluZGV4EhQKBXJlYWR5GAggASgIUgVyZWFkeRIaCghvY2N1cG'
    'llZBgJIAEoCFIIb2NjdXBpZWQ=');

@$core.Deprecated('Use cardDescriptor instead')
const Card$json = {
  '1': 'Card',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'rank', '3': 2, '4': 1, '5': 9, '10': 'rank'},
    {'1': 'suit', '3': 3, '4': 1, '5': 9, '10': 'suit'},
    {'1': 'value', '3': 4, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `Card`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cardDescriptor = $convert.base64Decode(
    'CgRDYXJkEg4KAmlkGAEgASgJUgJpZBISCgRyYW5rGAIgASgJUgRyYW5rEhIKBHN1aXQYAyABKA'
    'lSBHN1aXQSFAoFdmFsdWUYBCABKAVSBXZhbHVl');

@$core.Deprecated('Use cardCounterEntryDescriptor instead')
const CardCounterEntry$json = {
  '1': 'CardCounterEntry',
  '2': [
    {'1': 'rank', '3': 1, '4': 1, '5': 9, '10': 'rank'},
    {'1': 'remaining', '3': 2, '4': 1, '5': 5, '10': 'remaining'},
  ],
};

/// Descriptor for `CardCounterEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cardCounterEntryDescriptor = $convert.base64Decode(
    'ChBDYXJkQ291bnRlckVudHJ5EhIKBHJhbmsYASABKAlSBHJhbmsSHAoJcmVtYWluaW5nGAIgAS'
    'gFUglyZW1haW5pbmc=');

@$core.Deprecated('Use tableActionDescriptor instead')
const TableAction$json = {
  '1': 'TableAction',
  '2': [
    {'1': 'action_id', '3': 1, '4': 1, '5': 9, '10': 'actionId'},
    {'1': 'player_id', '3': 2, '4': 1, '5': 9, '10': 'playerId'},
    {
      '1': 'action_type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.ActionType',
      '10': 'actionType'
    },
    {
      '1': 'cards',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.Card',
      '10': 'cards'
    },
    {'1': 'pattern', '3': 5, '4': 1, '5': 9, '10': 'pattern'},
    {'1': 'timestamp_ms', '3': 6, '4': 1, '5': 3, '10': 'timestampMs'},
    {
      '1': 'pattern_type',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.PatternType',
      '10': 'patternType'
    },
  ],
};

/// Descriptor for `TableAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tableActionDescriptor = $convert.base64Decode(
    'CgtUYWJsZUFjdGlvbhIbCglhY3Rpb25faWQYASABKAlSCGFjdGlvbklkEhsKCXBsYXllcl9pZB'
    'gCIAEoCVIIcGxheWVySWQSPwoLYWN0aW9uX3R5cGUYAyABKA4yHi5sYW5kbG9yZHMucHJvdG9j'
    'b2wuQWN0aW9uVHlwZVIKYWN0aW9uVHlwZRIuCgVjYXJkcxgEIAMoCzIYLmxhbmRsb3Jkcy5wcm'
    '90b2NvbC5DYXJkUgVjYXJkcxIYCgdwYXR0ZXJuGAUgASgJUgdwYXR0ZXJuEiEKDHRpbWVzdGFt'
    'cF9tcxgGIAEoA1ILdGltZXN0YW1wTXMSQgoMcGF0dGVybl90eXBlGAcgASgOMh8ubGFuZGxvcm'
    'RzLnByb3RvY29sLlBhdHRlcm5UeXBlUgtwYXR0ZXJuVHlwZQ==');

@$core.Deprecated('Use roomSnapshotDescriptor instead')
const RoomSnapshot$json = {
  '1': 'RoomSnapshot',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {
      '1': 'phase',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.RoomPhase',
      '10': 'phase'
    },
    {
      '1': 'mode',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.MatchMode',
      '10': 'mode'
    },
    {
      '1': 'players',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.RoomPlayer',
      '10': 'players'
    },
    {
      '1': 'self_cards',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.Card',
      '10': 'selfCards'
    },
    {
      '1': 'landlord_cards',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.Card',
      '10': 'landlordCards'
    },
    {
      '1': 'recent_actions',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.TableAction',
      '10': 'recentActions'
    },
    {
      '1': 'current_turn_player_id',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'currentTurnPlayerId'
    },
    {'1': 'status_text', '3': 9, '4': 1, '5': 9, '10': 'statusText'},
    {
      '1': 'card_counter',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.landlords.protocol.CardCounterEntry',
      '10': 'cardCounter'
    },
    {'1': 'base_score', '3': 11, '4': 1, '5': 5, '10': 'baseScore'},
    {'1': 'multiplier', '3': 12, '4': 1, '5': 5, '10': 'multiplier'},
    {
      '1': 'current_round_score',
      '3': 13,
      '4': 1,
      '5': 5,
      '10': 'currentRoundScore'
    },
    {'1': 'spring_triggered', '3': 14, '4': 1, '5': 8, '10': 'springTriggered'},
    {'1': 'turn_serial', '3': 15, '4': 1, '5': 5, '10': 'turnSerial'},
    {'1': 'room_code', '3': 16, '4': 1, '5': 9, '10': 'roomCode'},
    {'1': 'owner_player_id', '3': 17, '4': 1, '5': 9, '10': 'ownerPlayerId'},
  ],
};

/// Descriptor for `RoomSnapshot`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomSnapshotDescriptor = $convert.base64Decode(
    'CgxSb29tU25hcHNob3QSFwoHcm9vbV9pZBgBIAEoCVIGcm9vbUlkEjMKBXBoYXNlGAIgASgOMh'
    '0ubGFuZGxvcmRzLnByb3RvY29sLlJvb21QaGFzZVIFcGhhc2USMQoEbW9kZRgDIAEoDjIdLmxh'
    'bmRsb3Jkcy5wcm90b2NvbC5NYXRjaE1vZGVSBG1vZGUSOAoHcGxheWVycxgEIAMoCzIeLmxhbm'
    'Rsb3Jkcy5wcm90b2NvbC5Sb29tUGxheWVyUgdwbGF5ZXJzEjcKCnNlbGZfY2FyZHMYBSADKAsy'
    'GC5sYW5kbG9yZHMucHJvdG9jb2wuQ2FyZFIJc2VsZkNhcmRzEj8KDmxhbmRsb3JkX2NhcmRzGA'
    'YgAygLMhgubGFuZGxvcmRzLnByb3RvY29sLkNhcmRSDWxhbmRsb3JkQ2FyZHMSRgoOcmVjZW50'
    'X2FjdGlvbnMYByADKAsyHy5sYW5kbG9yZHMucHJvdG9jb2wuVGFibGVBY3Rpb25SDXJlY2VudE'
    'FjdGlvbnMSMwoWY3VycmVudF90dXJuX3BsYXllcl9pZBgIIAEoCVITY3VycmVudFR1cm5QbGF5'
    'ZXJJZBIfCgtzdGF0dXNfdGV4dBgJIAEoCVIKc3RhdHVzVGV4dBJHCgxjYXJkX2NvdW50ZXIYCi'
    'ADKAsyJC5sYW5kbG9yZHMucHJvdG9jb2wuQ2FyZENvdW50ZXJFbnRyeVILY2FyZENvdW50ZXIS'
    'HQoKYmFzZV9zY29yZRgLIAEoBVIJYmFzZVNjb3JlEh4KCm11bHRpcGxpZXIYDCABKAVSCm11bH'
    'RpcGxpZXISLgoTY3VycmVudF9yb3VuZF9zY29yZRgNIAEoBVIRY3VycmVudFJvdW5kU2NvcmUS'
    'KQoQc3ByaW5nX3RyaWdnZXJlZBgOIAEoCFIPc3ByaW5nVHJpZ2dlcmVkEh8KC3R1cm5fc2VyaW'
    'FsGA8gASgFUgp0dXJuU2VyaWFsEhsKCXJvb21fY29kZRgQIAEoCVIIcm9vbUNvZGUSJgoPb3du'
    'ZXJfcGxheWVyX2lkGBEgASgJUg1vd25lclBsYXllcklk');

@$core.Deprecated('Use playCardsRequestDescriptor instead')
const PlayCardsRequest$json = {
  '1': 'PlayCardsRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
    {'1': 'card_ids', '3': 2, '4': 3, '5': 9, '10': 'cardIds'},
  ],
};

/// Descriptor for `PlayCardsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playCardsRequestDescriptor = $convert.base64Decode(
    'ChBQbGF5Q2FyZHNSZXF1ZXN0EhcKB3Jvb21faWQYASABKAlSBnJvb21JZBIZCghjYXJkX2lkcx'
    'gCIAMoCVIHY2FyZElkcw==');

@$core.Deprecated('Use passRequestDescriptor instead')
const PassRequest$json = {
  '1': 'PassRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
  ],
};

/// Descriptor for `PassRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List passRequestDescriptor = $convert
    .base64Decode('CgtQYXNzUmVxdWVzdBIXCgdyb29tX2lkGAEgASgJUgZyb29tSWQ=');

@$core.Deprecated('Use reconnectRequestDescriptor instead')
const ReconnectRequest$json = {
  '1': 'ReconnectRequest',
  '2': [
    {'1': 'room_id', '3': 1, '4': 1, '5': 9, '10': 'roomId'},
  ],
};

/// Descriptor for `ReconnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reconnectRequestDescriptor = $convert.base64Decode(
    'ChBSZWNvbm5lY3RSZXF1ZXN0EhcKB3Jvb21faWQYASABKAlSBnJvb21JZA==');

@$core.Deprecated('Use heartbeatRequestDescriptor instead')
const HeartbeatRequest$json = {
  '1': 'HeartbeatRequest',
  '2': [
    {'1': 'client_time_ms', '3': 1, '4': 1, '5': 3, '10': 'clientTimeMs'},
  ],
};

/// Descriptor for `HeartbeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatRequestDescriptor = $convert.base64Decode(
    'ChBIZWFydGJlYXRSZXF1ZXN0EiQKDmNsaWVudF90aW1lX21zGAEgASgDUgxjbGllbnRUaW1lTX'
    'M=');

@$core.Deprecated('Use heartbeatResponseDescriptor instead')
const HeartbeatResponse$json = {
  '1': 'HeartbeatResponse',
  '2': [
    {'1': 'server_time_ms', '3': 1, '4': 1, '5': 3, '10': 'serverTimeMs'},
  ],
};

/// Descriptor for `HeartbeatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatResponseDescriptor = $convert.base64Decode(
    'ChFIZWFydGJlYXRSZXNwb25zZRIkCg5zZXJ2ZXJfdGltZV9tcxgBIAEoA1IMc2VydmVyVGltZU'
    '1z');

@$core.Deprecated('Use operationResponseDescriptor instead')
const OperationResponse$json = {
  '1': 'OperationResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {
      '1': 'snapshot',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RoomSnapshot',
      '10': 'snapshot'
    },
  ],
};

/// Descriptor for `OperationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operationResponseDescriptor = $convert.base64Decode(
    'ChFPcGVyYXRpb25SZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2'
    'UYAiABKAlSB21lc3NhZ2USPAoIc25hcHNob3QYAyABKAsyIC5sYW5kbG9yZHMucHJvdG9jb2wu'
    'Um9vbVNuYXBzaG90UghzbmFwc2hvdA==');

@$core.Deprecated('Use errorResponseDescriptor instead')
const ErrorResponse$json = {
  '1': 'ErrorResponse',
  '2': [
    {
      '1': 'code',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.landlords.protocol.ErrorCode',
      '10': 'code'
    },
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ErrorResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorResponseDescriptor = $convert.base64Decode(
    'Cg1FcnJvclJlc3BvbnNlEjEKBGNvZGUYASABKA4yHS5sYW5kbG9yZHMucHJvdG9jb2wuRXJyb3'
    'JDb2RlUgRjb2RlEhgKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use clientMessageDescriptor instead')
const ClientMessage$json = {
  '1': 'ClientMessage',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_token', '3': 2, '4': 1, '5': 9, '10': 'sessionToken'},
    {
      '1': 'register_request',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RegisterRequest',
      '9': 0,
      '10': 'registerRequest'
    },
    {
      '1': 'login_request',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.LoginRequest',
      '9': 0,
      '10': 'loginRequest'
    },
    {
      '1': 'match_request',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.MatchRequest',
      '9': 0,
      '10': 'matchRequest'
    },
    {
      '1': 'play_cards_request',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.PlayCardsRequest',
      '9': 0,
      '10': 'playCardsRequest'
    },
    {
      '1': 'pass_request',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.PassRequest',
      '9': 0,
      '10': 'passRequest'
    },
    {
      '1': 'reconnect_request',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ReconnectRequest',
      '9': 0,
      '10': 'reconnectRequest'
    },
    {
      '1': 'heartbeat_request',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.HeartbeatRequest',
      '9': 0,
      '10': 'heartbeatRequest'
    },
    {
      '1': 'reset_password_request',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ResetPasswordRequest',
      '9': 0,
      '10': 'resetPasswordRequest'
    },
    {
      '1': 'create_room_request',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.CreateRoomRequest',
      '9': 0,
      '10': 'createRoomRequest'
    },
    {
      '1': 'join_room_request',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.JoinRoomRequest',
      '9': 0,
      '10': 'joinRoomRequest'
    },
    {
      '1': 'room_ready_request',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RoomReadyRequest',
      '9': 0,
      '10': 'roomReadyRequest'
    },
    {
      '1': 'add_bot_request',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.AddBotRequest',
      '9': 0,
      '10': 'addBotRequest'
    },
    {
      '1': 'remove_player_request',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RemovePlayerRequest',
      '9': 0,
      '10': 'removePlayerRequest'
    },
    {
      '1': 'list_friends_request',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ListFriendsRequest',
      '9': 0,
      '10': 'listFriendsRequest'
    },
    {
      '1': 'add_friend_request',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.AddFriendRequest',
      '9': 0,
      '10': 'addFriendRequest'
    },
    {
      '1': 'invite_player_request',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.InvitePlayerRequest',
      '9': 0,
      '10': 'invitePlayerRequest'
    },
    {
      '1': 'respond_room_invitation_request',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RespondRoomInvitationRequest',
      '9': 0,
      '10': 'respondRoomInvitationRequest'
    },
    {
      '1': 'leave_room_request',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.LeaveRoomRequest',
      '9': 0,
      '10': 'leaveRoomRequest'
    },
    {
      '1': 'update_nickname_request',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.UpdateNicknameRequest',
      '9': 0,
      '10': 'updateNicknameRequest'
    },
    {
      '1': 'respond_friend_request_request',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RespondFriendRequestRequest',
      '9': 0,
      '10': 'respondFriendRequestRequest'
    },
    {
      '1': 'delete_friend_request',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.DeleteFriendRequest',
      '9': 0,
      '10': 'deleteFriendRequest'
    },
    {
      '1': 'change_password_request',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ChangePasswordRequest',
      '9': 0,
      '10': 'changePasswordRequest'
    },
    {
      '1': 'fetch_system_stats_request',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FetchSystemStatsRequest',
      '9': 0,
      '10': 'fetchSystemStatsRequest'
    },
    {
      '1': 'claim_support_like_reward_request',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ClaimSupportLikeRewardRequest',
      '9': 0,
      '10': 'claimSupportLikeRewardRequest'
    },
    {
      '1': 'submit_support_like_request',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.SubmitSupportLikeRequest',
      '9': 0,
      '10': 'submitSupportLikeRequest'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `ClientMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientMessageDescriptor = $convert.base64Decode(
    'Cg1DbGllbnRNZXNzYWdlEh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3RJZBIjCg1zZXNzaW'
    '9uX3Rva2VuGAIgASgJUgxzZXNzaW9uVG9rZW4SUAoQcmVnaXN0ZXJfcmVxdWVzdBgKIAEoCzIj'
    'LmxhbmRsb3Jkcy5wcm90b2NvbC5SZWdpc3RlclJlcXVlc3RIAFIPcmVnaXN0ZXJSZXF1ZXN0Ek'
    'cKDWxvZ2luX3JlcXVlc3QYCyABKAsyIC5sYW5kbG9yZHMucHJvdG9jb2wuTG9naW5SZXF1ZXN0'
    'SABSDGxvZ2luUmVxdWVzdBJHCg1tYXRjaF9yZXF1ZXN0GAwgASgLMiAubGFuZGxvcmRzLnByb3'
    'RvY29sLk1hdGNoUmVxdWVzdEgAUgxtYXRjaFJlcXVlc3QSVAoScGxheV9jYXJkc19yZXF1ZXN0'
    'GA0gASgLMiQubGFuZGxvcmRzLnByb3RvY29sLlBsYXlDYXJkc1JlcXVlc3RIAFIQcGxheUNhcm'
    'RzUmVxdWVzdBJECgxwYXNzX3JlcXVlc3QYDiABKAsyHy5sYW5kbG9yZHMucHJvdG9jb2wuUGFz'
    'c1JlcXVlc3RIAFILcGFzc1JlcXVlc3QSUwoRcmVjb25uZWN0X3JlcXVlc3QYDyABKAsyJC5sYW'
    '5kbG9yZHMucHJvdG9jb2wuUmVjb25uZWN0UmVxdWVzdEgAUhByZWNvbm5lY3RSZXF1ZXN0ElMK'
    'EWhlYXJ0YmVhdF9yZXF1ZXN0GBAgASgLMiQubGFuZGxvcmRzLnByb3RvY29sLkhlYXJ0YmVhdF'
    'JlcXVlc3RIAFIQaGVhcnRiZWF0UmVxdWVzdBJgChZyZXNldF9wYXNzd29yZF9yZXF1ZXN0GBEg'
    'ASgLMigubGFuZGxvcmRzLnByb3RvY29sLlJlc2V0UGFzc3dvcmRSZXF1ZXN0SABSFHJlc2V0UG'
    'Fzc3dvcmRSZXF1ZXN0ElcKE2NyZWF0ZV9yb29tX3JlcXVlc3QYEiABKAsyJS5sYW5kbG9yZHMu'
    'cHJvdG9jb2wuQ3JlYXRlUm9vbVJlcXVlc3RIAFIRY3JlYXRlUm9vbVJlcXVlc3QSUQoRam9pbl'
    '9yb29tX3JlcXVlc3QYEyABKAsyIy5sYW5kbG9yZHMucHJvdG9jb2wuSm9pblJvb21SZXF1ZXN0'
    'SABSD2pvaW5Sb29tUmVxdWVzdBJUChJyb29tX3JlYWR5X3JlcXVlc3QYFCABKAsyJC5sYW5kbG'
    '9yZHMucHJvdG9jb2wuUm9vbVJlYWR5UmVxdWVzdEgAUhByb29tUmVhZHlSZXF1ZXN0EksKD2Fk'
    'ZF9ib3RfcmVxdWVzdBgVIAEoCzIhLmxhbmRsb3Jkcy5wcm90b2NvbC5BZGRCb3RSZXF1ZXN0SA'
    'BSDWFkZEJvdFJlcXVlc3QSXQoVcmVtb3ZlX3BsYXllcl9yZXF1ZXN0GBYgASgLMicubGFuZGxv'
    'cmRzLnByb3RvY29sLlJlbW92ZVBsYXllclJlcXVlc3RIAFITcmVtb3ZlUGxheWVyUmVxdWVzdB'
    'JaChRsaXN0X2ZyaWVuZHNfcmVxdWVzdBgXIAEoCzImLmxhbmRsb3Jkcy5wcm90b2NvbC5MaXN0'
    'RnJpZW5kc1JlcXVlc3RIAFISbGlzdEZyaWVuZHNSZXF1ZXN0ElQKEmFkZF9mcmllbmRfcmVxdW'
    'VzdBgYIAEoCzIkLmxhbmRsb3Jkcy5wcm90b2NvbC5BZGRGcmllbmRSZXF1ZXN0SABSEGFkZEZy'
    'aWVuZFJlcXVlc3QSXQoVaW52aXRlX3BsYXllcl9yZXF1ZXN0GBkgASgLMicubGFuZGxvcmRzLn'
    'Byb3RvY29sLkludml0ZVBsYXllclJlcXVlc3RIAFITaW52aXRlUGxheWVyUmVxdWVzdBJ5Ch9y'
    'ZXNwb25kX3Jvb21faW52aXRhdGlvbl9yZXF1ZXN0GBogASgLMjAubGFuZGxvcmRzLnByb3RvY2'
    '9sLlJlc3BvbmRSb29tSW52aXRhdGlvblJlcXVlc3RIAFIccmVzcG9uZFJvb21JbnZpdGF0aW9u'
    'UmVxdWVzdBJUChJsZWF2ZV9yb29tX3JlcXVlc3QYGyABKAsyJC5sYW5kbG9yZHMucHJvdG9jb2'
    'wuTGVhdmVSb29tUmVxdWVzdEgAUhBsZWF2ZVJvb21SZXF1ZXN0EmMKF3VwZGF0ZV9uaWNrbmFt'
    'ZV9yZXF1ZXN0GBwgASgLMikubGFuZGxvcmRzLnByb3RvY29sLlVwZGF0ZU5pY2tuYW1lUmVxdW'
    'VzdEgAUhV1cGRhdGVOaWNrbmFtZVJlcXVlc3QSdgoecmVzcG9uZF9mcmllbmRfcmVxdWVzdF9y'
    'ZXF1ZXN0GB0gASgLMi8ubGFuZGxvcmRzLnByb3RvY29sLlJlc3BvbmRGcmllbmRSZXF1ZXN0Um'
    'VxdWVzdEgAUhtyZXNwb25kRnJpZW5kUmVxdWVzdFJlcXVlc3QSXQoVZGVsZXRlX2ZyaWVuZF9y'
    'ZXF1ZXN0GB4gASgLMicubGFuZGxvcmRzLnByb3RvY29sLkRlbGV0ZUZyaWVuZFJlcXVlc3RIAF'
    'ITZGVsZXRlRnJpZW5kUmVxdWVzdBJjChdjaGFuZ2VfcGFzc3dvcmRfcmVxdWVzdBgfIAEoCzIp'
    'LmxhbmRsb3Jkcy5wcm90b2NvbC5DaGFuZ2VQYXNzd29yZFJlcXVlc3RIAFIVY2hhbmdlUGFzc3'
    'dvcmRSZXF1ZXN0EmoKGmZldGNoX3N5c3RlbV9zdGF0c19yZXF1ZXN0GCAgASgLMisubGFuZGxv'
    'cmRzLnByb3RvY29sLkZldGNoU3lzdGVtU3RhdHNSZXF1ZXN0SABSF2ZldGNoU3lzdGVtU3RhdH'
    'NSZXF1ZXN0En0KIWNsYWltX3N1cHBvcnRfbGlrZV9yZXdhcmRfcmVxdWVzdBghIAEoCzIxLmxh'
    'bmRsb3Jkcy5wcm90b2NvbC5DbGFpbVN1cHBvcnRMaWtlUmV3YXJkUmVxdWVzdEgAUh1jbGFpbV'
    'N1cHBvcnRMaWtlUmV3YXJkUmVxdWVzdBJtChtzdWJtaXRfc3VwcG9ydF9saWtlX3JlcXVlc3QY'
    'IiABKAsyLC5sYW5kbG9yZHMucHJvdG9jb2wuU3VibWl0U3VwcG9ydExpa2VSZXF1ZXN0SABSGH'
    'N1Ym1pdFN1cHBvcnRMaWtlUmVxdWVzdEIJCgdwYXlsb2Fk');

@$core.Deprecated('Use serverMessageDescriptor instead')
const ServerMessage$json = {
  '1': 'ServerMessage',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {
      '1': 'register_response',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RegisterResponse',
      '9': 0,
      '10': 'registerResponse'
    },
    {
      '1': 'login_response',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.LoginResponse',
      '9': 0,
      '10': 'loginResponse'
    },
    {
      '1': 'match_response',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.MatchResponse',
      '9': 0,
      '10': 'matchResponse'
    },
    {
      '1': 'match_found_push',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.MatchFoundPush',
      '9': 0,
      '10': 'matchFoundPush'
    },
    {
      '1': 'room_snapshot',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RoomSnapshot',
      '9': 0,
      '10': 'roomSnapshot'
    },
    {
      '1': 'operation_response',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.OperationResponse',
      '9': 0,
      '10': 'operationResponse'
    },
    {
      '1': 'error_response',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ErrorResponse',
      '9': 0,
      '10': 'errorResponse'
    },
    {
      '1': 'heartbeat_response',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.HeartbeatResponse',
      '9': 0,
      '10': 'heartbeatResponse'
    },
    {
      '1': 'reset_password_response',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ResetPasswordResponse',
      '9': 0,
      '10': 'resetPasswordResponse'
    },
    {
      '1': 'list_friends_response',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ListFriendsResponse',
      '9': 0,
      '10': 'listFriendsResponse'
    },
    {
      '1': 'add_friend_response',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.AddFriendResponse',
      '9': 0,
      '10': 'addFriendResponse'
    },
    {
      '1': 'invite_player_response',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.InvitePlayerResponse',
      '9': 0,
      '10': 'invitePlayerResponse'
    },
    {
      '1': 'room_invitation_push',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RoomInvitationPush',
      '9': 0,
      '10': 'roomInvitationPush'
    },
    {
      '1': 'respond_room_invitation_response',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RespondRoomInvitationResponse',
      '9': 0,
      '10': 'respondRoomInvitationResponse'
    },
    {
      '1': 'room_invitation_result_push',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RoomInvitationResultPush',
      '9': 0,
      '10': 'roomInvitationResultPush'
    },
    {
      '1': 'update_nickname_response',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.UpdateNicknameResponse',
      '9': 0,
      '10': 'updateNicknameResponse'
    },
    {
      '1': 'respond_friend_request_response',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.RespondFriendRequestResponse',
      '9': 0,
      '10': 'respondFriendRequestResponse'
    },
    {
      '1': 'delete_friend_response',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.DeleteFriendResponse',
      '9': 0,
      '10': 'deleteFriendResponse'
    },
    {
      '1': 'friend_center_push',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FriendCenterPush',
      '9': 0,
      '10': 'friendCenterPush'
    },
    {
      '1': 'change_password_response',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ChangePasswordResponse',
      '9': 0,
      '10': 'changePasswordResponse'
    },
    {
      '1': 'fetch_system_stats_response',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.FetchSystemStatsResponse',
      '9': 0,
      '10': 'fetchSystemStatsResponse'
    },
    {
      '1': 'claim_support_like_reward_response',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.ClaimSupportLikeRewardResponse',
      '9': 0,
      '10': 'claimSupportLikeRewardResponse'
    },
    {
      '1': 'submit_support_like_response',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.landlords.protocol.SubmitSupportLikeResponse',
      '9': 0,
      '10': 'submitSupportLikeResponse'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `ServerMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverMessageDescriptor = $convert.base64Decode(
    'Cg1TZXJ2ZXJNZXNzYWdlEh0KCnJlcXVlc3RfaWQYASABKAlSCXJlcXVlc3RJZBJTChFyZWdpc3'
    'Rlcl9yZXNwb25zZRgKIAEoCzIkLmxhbmRsb3Jkcy5wcm90b2NvbC5SZWdpc3RlclJlc3BvbnNl'
    'SABSEHJlZ2lzdGVyUmVzcG9uc2USSgoObG9naW5fcmVzcG9uc2UYCyABKAsyIS5sYW5kbG9yZH'
    'MucHJvdG9jb2wuTG9naW5SZXNwb25zZUgAUg1sb2dpblJlc3BvbnNlEkoKDm1hdGNoX3Jlc3Bv'
    'bnNlGAwgASgLMiEubGFuZGxvcmRzLnByb3RvY29sLk1hdGNoUmVzcG9uc2VIAFINbWF0Y2hSZX'
    'Nwb25zZRJOChBtYXRjaF9mb3VuZF9wdXNoGA0gASgLMiIubGFuZGxvcmRzLnByb3RvY29sLk1h'
    'dGNoRm91bmRQdXNoSABSDm1hdGNoRm91bmRQdXNoEkcKDXJvb21fc25hcHNob3QYDiABKAsyIC'
    '5sYW5kbG9yZHMucHJvdG9jb2wuUm9vbVNuYXBzaG90SABSDHJvb21TbmFwc2hvdBJWChJvcGVy'
    'YXRpb25fcmVzcG9uc2UYDyABKAsyJS5sYW5kbG9yZHMucHJvdG9jb2wuT3BlcmF0aW9uUmVzcG'
    '9uc2VIAFIRb3BlcmF0aW9uUmVzcG9uc2USSgoOZXJyb3JfcmVzcG9uc2UYECABKAsyIS5sYW5k'
    'bG9yZHMucHJvdG9jb2wuRXJyb3JSZXNwb25zZUgAUg1lcnJvclJlc3BvbnNlElYKEmhlYXJ0Ym'
    'VhdF9yZXNwb25zZRgRIAEoCzIlLmxhbmRsb3Jkcy5wcm90b2NvbC5IZWFydGJlYXRSZXNwb25z'
    'ZUgAUhFoZWFydGJlYXRSZXNwb25zZRJjChdyZXNldF9wYXNzd29yZF9yZXNwb25zZRgSIAEoCz'
    'IpLmxhbmRsb3Jkcy5wcm90b2NvbC5SZXNldFBhc3N3b3JkUmVzcG9uc2VIAFIVcmVzZXRQYXNz'
    'd29yZFJlc3BvbnNlEl0KFWxpc3RfZnJpZW5kc19yZXNwb25zZRgTIAEoCzInLmxhbmRsb3Jkcy'
    '5wcm90b2NvbC5MaXN0RnJpZW5kc1Jlc3BvbnNlSABSE2xpc3RGcmllbmRzUmVzcG9uc2USVwoT'
    'YWRkX2ZyaWVuZF9yZXNwb25zZRgUIAEoCzIlLmxhbmRsb3Jkcy5wcm90b2NvbC5BZGRGcmllbm'
    'RSZXNwb25zZUgAUhFhZGRGcmllbmRSZXNwb25zZRJgChZpbnZpdGVfcGxheWVyX3Jlc3BvbnNl'
    'GBUgASgLMigubGFuZGxvcmRzLnByb3RvY29sLkludml0ZVBsYXllclJlc3BvbnNlSABSFGludm'
    'l0ZVBsYXllclJlc3BvbnNlEloKFHJvb21faW52aXRhdGlvbl9wdXNoGBYgASgLMiYubGFuZGxv'
    'cmRzLnByb3RvY29sLlJvb21JbnZpdGF0aW9uUHVzaEgAUhJyb29tSW52aXRhdGlvblB1c2gSfA'
    'ogcmVzcG9uZF9yb29tX2ludml0YXRpb25fcmVzcG9uc2UYFyABKAsyMS5sYW5kbG9yZHMucHJv'
    'dG9jb2wuUmVzcG9uZFJvb21JbnZpdGF0aW9uUmVzcG9uc2VIAFIdcmVzcG9uZFJvb21JbnZpdG'
    'F0aW9uUmVzcG9uc2USbQobcm9vbV9pbnZpdGF0aW9uX3Jlc3VsdF9wdXNoGBggASgLMiwubGFu'
    'ZGxvcmRzLnByb3RvY29sLlJvb21JbnZpdGF0aW9uUmVzdWx0UHVzaEgAUhhyb29tSW52aXRhdG'
    'lvblJlc3VsdFB1c2gSZgoYdXBkYXRlX25pY2tuYW1lX3Jlc3BvbnNlGBkgASgLMioubGFuZGxv'
    'cmRzLnByb3RvY29sLlVwZGF0ZU5pY2tuYW1lUmVzcG9uc2VIAFIWdXBkYXRlTmlja25hbWVSZX'
    'Nwb25zZRJ5Ch9yZXNwb25kX2ZyaWVuZF9yZXF1ZXN0X3Jlc3BvbnNlGBogASgLMjAubGFuZGxv'
    'cmRzLnByb3RvY29sLlJlc3BvbmRGcmllbmRSZXF1ZXN0UmVzcG9uc2VIAFIccmVzcG9uZEZyaW'
    'VuZFJlcXVlc3RSZXNwb25zZRJgChZkZWxldGVfZnJpZW5kX3Jlc3BvbnNlGBsgASgLMigubGFu'
    'ZGxvcmRzLnByb3RvY29sLkRlbGV0ZUZyaWVuZFJlc3BvbnNlSABSFGRlbGV0ZUZyaWVuZFJlc3'
    'BvbnNlElQKEmZyaWVuZF9jZW50ZXJfcHVzaBgcIAEoCzIkLmxhbmRsb3Jkcy5wcm90b2NvbC5G'
    'cmllbmRDZW50ZXJQdXNoSABSEGZyaWVuZENlbnRlclB1c2gSZgoYY2hhbmdlX3Bhc3N3b3JkX3'
    'Jlc3BvbnNlGB0gASgLMioubGFuZGxvcmRzLnByb3RvY29sLkNoYW5nZVBhc3N3b3JkUmVzcG9u'
    'c2VIAFIWY2hhbmdlUGFzc3dvcmRSZXNwb25zZRJtChtmZXRjaF9zeXN0ZW1fc3RhdHNfcmVzcG'
    '9uc2UYHiABKAsyLC5sYW5kbG9yZHMucHJvdG9jb2wuRmV0Y2hTeXN0ZW1TdGF0c1Jlc3BvbnNl'
    'SABSGGZldGNoU3lzdGVtU3RhdHNSZXNwb25zZRKAAQoiY2xhaW1fc3VwcG9ydF9saWtlX3Jld2'
    'FyZF9yZXNwb25zZRgfIAEoCzIyLmxhbmRsb3Jkcy5wcm90b2NvbC5DbGFpbVN1cHBvcnRMaWtl'
    'UmV3YXJkUmVzcG9uc2VIAFIeY2xhaW1TdXBwb3J0TGlrZVJld2FyZFJlc3BvbnNlEnAKHHN1Ym'
    '1pdF9zdXBwb3J0X2xpa2VfcmVzcG9uc2UYICABKAsyLS5sYW5kbG9yZHMucHJvdG9jb2wuU3Vi'
    'bWl0U3VwcG9ydExpa2VSZXNwb25zZUgAUhlzdWJtaXRTdXBwb3J0TGlrZVJlc3BvbnNlQgkKB3'
    'BheWxvYWQ=');
