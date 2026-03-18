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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'landlords.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'landlords.pbenum.dart';

class UserProfile extends $pb.GeneratedMessage {
  factory UserProfile({
    $core.String? userId,
    $core.String? username,
    $core.int? totalScore,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (totalScore != null) result.totalScore = totalScore;
    return result;
  }

  UserProfile._();

  factory UserProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserProfile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aI(3, _omitFieldNames ? '' : 'totalScore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfile copyWith(void Function(UserProfile) updates) =>
      super.copyWith((message) => updates(message as UserProfile))
          as UserProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserProfile create() => UserProfile._();
  @$core.override
  UserProfile createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserProfile>(create);
  static UserProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get totalScore => $_getIZ(2);
  @$pb.TagNumber(3)
  set totalScore($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalScore() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalScore() => $_clearField(3);
}

class RegisterRequest extends $pb.GeneratedMessage {
  factory RegisterRequest({
    $core.String? username,
    $core.String? password,
  }) {
    final result = create();
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  RegisterRequest._();

  factory RegisterRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRequest copyWith(void Function(RegisterRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterRequest))
          as RegisterRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterRequest create() => RegisterRequest._();
  @$core.override
  RegisterRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterRequest>(create);
  static RegisterRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

class RegisterResponse extends $pb.GeneratedMessage {
  factory RegisterResponse({
    $core.bool? success,
    $core.String? message,
    UserProfile? profile,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (profile != null) result.profile = profile;
    return result;
  }

  RegisterResponse._();

  factory RegisterResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<UserProfile>(3, _omitFieldNames ? '' : 'profile',
        subBuilder: UserProfile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResponse copyWith(void Function(RegisterResponse) updates) =>
      super.copyWith((message) => updates(message as RegisterResponse))
          as RegisterResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterResponse create() => RegisterResponse._();
  @$core.override
  RegisterResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterResponse>(create);
  static RegisterResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  UserProfile get profile => $_getN(2);
  @$pb.TagNumber(3)
  set profile(UserProfile value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProfile() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfile() => $_clearField(3);
  @$pb.TagNumber(3)
  UserProfile ensureProfile() => $_ensure(2);
}

class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? username,
    $core.String? password,
  }) {
    final result = create();
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginRequest create() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginRequest>(create);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    $core.bool? success,
    $core.String? message,
    UserProfile? profile,
    $core.String? sessionToken,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (profile != null) result.profile = profile;
    if (sessionToken != null) result.sessionToken = sessionToken;
    return result;
  }

  LoginResponse._();

  factory LoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<UserProfile>(3, _omitFieldNames ? '' : 'profile',
        subBuilder: UserProfile.create)
    ..aOS(4, _omitFieldNames ? '' : 'sessionToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginResponse create() => LoginResponse._();
  @$core.override
  LoginResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginResponse>(create);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  UserProfile get profile => $_getN(2);
  @$pb.TagNumber(3)
  set profile(UserProfile value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProfile() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfile() => $_clearField(3);
  @$pb.TagNumber(3)
  UserProfile ensureProfile() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get sessionToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set sessionToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSessionToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearSessionToken() => $_clearField(4);
}

class MatchRequest extends $pb.GeneratedMessage {
  factory MatchRequest({
    MatchMode? mode,
    BotDifficulty? botDifficulty,
  }) {
    final result = create();
    if (mode != null) result.mode = mode;
    if (botDifficulty != null) result.botDifficulty = botDifficulty;
    return result;
  }

  MatchRequest._();

  factory MatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MatchRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aE<MatchMode>(1, _omitFieldNames ? '' : 'mode',
        enumValues: MatchMode.values)
    ..aE<BotDifficulty>(2, _omitFieldNames ? '' : 'botDifficulty',
        protoName: 'bot_difficulty', enumValues: BotDifficulty.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MatchRequest copyWith(void Function(MatchRequest) updates) =>
      super.copyWith((message) => updates(message as MatchRequest))
          as MatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MatchRequest create() => MatchRequest._();
  @$core.override
  MatchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MatchRequest>(create);
  static MatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  MatchMode get mode => $_getN(0);
  @$pb.TagNumber(1)
  set mode(MatchMode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);

  @$pb.TagNumber(2)
  BotDifficulty get botDifficulty => $_getN(1);
  @$pb.TagNumber(2)
  set botDifficulty(BotDifficulty value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBotDifficulty() => $_has(1);
  @$pb.TagNumber(2)
  void clearBotDifficulty() => $_clearField(2);
}

class MatchResponse extends $pb.GeneratedMessage {
  factory MatchResponse({
    $core.bool? accepted,
    $core.String? message,
  }) {
    final result = create();
    if (accepted != null) result.accepted = accepted;
    if (message != null) result.message = message;
    return result;
  }

  MatchResponse._();

  factory MatchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MatchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MatchResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'accepted')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MatchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MatchResponse copyWith(void Function(MatchResponse) updates) =>
      super.copyWith((message) => updates(message as MatchResponse))
          as MatchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MatchResponse create() => MatchResponse._();
  @$core.override
  MatchResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MatchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MatchResponse>(create);
  static MatchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get accepted => $_getBF(0);
  @$pb.TagNumber(1)
  set accepted($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccepted() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccepted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class MatchFoundPush extends $pb.GeneratedMessage {
  factory MatchFoundPush({
    $core.String? roomId,
    MatchMode? mode,
    $core.Iterable<RoomPlayer>? players,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (mode != null) result.mode = mode;
    if (players != null) result.players.addAll(players);
    return result;
  }

  MatchFoundPush._();

  factory MatchFoundPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MatchFoundPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MatchFoundPush',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aE<MatchMode>(2, _omitFieldNames ? '' : 'mode',
        enumValues: MatchMode.values)
    ..pPM<RoomPlayer>(3, _omitFieldNames ? '' : 'players',
        subBuilder: RoomPlayer.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MatchFoundPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MatchFoundPush copyWith(void Function(MatchFoundPush) updates) =>
      super.copyWith((message) => updates(message as MatchFoundPush))
          as MatchFoundPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MatchFoundPush create() => MatchFoundPush._();
  @$core.override
  MatchFoundPush createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MatchFoundPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MatchFoundPush>(create);
  static MatchFoundPush? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  MatchMode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(MatchMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<RoomPlayer> get players => $_getList(2);
}

class RoomPlayer extends $pb.GeneratedMessage {
  factory RoomPlayer({
    $core.String? playerId,
    $core.String? displayName,
    $core.bool? isBot,
    PlayerRole? role,
    $core.int? cardsLeft,
    $core.int? roundScore,
  }) {
    final result = create();
    if (playerId != null) result.playerId = playerId;
    if (displayName != null) result.displayName = displayName;
    if (isBot != null) result.isBot = isBot;
    if (role != null) result.role = role;
    if (cardsLeft != null) result.cardsLeft = cardsLeft;
    if (roundScore != null) result.roundScore = roundScore;
    return result;
  }

  RoomPlayer._();

  factory RoomPlayer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoomPlayer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomPlayer',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'playerId')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOB(3, _omitFieldNames ? '' : 'isBot')
    ..aE<PlayerRole>(4, _omitFieldNames ? '' : 'role',
        enumValues: PlayerRole.values)
    ..aI(5, _omitFieldNames ? '' : 'cardsLeft')
    ..aI(6, _omitFieldNames ? '' : 'roundScore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomPlayer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomPlayer copyWith(void Function(RoomPlayer) updates) =>
      super.copyWith((message) => updates(message as RoomPlayer)) as RoomPlayer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomPlayer create() => RoomPlayer._();
  @$core.override
  RoomPlayer createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoomPlayer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomPlayer>(create);
  static RoomPlayer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get playerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set playerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlayerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlayerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isBot => $_getBF(2);
  @$pb.TagNumber(3)
  set isBot($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsBot() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsBot() => $_clearField(3);

  @$pb.TagNumber(4)
  PlayerRole get role => $_getN(3);
  @$pb.TagNumber(4)
  set role(PlayerRole value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasRole() => $_has(3);
  @$pb.TagNumber(4)
  void clearRole() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get cardsLeft => $_getIZ(4);
  @$pb.TagNumber(5)
  set cardsLeft($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCardsLeft() => $_has(4);
  @$pb.TagNumber(5)
  void clearCardsLeft() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get roundScore => $_getIZ(5);
  @$pb.TagNumber(6)
  set roundScore($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRoundScore() => $_has(5);
  @$pb.TagNumber(6)
  void clearRoundScore() => $_clearField(6);
}

class Card extends $pb.GeneratedMessage {
  factory Card({
    $core.String? id,
    $core.String? rank,
    $core.String? suit,
    $core.int? value,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (rank != null) result.rank = rank;
    if (suit != null) result.suit = suit;
    if (value != null) result.value = value;
    return result;
  }

  Card._();

  factory Card.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Card.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Card',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'rank')
    ..aOS(3, _omitFieldNames ? '' : 'suit')
    ..aI(4, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Card clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Card copyWith(void Function(Card) updates) =>
      super.copyWith((message) => updates(message as Card)) as Card;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Card create() => Card._();
  @$core.override
  Card createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Card getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Card>(create);
  static Card? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get rank => $_getSZ(1);
  @$pb.TagNumber(2)
  set rank($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRank() => $_has(1);
  @$pb.TagNumber(2)
  void clearRank() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get suit => $_getSZ(2);
  @$pb.TagNumber(3)
  set suit($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSuit() => $_has(2);
  @$pb.TagNumber(3)
  void clearSuit() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get value => $_getIZ(3);
  @$pb.TagNumber(4)
  set value($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearValue() => $_clearField(4);
}

class CardCounterEntry extends $pb.GeneratedMessage {
  factory CardCounterEntry({
    $core.String? rank,
    $core.int? remaining,
  }) {
    final result = create();
    if (rank != null) result.rank = rank;
    if (remaining != null) result.remaining = remaining;
    return result;
  }

  CardCounterEntry._();

  factory CardCounterEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CardCounterEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CardCounterEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'rank')
    ..aI(2, _omitFieldNames ? '' : 'remaining')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardCounterEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CardCounterEntry copyWith(void Function(CardCounterEntry) updates) =>
      super.copyWith((message) => updates(message as CardCounterEntry))
          as CardCounterEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CardCounterEntry create() => CardCounterEntry._();
  @$core.override
  CardCounterEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CardCounterEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CardCounterEntry>(create);
  static CardCounterEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get rank => $_getSZ(0);
  @$pb.TagNumber(1)
  set rank($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRank() => $_has(0);
  @$pb.TagNumber(1)
  void clearRank() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get remaining => $_getIZ(1);
  @$pb.TagNumber(2)
  set remaining($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRemaining() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemaining() => $_clearField(2);
}

class TableAction extends $pb.GeneratedMessage {
  factory TableAction({
    $core.String? actionId,
    $core.String? playerId,
    ActionType? actionType,
    $core.Iterable<Card>? cards,
    $core.String? pattern,
    $fixnum.Int64? timestampMs,
    PatternType? patternType,
  }) {
    final result = create();
    if (actionId != null) result.actionId = actionId;
    if (playerId != null) result.playerId = playerId;
    if (actionType != null) result.actionType = actionType;
    if (cards != null) result.cards.addAll(cards);
    if (pattern != null) result.pattern = pattern;
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (patternType != null) result.patternType = patternType;
    return result;
  }

  TableAction._();

  factory TableAction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TableAction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TableAction',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'actionId')
    ..aOS(2, _omitFieldNames ? '' : 'playerId')
    ..aE<ActionType>(3, _omitFieldNames ? '' : 'actionType',
        enumValues: ActionType.values)
    ..pPM<Card>(4, _omitFieldNames ? '' : 'cards', subBuilder: Card.create)
    ..aOS(5, _omitFieldNames ? '' : 'pattern')
    ..aInt64(6, _omitFieldNames ? '' : 'timestampMs')
    ..aE<PatternType>(7, _omitFieldNames ? '' : 'patternType',
        enumValues: PatternType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableAction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TableAction copyWith(void Function(TableAction) updates) =>
      super.copyWith((message) => updates(message as TableAction))
          as TableAction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TableAction create() => TableAction._();
  @$core.override
  TableAction createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TableAction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TableAction>(create);
  static TableAction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get actionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set actionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearActionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get playerId => $_getSZ(1);
  @$pb.TagNumber(2)
  set playerId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayerId() => $_clearField(2);

  @$pb.TagNumber(3)
  ActionType get actionType => $_getN(2);
  @$pb.TagNumber(3)
  set actionType(ActionType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasActionType() => $_has(2);
  @$pb.TagNumber(3)
  void clearActionType() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<Card> get cards => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get pattern => $_getSZ(4);
  @$pb.TagNumber(5)
  set pattern($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPattern() => $_has(4);
  @$pb.TagNumber(5)
  void clearPattern() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get timestampMs => $_getI64(5);
  @$pb.TagNumber(6)
  set timestampMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTimestampMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearTimestampMs() => $_clearField(6);

  @$pb.TagNumber(7)
  PatternType get patternType => $_getN(6);
  @$pb.TagNumber(7)
  set patternType(PatternType value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPatternType() => $_has(6);
  @$pb.TagNumber(7)
  void clearPatternType() => $_clearField(7);
}

class RoomSnapshot extends $pb.GeneratedMessage {
  factory RoomSnapshot({
    $core.String? roomId,
    RoomPhase? phase,
    MatchMode? mode,
    $core.Iterable<RoomPlayer>? players,
    $core.Iterable<Card>? selfCards,
    $core.Iterable<Card>? landlordCards,
    $core.Iterable<TableAction>? recentActions,
    $core.String? currentTurnPlayerId,
    $core.String? statusText,
    $core.Iterable<CardCounterEntry>? cardCounter,
    $core.int? baseScore,
    $core.int? multiplier,
    $core.int? currentRoundScore,
    $core.bool? springTriggered,
    $core.int? turnSerial,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (phase != null) result.phase = phase;
    if (mode != null) result.mode = mode;
    if (players != null) result.players.addAll(players);
    if (selfCards != null) result.selfCards.addAll(selfCards);
    if (landlordCards != null) result.landlordCards.addAll(landlordCards);
    if (recentActions != null) result.recentActions.addAll(recentActions);
    if (currentTurnPlayerId != null)
      result.currentTurnPlayerId = currentTurnPlayerId;
    if (statusText != null) result.statusText = statusText;
    if (cardCounter != null) result.cardCounter.addAll(cardCounter);
    if (baseScore != null) result.baseScore = baseScore;
    if (multiplier != null) result.multiplier = multiplier;
    if (currentRoundScore != null) result.currentRoundScore = currentRoundScore;
    if (springTriggered != null) result.springTriggered = springTriggered;
    if (turnSerial != null) result.turnSerial = turnSerial;
    return result;
  }

  RoomSnapshot._();

  factory RoomSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoomSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aE<RoomPhase>(2, _omitFieldNames ? '' : 'phase',
        enumValues: RoomPhase.values)
    ..aE<MatchMode>(3, _omitFieldNames ? '' : 'mode',
        enumValues: MatchMode.values)
    ..pPM<RoomPlayer>(4, _omitFieldNames ? '' : 'players',
        subBuilder: RoomPlayer.create)
    ..pPM<Card>(5, _omitFieldNames ? '' : 'selfCards', subBuilder: Card.create)
    ..pPM<Card>(6, _omitFieldNames ? '' : 'landlordCards',
        subBuilder: Card.create)
    ..pPM<TableAction>(7, _omitFieldNames ? '' : 'recentActions',
        subBuilder: TableAction.create)
    ..aOS(8, _omitFieldNames ? '' : 'currentTurnPlayerId')
    ..aOS(9, _omitFieldNames ? '' : 'statusText')
    ..pPM<CardCounterEntry>(10, _omitFieldNames ? '' : 'cardCounter',
        subBuilder: CardCounterEntry.create)
    ..aI(11, _omitFieldNames ? '' : 'baseScore')
    ..aI(12, _omitFieldNames ? '' : 'multiplier')
    ..aI(13, _omitFieldNames ? '' : 'currentRoundScore')
    ..aOB(14, _omitFieldNames ? '' : 'springTriggered')
    ..aI(15, _omitFieldNames ? '' : 'turnSerial')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomSnapshot copyWith(void Function(RoomSnapshot) updates) =>
      super.copyWith((message) => updates(message as RoomSnapshot))
          as RoomSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomSnapshot create() => RoomSnapshot._();
  @$core.override
  RoomSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoomSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomSnapshot>(create);
  static RoomSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  RoomPhase get phase => $_getN(1);
  @$pb.TagNumber(2)
  set phase(RoomPhase value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPhase() => $_has(1);
  @$pb.TagNumber(2)
  void clearPhase() => $_clearField(2);

  @$pb.TagNumber(3)
  MatchMode get mode => $_getN(2);
  @$pb.TagNumber(3)
  set mode(MatchMode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMode() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<RoomPlayer> get players => $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<Card> get selfCards => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<Card> get landlordCards => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<TableAction> get recentActions => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get currentTurnPlayerId => $_getSZ(7);
  @$pb.TagNumber(8)
  set currentTurnPlayerId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasCurrentTurnPlayerId() => $_has(7);
  @$pb.TagNumber(8)
  void clearCurrentTurnPlayerId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get statusText => $_getSZ(8);
  @$pb.TagNumber(9)
  set statusText($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasStatusText() => $_has(8);
  @$pb.TagNumber(9)
  void clearStatusText() => $_clearField(9);

  @$pb.TagNumber(10)
  $pb.PbList<CardCounterEntry> get cardCounter => $_getList(9);

  @$pb.TagNumber(11)
  $core.int get baseScore => $_getIZ(10);
  @$pb.TagNumber(11)
  set baseScore($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasBaseScore() => $_has(10);
  @$pb.TagNumber(11)
  void clearBaseScore() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get multiplier => $_getIZ(11);
  @$pb.TagNumber(12)
  set multiplier($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMultiplier() => $_has(11);
  @$pb.TagNumber(12)
  void clearMultiplier() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get currentRoundScore => $_getIZ(12);
  @$pb.TagNumber(13)
  set currentRoundScore($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCurrentRoundScore() => $_has(12);
  @$pb.TagNumber(13)
  void clearCurrentRoundScore() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get springTriggered => $_getBF(13);
  @$pb.TagNumber(14)
  set springTriggered($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasSpringTriggered() => $_has(13);
  @$pb.TagNumber(14)
  void clearSpringTriggered() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get turnSerial => $_getIZ(14);
  @$pb.TagNumber(15)
  set turnSerial($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasTurnSerial() => $_has(14);
  @$pb.TagNumber(15)
  void clearTurnSerial() => $_clearField(15);
}

class PlayCardsRequest extends $pb.GeneratedMessage {
  factory PlayCardsRequest({
    $core.String? roomId,
    $core.Iterable<$core.String>? cardIds,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (cardIds != null) result.cardIds.addAll(cardIds);
    return result;
  }

  PlayCardsRequest._();

  factory PlayCardsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlayCardsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayCardsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..pPS(2, _omitFieldNames ? '' : 'cardIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayCardsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayCardsRequest copyWith(void Function(PlayCardsRequest) updates) =>
      super.copyWith((message) => updates(message as PlayCardsRequest))
          as PlayCardsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayCardsRequest create() => PlayCardsRequest._();
  @$core.override
  PlayCardsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlayCardsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayCardsRequest>(create);
  static PlayCardsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get cardIds => $_getList(1);
}

class PassRequest extends $pb.GeneratedMessage {
  factory PassRequest({
    $core.String? roomId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    return result;
  }

  PassRequest._();

  factory PassRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PassRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PassRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PassRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PassRequest copyWith(void Function(PassRequest) updates) =>
      super.copyWith((message) => updates(message as PassRequest))
          as PassRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PassRequest create() => PassRequest._();
  @$core.override
  PassRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PassRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PassRequest>(create);
  static PassRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);
}

class ReconnectRequest extends $pb.GeneratedMessage {
  factory ReconnectRequest({
    $core.String? roomId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    return result;
  }

  ReconnectRequest._();

  factory ReconnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReconnectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReconnectRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReconnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReconnectRequest copyWith(void Function(ReconnectRequest) updates) =>
      super.copyWith((message) => updates(message as ReconnectRequest))
          as ReconnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReconnectRequest create() => ReconnectRequest._();
  @$core.override
  ReconnectRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReconnectRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReconnectRequest>(create);
  static ReconnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);
}

class HeartbeatRequest extends $pb.GeneratedMessage {
  factory HeartbeatRequest({
    $fixnum.Int64? clientTimeMs,
  }) {
    final result = create();
    if (clientTimeMs != null) result.clientTimeMs = clientTimeMs;
    return result;
  }

  HeartbeatRequest._();

  factory HeartbeatRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeartbeatRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeartbeatRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'clientTimeMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatRequest copyWith(void Function(HeartbeatRequest) updates) =>
      super.copyWith((message) => updates(message as HeartbeatRequest))
          as HeartbeatRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeartbeatRequest create() => HeartbeatRequest._();
  @$core.override
  HeartbeatRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeartbeatRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeartbeatRequest>(create);
  static HeartbeatRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get clientTimeMs => $_getI64(0);
  @$pb.TagNumber(1)
  set clientTimeMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClientTimeMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientTimeMs() => $_clearField(1);
}

class HeartbeatResponse extends $pb.GeneratedMessage {
  factory HeartbeatResponse({
    $fixnum.Int64? serverTimeMs,
  }) {
    final result = create();
    if (serverTimeMs != null) result.serverTimeMs = serverTimeMs;
    return result;
  }

  HeartbeatResponse._();

  factory HeartbeatResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HeartbeatResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeartbeatResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'serverTimeMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeartbeatResponse copyWith(void Function(HeartbeatResponse) updates) =>
      super.copyWith((message) => updates(message as HeartbeatResponse))
          as HeartbeatResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HeartbeatResponse create() => HeartbeatResponse._();
  @$core.override
  HeartbeatResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HeartbeatResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HeartbeatResponse>(create);
  static HeartbeatResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get serverTimeMs => $_getI64(0);
  @$pb.TagNumber(1)
  set serverTimeMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerTimeMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerTimeMs() => $_clearField(1);
}

class OperationResponse extends $pb.GeneratedMessage {
  factory OperationResponse({
    $core.bool? success,
    $core.String? message,
    RoomSnapshot? snapshot,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  OperationResponse._();

  factory OperationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperationResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<RoomSnapshot>(3, _omitFieldNames ? '' : 'snapshot',
        subBuilder: RoomSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperationResponse copyWith(void Function(OperationResponse) updates) =>
      super.copyWith((message) => updates(message as OperationResponse))
          as OperationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperationResponse create() => OperationResponse._();
  @$core.override
  OperationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperationResponse>(create);
  static OperationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  RoomSnapshot get snapshot => $_getN(2);
  @$pb.TagNumber(3)
  set snapshot(RoomSnapshot value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSnapshot() => $_has(2);
  @$pb.TagNumber(3)
  void clearSnapshot() => $_clearField(3);
  @$pb.TagNumber(3)
  RoomSnapshot ensureSnapshot() => $_ensure(2);
}

class ErrorResponse extends $pb.GeneratedMessage {
  factory ErrorResponse({
    ErrorCode? code,
    $core.String? message,
  }) {
    final result = create();
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  ErrorResponse._();

  factory ErrorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ErrorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ErrorResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aE<ErrorCode>(1, _omitFieldNames ? '' : 'code',
        enumValues: ErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ErrorResponse copyWith(void Function(ErrorResponse) updates) =>
      super.copyWith((message) => updates(message as ErrorResponse))
          as ErrorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ErrorResponse create() => ErrorResponse._();
  @$core.override
  ErrorResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ErrorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ErrorResponse>(create);
  static ErrorResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(ErrorCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

enum ClientMessage_Payload {
  registerRequest,
  loginRequest,
  matchRequest,
  playCardsRequest,
  passRequest,
  reconnectRequest,
  heartbeatRequest,
  notSet
}

class ClientMessage extends $pb.GeneratedMessage {
  factory ClientMessage({
    $core.String? requestId,
    $core.String? sessionToken,
    RegisterRequest? registerRequest,
    LoginRequest? loginRequest,
    MatchRequest? matchRequest,
    PlayCardsRequest? playCardsRequest,
    PassRequest? passRequest,
    ReconnectRequest? reconnectRequest,
    HeartbeatRequest? heartbeatRequest,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (sessionToken != null) result.sessionToken = sessionToken;
    if (registerRequest != null) result.registerRequest = registerRequest;
    if (loginRequest != null) result.loginRequest = loginRequest;
    if (matchRequest != null) result.matchRequest = matchRequest;
    if (playCardsRequest != null) result.playCardsRequest = playCardsRequest;
    if (passRequest != null) result.passRequest = passRequest;
    if (reconnectRequest != null) result.reconnectRequest = reconnectRequest;
    if (heartbeatRequest != null) result.heartbeatRequest = heartbeatRequest;
    return result;
  }

  ClientMessage._();

  factory ClientMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClientMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ClientMessage_Payload>
      _ClientMessage_PayloadByTag = {
    10: ClientMessage_Payload.registerRequest,
    11: ClientMessage_Payload.loginRequest,
    12: ClientMessage_Payload.matchRequest,
    13: ClientMessage_Payload.playCardsRequest,
    14: ClientMessage_Payload.passRequest,
    15: ClientMessage_Payload.reconnectRequest,
    16: ClientMessage_Payload.heartbeatRequest,
    0: ClientMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15, 16])
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOS(2, _omitFieldNames ? '' : 'sessionToken')
    ..aOM<RegisterRequest>(10, _omitFieldNames ? '' : 'registerRequest',
        subBuilder: RegisterRequest.create)
    ..aOM<LoginRequest>(11, _omitFieldNames ? '' : 'loginRequest',
        subBuilder: LoginRequest.create)
    ..aOM<MatchRequest>(12, _omitFieldNames ? '' : 'matchRequest',
        subBuilder: MatchRequest.create)
    ..aOM<PlayCardsRequest>(13, _omitFieldNames ? '' : 'playCardsRequest',
        subBuilder: PlayCardsRequest.create)
    ..aOM<PassRequest>(14, _omitFieldNames ? '' : 'passRequest',
        subBuilder: PassRequest.create)
    ..aOM<ReconnectRequest>(15, _omitFieldNames ? '' : 'reconnectRequest',
        subBuilder: ReconnectRequest.create)
    ..aOM<HeartbeatRequest>(16, _omitFieldNames ? '' : 'heartbeatRequest',
        subBuilder: HeartbeatRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClientMessage copyWith(void Function(ClientMessage) updates) =>
      super.copyWith((message) => updates(message as ClientMessage))
          as ClientMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientMessage create() => ClientMessage._();
  @$core.override
  ClientMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClientMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClientMessage>(create);
  static ClientMessage? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  ClientMessage_Payload whichPayload() =>
      _ClientMessage_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionToken() => $_clearField(2);

  @$pb.TagNumber(10)
  RegisterRequest get registerRequest => $_getN(2);
  @$pb.TagNumber(10)
  set registerRequest(RegisterRequest value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRegisterRequest() => $_has(2);
  @$pb.TagNumber(10)
  void clearRegisterRequest() => $_clearField(10);
  @$pb.TagNumber(10)
  RegisterRequest ensureRegisterRequest() => $_ensure(2);

  @$pb.TagNumber(11)
  LoginRequest get loginRequest => $_getN(3);
  @$pb.TagNumber(11)
  set loginRequest(LoginRequest value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasLoginRequest() => $_has(3);
  @$pb.TagNumber(11)
  void clearLoginRequest() => $_clearField(11);
  @$pb.TagNumber(11)
  LoginRequest ensureLoginRequest() => $_ensure(3);

  @$pb.TagNumber(12)
  MatchRequest get matchRequest => $_getN(4);
  @$pb.TagNumber(12)
  set matchRequest(MatchRequest value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasMatchRequest() => $_has(4);
  @$pb.TagNumber(12)
  void clearMatchRequest() => $_clearField(12);
  @$pb.TagNumber(12)
  MatchRequest ensureMatchRequest() => $_ensure(4);

  @$pb.TagNumber(13)
  PlayCardsRequest get playCardsRequest => $_getN(5);
  @$pb.TagNumber(13)
  set playCardsRequest(PlayCardsRequest value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasPlayCardsRequest() => $_has(5);
  @$pb.TagNumber(13)
  void clearPlayCardsRequest() => $_clearField(13);
  @$pb.TagNumber(13)
  PlayCardsRequest ensurePlayCardsRequest() => $_ensure(5);

  @$pb.TagNumber(14)
  PassRequest get passRequest => $_getN(6);
  @$pb.TagNumber(14)
  set passRequest(PassRequest value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasPassRequest() => $_has(6);
  @$pb.TagNumber(14)
  void clearPassRequest() => $_clearField(14);
  @$pb.TagNumber(14)
  PassRequest ensurePassRequest() => $_ensure(6);

  @$pb.TagNumber(15)
  ReconnectRequest get reconnectRequest => $_getN(7);
  @$pb.TagNumber(15)
  set reconnectRequest(ReconnectRequest value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasReconnectRequest() => $_has(7);
  @$pb.TagNumber(15)
  void clearReconnectRequest() => $_clearField(15);
  @$pb.TagNumber(15)
  ReconnectRequest ensureReconnectRequest() => $_ensure(7);

  @$pb.TagNumber(16)
  HeartbeatRequest get heartbeatRequest => $_getN(8);
  @$pb.TagNumber(16)
  set heartbeatRequest(HeartbeatRequest value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasHeartbeatRequest() => $_has(8);
  @$pb.TagNumber(16)
  void clearHeartbeatRequest() => $_clearField(16);
  @$pb.TagNumber(16)
  HeartbeatRequest ensureHeartbeatRequest() => $_ensure(8);
}

enum ServerMessage_Payload {
  registerResponse,
  loginResponse,
  matchResponse,
  matchFoundPush,
  roomSnapshot,
  operationResponse,
  errorResponse,
  heartbeatResponse,
  notSet
}

class ServerMessage extends $pb.GeneratedMessage {
  factory ServerMessage({
    $core.String? requestId,
    RegisterResponse? registerResponse,
    LoginResponse? loginResponse,
    MatchResponse? matchResponse,
    MatchFoundPush? matchFoundPush,
    RoomSnapshot? roomSnapshot,
    OperationResponse? operationResponse,
    ErrorResponse? errorResponse,
    HeartbeatResponse? heartbeatResponse,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (registerResponse != null) result.registerResponse = registerResponse;
    if (loginResponse != null) result.loginResponse = loginResponse;
    if (matchResponse != null) result.matchResponse = matchResponse;
    if (matchFoundPush != null) result.matchFoundPush = matchFoundPush;
    if (roomSnapshot != null) result.roomSnapshot = roomSnapshot;
    if (operationResponse != null) result.operationResponse = operationResponse;
    if (errorResponse != null) result.errorResponse = errorResponse;
    if (heartbeatResponse != null) result.heartbeatResponse = heartbeatResponse;
    return result;
  }

  ServerMessage._();

  factory ServerMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ServerMessage_Payload>
      _ServerMessage_PayloadByTag = {
    10: ServerMessage_Payload.registerResponse,
    11: ServerMessage_Payload.loginResponse,
    12: ServerMessage_Payload.matchResponse,
    13: ServerMessage_Payload.matchFoundPush,
    14: ServerMessage_Payload.roomSnapshot,
    15: ServerMessage_Payload.operationResponse,
    16: ServerMessage_Payload.errorResponse,
    17: ServerMessage_Payload.heartbeatResponse,
    0: ServerMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15, 16, 17])
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOM<RegisterResponse>(10, _omitFieldNames ? '' : 'registerResponse',
        subBuilder: RegisterResponse.create)
    ..aOM<LoginResponse>(11, _omitFieldNames ? '' : 'loginResponse',
        subBuilder: LoginResponse.create)
    ..aOM<MatchResponse>(12, _omitFieldNames ? '' : 'matchResponse',
        subBuilder: MatchResponse.create)
    ..aOM<MatchFoundPush>(13, _omitFieldNames ? '' : 'matchFoundPush',
        subBuilder: MatchFoundPush.create)
    ..aOM<RoomSnapshot>(14, _omitFieldNames ? '' : 'roomSnapshot',
        subBuilder: RoomSnapshot.create)
    ..aOM<OperationResponse>(15, _omitFieldNames ? '' : 'operationResponse',
        subBuilder: OperationResponse.create)
    ..aOM<ErrorResponse>(16, _omitFieldNames ? '' : 'errorResponse',
        subBuilder: ErrorResponse.create)
    ..aOM<HeartbeatResponse>(17, _omitFieldNames ? '' : 'heartbeatResponse',
        subBuilder: HeartbeatResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerMessage copyWith(void Function(ServerMessage) updates) =>
      super.copyWith((message) => updates(message as ServerMessage))
          as ServerMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerMessage create() => ServerMessage._();
  @$core.override
  ServerMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerMessage>(create);
  static ServerMessage? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  ServerMessage_Payload whichPayload() =>
      _ServerMessage_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(10)
  RegisterResponse get registerResponse => $_getN(1);
  @$pb.TagNumber(10)
  set registerResponse(RegisterResponse value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRegisterResponse() => $_has(1);
  @$pb.TagNumber(10)
  void clearRegisterResponse() => $_clearField(10);
  @$pb.TagNumber(10)
  RegisterResponse ensureRegisterResponse() => $_ensure(1);

  @$pb.TagNumber(11)
  LoginResponse get loginResponse => $_getN(2);
  @$pb.TagNumber(11)
  set loginResponse(LoginResponse value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasLoginResponse() => $_has(2);
  @$pb.TagNumber(11)
  void clearLoginResponse() => $_clearField(11);
  @$pb.TagNumber(11)
  LoginResponse ensureLoginResponse() => $_ensure(2);

  @$pb.TagNumber(12)
  MatchResponse get matchResponse => $_getN(3);
  @$pb.TagNumber(12)
  set matchResponse(MatchResponse value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasMatchResponse() => $_has(3);
  @$pb.TagNumber(12)
  void clearMatchResponse() => $_clearField(12);
  @$pb.TagNumber(12)
  MatchResponse ensureMatchResponse() => $_ensure(3);

  @$pb.TagNumber(13)
  MatchFoundPush get matchFoundPush => $_getN(4);
  @$pb.TagNumber(13)
  set matchFoundPush(MatchFoundPush value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasMatchFoundPush() => $_has(4);
  @$pb.TagNumber(13)
  void clearMatchFoundPush() => $_clearField(13);
  @$pb.TagNumber(13)
  MatchFoundPush ensureMatchFoundPush() => $_ensure(4);

  @$pb.TagNumber(14)
  RoomSnapshot get roomSnapshot => $_getN(5);
  @$pb.TagNumber(14)
  set roomSnapshot(RoomSnapshot value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasRoomSnapshot() => $_has(5);
  @$pb.TagNumber(14)
  void clearRoomSnapshot() => $_clearField(14);
  @$pb.TagNumber(14)
  RoomSnapshot ensureRoomSnapshot() => $_ensure(5);

  @$pb.TagNumber(15)
  OperationResponse get operationResponse => $_getN(6);
  @$pb.TagNumber(15)
  set operationResponse(OperationResponse value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasOperationResponse() => $_has(6);
  @$pb.TagNumber(15)
  void clearOperationResponse() => $_clearField(15);
  @$pb.TagNumber(15)
  OperationResponse ensureOperationResponse() => $_ensure(6);

  @$pb.TagNumber(16)
  ErrorResponse get errorResponse => $_getN(7);
  @$pb.TagNumber(16)
  set errorResponse(ErrorResponse value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasErrorResponse() => $_has(7);
  @$pb.TagNumber(16)
  void clearErrorResponse() => $_clearField(16);
  @$pb.TagNumber(16)
  ErrorResponse ensureErrorResponse() => $_ensure(7);

  @$pb.TagNumber(17)
  HeartbeatResponse get heartbeatResponse => $_getN(8);
  @$pb.TagNumber(17)
  set heartbeatResponse(HeartbeatResponse value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasHeartbeatResponse() => $_has(8);
  @$pb.TagNumber(17)
  void clearHeartbeatResponse() => $_clearField(17);
  @$pb.TagNumber(17)
  HeartbeatResponse ensureHeartbeatResponse() => $_ensure(8);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
