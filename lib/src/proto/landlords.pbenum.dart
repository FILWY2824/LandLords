// This is a generated file - do not edit.
//
// Generated from landlords.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode ERROR_CODE_UNSPECIFIED =
      ErrorCode._(0, _omitEnumNames ? '' : 'ERROR_CODE_UNSPECIFIED');
  static const ErrorCode ERROR_CODE_INVALID_REQUEST =
      ErrorCode._(1, _omitEnumNames ? '' : 'ERROR_CODE_INVALID_REQUEST');
  static const ErrorCode ERROR_CODE_AUTH_FAILED =
      ErrorCode._(2, _omitEnumNames ? '' : 'ERROR_CODE_AUTH_FAILED');
  static const ErrorCode ERROR_CODE_ALREADY_EXISTS =
      ErrorCode._(3, _omitEnumNames ? '' : 'ERROR_CODE_ALREADY_EXISTS');
  static const ErrorCode ERROR_CODE_NOT_FOUND =
      ErrorCode._(4, _omitEnumNames ? '' : 'ERROR_CODE_NOT_FOUND');
  static const ErrorCode ERROR_CODE_MATCH_STATE_INVALID =
      ErrorCode._(5, _omitEnumNames ? '' : 'ERROR_CODE_MATCH_STATE_INVALID');
  static const ErrorCode ERROR_CODE_GAME_STATE_INVALID =
      ErrorCode._(6, _omitEnumNames ? '' : 'ERROR_CODE_GAME_STATE_INVALID');
  static const ErrorCode ERROR_CODE_INTERNAL =
      ErrorCode._(7, _omitEnumNames ? '' : 'ERROR_CODE_INTERNAL');

  static const $core.List<ErrorCode> values = <ErrorCode>[
    ERROR_CODE_UNSPECIFIED,
    ERROR_CODE_INVALID_REQUEST,
    ERROR_CODE_AUTH_FAILED,
    ERROR_CODE_ALREADY_EXISTS,
    ERROR_CODE_NOT_FOUND,
    ERROR_CODE_MATCH_STATE_INVALID,
    ERROR_CODE_GAME_STATE_INVALID,
    ERROR_CODE_INTERNAL,
  ];

  static final $core.List<ErrorCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ErrorCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ErrorCode._(super.value, super.name);
}

class MatchMode extends $pb.ProtobufEnum {
  static const MatchMode MATCH_MODE_UNSPECIFIED =
      MatchMode._(0, _omitEnumNames ? '' : 'MATCH_MODE_UNSPECIFIED');
  static const MatchMode MATCH_MODE_VS_BOT =
      MatchMode._(1, _omitEnumNames ? '' : 'MATCH_MODE_VS_BOT');
  static const MatchMode MATCH_MODE_PVP =
      MatchMode._(2, _omitEnumNames ? '' : 'MATCH_MODE_PVP');

  static const $core.List<MatchMode> values = <MatchMode>[
    MATCH_MODE_UNSPECIFIED,
    MATCH_MODE_VS_BOT,
    MATCH_MODE_PVP,
  ];

  static final $core.List<MatchMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static MatchMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MatchMode._(super.value, super.name);
}

class BotDifficulty extends $pb.ProtobufEnum {
  static const BotDifficulty BOT_DIFFICULTY_UNSPECIFIED =
      BotDifficulty._(0, _omitEnumNames ? '' : 'BOT_DIFFICULTY_UNSPECIFIED');
  static const BotDifficulty BOT_DIFFICULTY_EASY =
      BotDifficulty._(1, _omitEnumNames ? '' : 'BOT_DIFFICULTY_EASY');
  static const BotDifficulty BOT_DIFFICULTY_NORMAL =
      BotDifficulty._(2, _omitEnumNames ? '' : 'BOT_DIFFICULTY_NORMAL');
  static const BotDifficulty BOT_DIFFICULTY_HARD =
      BotDifficulty._(3, _omitEnumNames ? '' : 'BOT_DIFFICULTY_HARD');

  static const $core.List<BotDifficulty> values = <BotDifficulty>[
    BOT_DIFFICULTY_UNSPECIFIED,
    BOT_DIFFICULTY_EASY,
    BOT_DIFFICULTY_NORMAL,
    BOT_DIFFICULTY_HARD,
  ];

  static final $core.List<BotDifficulty?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static BotDifficulty? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BotDifficulty._(super.value, super.name);
}

class PlayerRole extends $pb.ProtobufEnum {
  static const PlayerRole PLAYER_ROLE_UNSPECIFIED =
      PlayerRole._(0, _omitEnumNames ? '' : 'PLAYER_ROLE_UNSPECIFIED');
  static const PlayerRole PLAYER_ROLE_FARMER =
      PlayerRole._(1, _omitEnumNames ? '' : 'PLAYER_ROLE_FARMER');
  static const PlayerRole PLAYER_ROLE_LANDLORD =
      PlayerRole._(2, _omitEnumNames ? '' : 'PLAYER_ROLE_LANDLORD');

  static const $core.List<PlayerRole> values = <PlayerRole>[
    PLAYER_ROLE_UNSPECIFIED,
    PLAYER_ROLE_FARMER,
    PLAYER_ROLE_LANDLORD,
  ];

  static final $core.List<PlayerRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PlayerRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlayerRole._(super.value, super.name);
}

