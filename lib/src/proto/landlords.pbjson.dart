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
    {'1': 'ROOM_PHASE_WAITING', '2': 1},
    {'1': 'ROOM_PHASE_PLAYING', '2': 2},
    {'1': 'ROOM_PHASE_FINISHED', '2': 3},
  ],
};

/// Descriptor for `RoomPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List roomPhaseDescriptor = $convert.base64Decode(
    'CglSb29tUGhhc2USGgoWUk9PTV9QSEFTRV9VTlNQRUNJRklFRBAAEhYKElJPT01fUEhBU0VfV0'
    'FJVElORxABEhYKElJPT01fUEhBU0VfUExBWUlORxACEhcKE1JPT01fUEhBU0VfRklOSVNIRUQQ'
    'Aw==');

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

@$core.Deprecated('Use userProfileDescriptor instead')
const UserProfile$json = {
  '1': 'UserProfile',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'total_score', '3': 3, '4': 1, '5': 5, '10': 'totalScore'},
  ],
};

/// Descriptor for `UserProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userProfileDescriptor = $convert.base64Decode(
    'CgtVc2VyUHJvZmlsZRIXCgd1c2VyX2lkGAEgASgJUgZ1c2VySWQSGgoIdXNlcm5hbWUYAiABKA'
    'lSCHVzZXJuYW1lEh8KC3RvdGFsX3Njb3JlGAMgASgFUgp0b3RhbFNjb3Jl');

@$core.Deprecated('Use registerRequestDescriptor instead')
const RegisterRequest$json = {
  '1': 'RegisterRequest',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `RegisterRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerRequestDescriptor = $convert.base64Decode(
    'Cg9SZWdpc3RlclJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3'
    'JkGAIgASgJUghwYXNzd29yZA==');

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
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGA'
    'IgASgJUghwYXNzd29yZA==');

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
  ],
};

/// Descriptor for `MatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List matchRequestDescriptor = $convert.base64Decode(
    'CgxNYXRjaFJlcXVlc3QSMQoEbW9kZRgBIAEoDjIdLmxhbmRsb3Jkcy5wcm90b2NvbC5NYXRjaE'
    '1vZGVSBG1vZGU=');

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
  ],
};

/// Descriptor for `RoomPlayer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List roomPlayerDescriptor = $convert.base64Decode(
    'CgpSb29tUGxheWVyEhsKCXBsYXllcl9pZBgBIAEoCVIIcGxheWVySWQSIQoMZGlzcGxheV9uYW'
    '1lGAIgASgJUgtkaXNwbGF5TmFtZRIVCgZpc19ib3QYAyABKAhSBWlzQm90EjIKBHJvbGUYBCAB'
    'KA4yHi5sYW5kbG9yZHMucHJvdG9jb2wuUGxheWVyUm9sZVIEcm9sZRIdCgpjYXJkc19sZWZ0GA'
    'UgASgFUgljYXJkc0xlZnQSHwoLcm91bmRfc2NvcmUYBiABKAVSCnJvdW5kU2NvcmU=');

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
    'FsGA8gASgFUgp0dXJuU2VyaWFs');

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
    'JlcXVlc3RIAFIQaGVhcnRiZWF0UmVxdWVzdEIJCgdwYXlsb2Fk');

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
    'ZUgAUhFoZWFydGJlYXRSZXNwb25zZUIJCgdwYXlsb2Fk');