class RoomPhase extends $pb.ProtobufEnum {
  static const RoomPhase ROOM_PHASE_UNSPECIFIED =
      RoomPhase._(0, _omitEnumNames ? '' : 'ROOM_PHASE_UNSPECIFIED');
  static const RoomPhase ROOM_PHASE_WAITING =
      RoomPhase._(1, _omitEnumNames ? '' : 'ROOM_PHASE_WAITING');
  static const RoomPhase ROOM_PHASE_PLAYING =
      RoomPhase._(2, _omitEnumNames ? '' : 'ROOM_PHASE_PLAYING');
  static const RoomPhase ROOM_PHASE_FINISHED =
      RoomPhase._(3, _omitEnumNames ? '' : 'ROOM_PHASE_FINISHED');

  static const $core.List<RoomPhase> values = <RoomPhase>[
    ROOM_PHASE_UNSPECIFIED,
    ROOM_PHASE_WAITING,
    ROOM_PHASE_PLAYING,
    ROOM_PHASE_FINISHED,
  ];

  static final $core.List<RoomPhase?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static RoomPhase? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RoomPhase._(super.value, super.name);
}

class ActionType extends $pb.ProtobufEnum {
  static const ActionType ACTION_TYPE_UNSPECIFIED =
      ActionType._(0, _omitEnumNames ? '' : 'ACTION_TYPE_UNSPECIFIED');
  static const ActionType ACTION_TYPE_PLAY =
      ActionType._(1, _omitEnumNames ? '' : 'ACTION_TYPE_PLAY');
  static const ActionType ACTION_TYPE_PASS =
      ActionType._(2, _omitEnumNames ? '' : 'ACTION_TYPE_PASS');

  static const $core.List<ActionType> values = <ActionType>[
    ACTION_TYPE_UNSPECIFIED,
    ACTION_TYPE_PLAY,
    ACTION_TYPE_PASS,
  ];

  static final $core.List<ActionType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ActionType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ActionType._(super.value, super.name);
}

class PatternType extends $pb.ProtobufEnum {
  static const PatternType PATTERN_TYPE_UNSPECIFIED =
      PatternType._(0, _omitEnumNames ? '' : 'PATTERN_TYPE_UNSPECIFIED');
  static const PatternType PATTERN_TYPE_SINGLE =
      PatternType._(1, _omitEnumNames ? '' : 'PATTERN_TYPE_SINGLE');
  static const PatternType PATTERN_TYPE_PAIR =
      PatternType._(2, _omitEnumNames ? '' : 'PATTERN_TYPE_PAIR');
  static const PatternType PATTERN_TYPE_TRIPLE =
      PatternType._(3, _omitEnumNames ? '' : 'PATTERN_TYPE_TRIPLE');
  static const PatternType PATTERN_TYPE_TRIPLE_WITH_SINGLE =
      PatternType._(4, _omitEnumNames ? '' : 'PATTERN_TYPE_TRIPLE_WITH_SINGLE');
  static const PatternType PATTERN_TYPE_TRIPLE_WITH_PAIR =
      PatternType._(5, _omitEnumNames ? '' : 'PATTERN_TYPE_TRIPLE_WITH_PAIR');
  static const PatternType PATTERN_TYPE_STRAIGHT =
      PatternType._(6, _omitEnumNames ? '' : 'PATTERN_TYPE_STRAIGHT');
  static const PatternType PATTERN_TYPE_STRAIGHT_PAIR =
      PatternType._(7, _omitEnumNames ? '' : 'PATTERN_TYPE_STRAIGHT_PAIR');
  static const PatternType PATTERN_TYPE_AIRPLANE =
      PatternType._(8, _omitEnumNames ? '' : 'PATTERN_TYPE_AIRPLANE');
  static const PatternType PATTERN_TYPE_AIRPLANE_WITH_SINGLE = PatternType._(
      9, _omitEnumNames ? '' : 'PATTERN_TYPE_AIRPLANE_WITH_SINGLE');
  static const PatternType PATTERN_TYPE_AIRPLANE_WITH_PAIR = PatternType._(
      10, _omitEnumNames ? '' : 'PATTERN_TYPE_AIRPLANE_WITH_PAIR');
  static const PatternType PATTERN_TYPE_BOMB =
      PatternType._(11, _omitEnumNames ? '' : 'PATTERN_TYPE_BOMB');
  static const PatternType PATTERN_TYPE_FOUR_WITH_TWO_SINGLES = PatternType._(
      12, _omitEnumNames ? '' : 'PATTERN_TYPE_FOUR_WITH_TWO_SINGLES');
  static const PatternType PATTERN_TYPE_FOUR_WITH_TWO_PAIRS = PatternType._(
      13, _omitEnumNames ? '' : 'PATTERN_TYPE_FOUR_WITH_TWO_PAIRS');
  static const PatternType PATTERN_TYPE_ROCKET =
      PatternType._(14, _omitEnumNames ? '' : 'PATTERN_TYPE_ROCKET');

  static const $core.List<PatternType> values = <PatternType>[
    PATTERN_TYPE_UNSPECIFIED,
    PATTERN_TYPE_SINGLE,
    PATTERN_TYPE_PAIR,
    PATTERN_TYPE_TRIPLE,
    PATTERN_TYPE_TRIPLE_WITH_SINGLE,
    PATTERN_TYPE_TRIPLE_WITH_PAIR,
    PATTERN_TYPE_STRAIGHT,
    PATTERN_TYPE_STRAIGHT_PAIR,
    PATTERN_TYPE_AIRPLANE,
    PATTERN_TYPE_AIRPLANE_WITH_SINGLE,
    PATTERN_TYPE_AIRPLANE_WITH_PAIR,
    PATTERN_TYPE_BOMB,
    PATTERN_TYPE_FOUR_WITH_TWO_SINGLES,
    PATTERN_TYPE_FOUR_WITH_TWO_PAIRS,
    PATTERN_TYPE_ROCKET,
  ];

  static final $core.List<PatternType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 14);
  static PatternType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PatternType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
