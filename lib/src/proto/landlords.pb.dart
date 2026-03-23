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
    $core.String? account,
    $core.String? nickname,
    $core.int? totalScore,
    $core.int? landlordWins,
    $core.int? landlordGames,
    $core.int? farmerWins,
    $core.int? farmerGames,
    $core.int? onlineLandlordWins,
    $core.int? onlineLandlordGames,
    $core.int? onlineFarmerWins,
    $core.int? onlineFarmerGames,
    $core.int? botLandlordWins,
    $core.int? botLandlordGames,
    $core.int? botFarmerWins,
    $core.int? botFarmerGames,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (account != null) result.account = account;
    if (nickname != null) result.nickname = nickname;
    if (totalScore != null) result.totalScore = totalScore;
    if (landlordWins != null) result.landlordWins = landlordWins;
    if (landlordGames != null) result.landlordGames = landlordGames;
    if (farmerWins != null) result.farmerWins = farmerWins;
    if (farmerGames != null) result.farmerGames = farmerGames;
    if (onlineLandlordWins != null)
      result.onlineLandlordWins = onlineLandlordWins;
    if (onlineLandlordGames != null)
      result.onlineLandlordGames = onlineLandlordGames;
    if (onlineFarmerWins != null) result.onlineFarmerWins = onlineFarmerWins;
    if (onlineFarmerGames != null) result.onlineFarmerGames = onlineFarmerGames;
    if (botLandlordWins != null) result.botLandlordWins = botLandlordWins;
    if (botLandlordGames != null) result.botLandlordGames = botLandlordGames;
    if (botFarmerWins != null) result.botFarmerWins = botFarmerWins;
    if (botFarmerGames != null) result.botFarmerGames = botFarmerGames;
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
    ..aOS(2, _omitFieldNames ? '' : 'account')
    ..aOS(3, _omitFieldNames ? '' : 'nickname')
    ..aI(4, _omitFieldNames ? '' : 'totalScore')
    ..aI(5, _omitFieldNames ? '' : 'landlordWins')
    ..aI(6, _omitFieldNames ? '' : 'landlordGames')
    ..aI(7, _omitFieldNames ? '' : 'farmerWins')
    ..aI(8, _omitFieldNames ? '' : 'farmerGames')
    ..aI(9, _omitFieldNames ? '' : 'onlineLandlordWins')
    ..aI(10, _omitFieldNames ? '' : 'onlineLandlordGames')
    ..aI(11, _omitFieldNames ? '' : 'onlineFarmerWins')
    ..aI(12, _omitFieldNames ? '' : 'onlineFarmerGames')
    ..aI(13, _omitFieldNames ? '' : 'botLandlordWins')
    ..aI(14, _omitFieldNames ? '' : 'botLandlordGames')
    ..aI(15, _omitFieldNames ? '' : 'botFarmerWins')
    ..aI(16, _omitFieldNames ? '' : 'botFarmerGames')
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
  $core.String get account => $_getSZ(1);
  @$pb.TagNumber(2)
  set account($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nickname => $_getSZ(2);
  @$pb.TagNumber(3)
  set nickname($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNickname() => $_has(2);
  @$pb.TagNumber(3)
  void clearNickname() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get totalScore => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalScore($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalScore() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalScore() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get landlordWins => $_getIZ(4);
  @$pb.TagNumber(5)
  set landlordWins($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLandlordWins() => $_has(4);
  @$pb.TagNumber(5)
  void clearLandlordWins() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get landlordGames => $_getIZ(5);
  @$pb.TagNumber(6)
  set landlordGames($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLandlordGames() => $_has(5);
  @$pb.TagNumber(6)
  void clearLandlordGames() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get farmerWins => $_getIZ(6);
  @$pb.TagNumber(7)
  set farmerWins($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFarmerWins() => $_has(6);
  @$pb.TagNumber(7)
  void clearFarmerWins() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get farmerGames => $_getIZ(7);
  @$pb.TagNumber(8)
  set farmerGames($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFarmerGames() => $_has(7);
  @$pb.TagNumber(8)
  void clearFarmerGames() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get onlineLandlordWins => $_getIZ(8);
  @$pb.TagNumber(9)
  set onlineLandlordWins($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOnlineLandlordWins() => $_has(8);
  @$pb.TagNumber(9)
  void clearOnlineLandlordWins() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get onlineLandlordGames => $_getIZ(9);
  @$pb.TagNumber(10)
  set onlineLandlordGames($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasOnlineLandlordGames() => $_has(9);
  @$pb.TagNumber(10)
  void clearOnlineLandlordGames() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get onlineFarmerWins => $_getIZ(10);
  @$pb.TagNumber(11)
  set onlineFarmerWins($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasOnlineFarmerWins() => $_has(10);
  @$pb.TagNumber(11)
  void clearOnlineFarmerWins() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get onlineFarmerGames => $_getIZ(11);
  @$pb.TagNumber(12)
  set onlineFarmerGames($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasOnlineFarmerGames() => $_has(11);
  @$pb.TagNumber(12)
  void clearOnlineFarmerGames() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get botLandlordWins => $_getIZ(12);
  @$pb.TagNumber(13)
  set botLandlordWins($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasBotLandlordWins() => $_has(12);
  @$pb.TagNumber(13)
  void clearBotLandlordWins() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get botLandlordGames => $_getIZ(13);
  @$pb.TagNumber(14)
  set botLandlordGames($core.int value) => $_setSignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasBotLandlordGames() => $_has(13);
  @$pb.TagNumber(14)
  void clearBotLandlordGames() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.int get botFarmerWins => $_getIZ(14);
  @$pb.TagNumber(15)
  set botFarmerWins($core.int value) => $_setSignedInt32(14, value);
  @$pb.TagNumber(15)
  $core.bool hasBotFarmerWins() => $_has(14);
  @$pb.TagNumber(15)
  void clearBotFarmerWins() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.int get botFarmerGames => $_getIZ(15);
  @$pb.TagNumber(16)
  set botFarmerGames($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasBotFarmerGames() => $_has(15);
  @$pb.TagNumber(16)
  void clearBotFarmerGames() => $_clearField(16);
}

class OnlineUser extends $pb.GeneratedMessage {
  factory OnlineUser({
    $core.String? userId,
    $core.String? account,
    $core.String? nickname,
    $core.bool? online,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (account != null) result.account = account;
    if (nickname != null) result.nickname = nickname;
    if (online != null) result.online = online;
    return result;
  }

  OnlineUser._();

  factory OnlineUser.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OnlineUser.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OnlineUser',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'account')
    ..aOS(3, _omitFieldNames ? '' : 'nickname')
    ..aOB(4, _omitFieldNames ? '' : 'online')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OnlineUser clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OnlineUser copyWith(void Function(OnlineUser) updates) =>
      super.copyWith((message) => updates(message as OnlineUser)) as OnlineUser;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OnlineUser create() => OnlineUser._();
  @$core.override
  OnlineUser createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OnlineUser getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OnlineUser>(create);
  static OnlineUser? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get account => $_getSZ(1);
  @$pb.TagNumber(2)
  set account($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nickname => $_getSZ(2);
  @$pb.TagNumber(3)
  set nickname($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNickname() => $_has(2);
  @$pb.TagNumber(3)
  void clearNickname() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get online => $_getBF(3);
  @$pb.TagNumber(4)
  set online($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOnline() => $_has(3);
  @$pb.TagNumber(4)
  void clearOnline() => $_clearField(4);
}

class FriendRequestEntry extends $pb.GeneratedMessage {
  factory FriendRequestEntry({
    $core.String? requestId,
    $core.String? requesterUserId,
    $core.String? requesterAccount,
    $core.String? requesterNickname,
    $core.String? receiverUserId,
    $core.String? receiverAccount,
    $core.String? receiverNickname,
    FriendRequestStatus? status,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? updatedAtMs,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (requesterUserId != null) result.requesterUserId = requesterUserId;
    if (requesterAccount != null) result.requesterAccount = requesterAccount;
    if (requesterNickname != null) result.requesterNickname = requesterNickname;
    if (receiverUserId != null) result.receiverUserId = receiverUserId;
    if (receiverAccount != null) result.receiverAccount = receiverAccount;
    if (receiverNickname != null) result.receiverNickname = receiverNickname;
    if (status != null) result.status = status;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (updatedAtMs != null) result.updatedAtMs = updatedAtMs;
    return result;
  }

  FriendRequestEntry._();

  factory FriendRequestEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FriendRequestEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FriendRequestEntry',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOS(2, _omitFieldNames ? '' : 'requesterUserId')
    ..aOS(3, _omitFieldNames ? '' : 'requesterAccount')
    ..aOS(4, _omitFieldNames ? '' : 'requesterNickname')
    ..aOS(5, _omitFieldNames ? '' : 'receiverUserId')
    ..aOS(6, _omitFieldNames ? '' : 'receiverAccount')
    ..aOS(7, _omitFieldNames ? '' : 'receiverNickname')
    ..aE<FriendRequestStatus>(8, _omitFieldNames ? '' : 'status',
        enumValues: FriendRequestStatus.values)
    ..aInt64(9, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(10, _omitFieldNames ? '' : 'updatedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendRequestEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendRequestEntry copyWith(void Function(FriendRequestEntry) updates) =>
      super.copyWith((message) => updates(message as FriendRequestEntry))
          as FriendRequestEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FriendRequestEntry create() => FriendRequestEntry._();
  @$core.override
  FriendRequestEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FriendRequestEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FriendRequestEntry>(create);
  static FriendRequestEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get requesterUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requesterUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequesterUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequesterUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get requesterAccount => $_getSZ(2);
  @$pb.TagNumber(3)
  set requesterAccount($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRequesterAccount() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequesterAccount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get requesterNickname => $_getSZ(3);
  @$pb.TagNumber(4)
  set requesterNickname($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequesterNickname() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequesterNickname() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get receiverUserId => $_getSZ(4);
  @$pb.TagNumber(5)
  set receiverUserId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReceiverUserId() => $_has(4);
  @$pb.TagNumber(5)
  void clearReceiverUserId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get receiverAccount => $_getSZ(5);
  @$pb.TagNumber(6)
  set receiverAccount($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReceiverAccount() => $_has(5);
  @$pb.TagNumber(6)
  void clearReceiverAccount() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get receiverNickname => $_getSZ(6);
  @$pb.TagNumber(7)
  set receiverNickname($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReceiverNickname() => $_has(6);
  @$pb.TagNumber(7)
  void clearReceiverNickname() => $_clearField(7);

  @$pb.TagNumber(8)
  FriendRequestStatus get status => $_getN(7);
  @$pb.TagNumber(8)
  set status(FriendRequestStatus value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasStatus() => $_has(7);
  @$pb.TagNumber(8)
  void clearStatus() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get createdAtMs => $_getI64(8);
  @$pb.TagNumber(9)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCreatedAtMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearCreatedAtMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get updatedAtMs => $_getI64(9);
  @$pb.TagNumber(10)
  set updatedAtMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUpdatedAtMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearUpdatedAtMs() => $_clearField(10);
}

class FriendCenterSnapshot extends $pb.GeneratedMessage {
  factory FriendCenterSnapshot({
    $core.Iterable<OnlineUser>? friends,
    $core.Iterable<FriendRequestEntry>? pendingRequests,
    $core.Iterable<FriendRequestEntry>? historyRequests,
    $core.int? pendingRequestCount,
  }) {
    final result = create();
    if (friends != null) result.friends.addAll(friends);
    if (pendingRequests != null) result.pendingRequests.addAll(pendingRequests);
    if (historyRequests != null) result.historyRequests.addAll(historyRequests);
    if (pendingRequestCount != null)
      result.pendingRequestCount = pendingRequestCount;
    return result;
  }

  FriendCenterSnapshot._();

  factory FriendCenterSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FriendCenterSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FriendCenterSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..pPM<OnlineUser>(1, _omitFieldNames ? '' : 'friends',
        subBuilder: OnlineUser.create)
    ..pPM<FriendRequestEntry>(2, _omitFieldNames ? '' : 'pendingRequests',
        subBuilder: FriendRequestEntry.create)
    ..pPM<FriendRequestEntry>(3, _omitFieldNames ? '' : 'historyRequests',
        subBuilder: FriendRequestEntry.create)
    ..aI(4, _omitFieldNames ? '' : 'pendingRequestCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendCenterSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendCenterSnapshot copyWith(void Function(FriendCenterSnapshot) updates) =>
      super.copyWith((message) => updates(message as FriendCenterSnapshot))
          as FriendCenterSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FriendCenterSnapshot create() => FriendCenterSnapshot._();
  @$core.override
  FriendCenterSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FriendCenterSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FriendCenterSnapshot>(create);
  static FriendCenterSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OnlineUser> get friends => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<FriendRequestEntry> get pendingRequests => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<FriendRequestEntry> get historyRequests => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get pendingRequestCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set pendingRequestCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPendingRequestCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearPendingRequestCount() => $_clearField(4);
}

class SystemStatsSnapshot extends $pb.GeneratedMessage {
  factory SystemStatsSnapshot({
    $core.int? supportLikeCount,
  }) {
    final result = create();
    if (supportLikeCount != null) result.supportLikeCount = supportLikeCount;
    return result;
  }

  SystemStatsSnapshot._();

  factory SystemStatsSnapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SystemStatsSnapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SystemStatsSnapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'supportLikeCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemStatsSnapshot clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemStatsSnapshot copyWith(void Function(SystemStatsSnapshot) updates) =>
      super.copyWith((message) => updates(message as SystemStatsSnapshot))
          as SystemStatsSnapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SystemStatsSnapshot create() => SystemStatsSnapshot._();
  @$core.override
  SystemStatsSnapshot createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SystemStatsSnapshot getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SystemStatsSnapshot>(create);
  static SystemStatsSnapshot? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get supportLikeCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set supportLikeCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSupportLikeCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearSupportLikeCount() => $_clearField(1);
}

class RegisterRequest extends $pb.GeneratedMessage {
  factory RegisterRequest({
    $core.String? nickname,
    $core.String? account,
    $core.String? password,
  }) {
    final result = create();
    if (nickname != null) result.nickname = nickname;
    if (account != null) result.account = account;
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
    ..aOS(1, _omitFieldNames ? '' : 'nickname')
    ..aOS(2, _omitFieldNames ? '' : 'account')
    ..aOS(3, _omitFieldNames ? '' : 'password')
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
  $core.String get nickname => $_getSZ(0);
  @$pb.TagNumber(1)
  set nickname($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNickname() => $_has(0);
  @$pb.TagNumber(1)
  void clearNickname() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get account => $_getSZ(1);
  @$pb.TagNumber(2)
  set account($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);
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
    $core.String? account,
    $core.String? password,
  }) {
    final result = create();
    if (account != null) result.account = account;
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
    ..aOS(1, _omitFieldNames ? '' : 'account')
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
  $core.String get account => $_getSZ(0);
  @$pb.TagNumber(1)
  set account($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccount() => $_clearField(1);

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

class ResetPasswordRequest extends $pb.GeneratedMessage {
  factory ResetPasswordRequest({
    $core.String? account,
    $core.String? newPassword,
  }) {
    final result = create();
    if (account != null) result.account = account;
    if (newPassword != null) result.newPassword = newPassword;
    return result;
  }

  ResetPasswordRequest._();

  factory ResetPasswordRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResetPasswordRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetPasswordRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'account')
    ..aOS(2, _omitFieldNames ? '' : 'newPassword')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordRequest copyWith(void Function(ResetPasswordRequest) updates) =>
      super.copyWith((message) => updates(message as ResetPasswordRequest))
          as ResetPasswordRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResetPasswordRequest create() => ResetPasswordRequest._();
  @$core.override
  ResetPasswordRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResetPasswordRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetPasswordRequest>(create);
  static ResetPasswordRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get account => $_getSZ(0);
  @$pb.TagNumber(1)
  set account($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccount() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newPassword => $_getSZ(1);
  @$pb.TagNumber(2)
  set newPassword($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewPassword() => $_clearField(2);
}

class ResetPasswordResponse extends $pb.GeneratedMessage {
  factory ResetPasswordResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  ResetPasswordResponse._();

  factory ResetPasswordResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResetPasswordResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetPasswordResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPasswordResponse copyWith(
          void Function(ResetPasswordResponse) updates) =>
      super.copyWith((message) => updates(message as ResetPasswordResponse))
          as ResetPasswordResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResetPasswordResponse create() => ResetPasswordResponse._();
  @$core.override
  ResetPasswordResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResetPasswordResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetPasswordResponse>(create);
  static ResetPasswordResponse? _defaultInstance;

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
}

class ChangePasswordRequest extends $pb.GeneratedMessage {
  factory ChangePasswordRequest({
    $core.String? currentPassword,
    $core.String? newPassword,
  }) {
    final result = create();
    if (currentPassword != null) result.currentPassword = currentPassword;
    if (newPassword != null) result.newPassword = newPassword;
    return result;
  }

  ChangePasswordRequest._();

  factory ChangePasswordRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangePasswordRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePasswordRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'currentPassword')
    ..aOS(2, _omitFieldNames ? '' : 'newPassword')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest copyWith(
          void Function(ChangePasswordRequest) updates) =>
      super.copyWith((message) => updates(message as ChangePasswordRequest))
          as ChangePasswordRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangePasswordRequest create() => ChangePasswordRequest._();
  @$core.override
  ChangePasswordRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangePasswordRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePasswordRequest>(create);
  static ChangePasswordRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get currentPassword => $_getSZ(0);
  @$pb.TagNumber(1)
  set currentPassword($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCurrentPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearCurrentPassword() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newPassword => $_getSZ(1);
  @$pb.TagNumber(2)
  set newPassword($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewPassword() => $_clearField(2);
}

class ChangePasswordResponse extends $pb.GeneratedMessage {
  factory ChangePasswordResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  ChangePasswordResponse._();

  factory ChangePasswordResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChangePasswordResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePasswordResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordResponse copyWith(
          void Function(ChangePasswordResponse) updates) =>
      super.copyWith((message) => updates(message as ChangePasswordResponse))
          as ChangePasswordResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChangePasswordResponse create() => ChangePasswordResponse._();
  @$core.override
  ChangePasswordResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChangePasswordResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePasswordResponse>(create);
  static ChangePasswordResponse? _defaultInstance;

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
}

class UpdateNicknameRequest extends $pb.GeneratedMessage {
  factory UpdateNicknameRequest({
    $core.String? nickname,
  }) {
    final result = create();
    if (nickname != null) result.nickname = nickname;
    return result;
  }

  UpdateNicknameRequest._();

  factory UpdateNicknameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateNicknameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateNicknameRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'nickname')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNicknameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNicknameRequest copyWith(
          void Function(UpdateNicknameRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateNicknameRequest))
          as UpdateNicknameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateNicknameRequest create() => UpdateNicknameRequest._();
  @$core.override
  UpdateNicknameRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateNicknameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateNicknameRequest>(create);
  static UpdateNicknameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get nickname => $_getSZ(0);
  @$pb.TagNumber(1)
  set nickname($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNickname() => $_has(0);
  @$pb.TagNumber(1)
  void clearNickname() => $_clearField(1);
}

class UpdateNicknameResponse extends $pb.GeneratedMessage {
  factory UpdateNicknameResponse({
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

  UpdateNicknameResponse._();

  factory UpdateNicknameResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateNicknameResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateNicknameResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<UserProfile>(3, _omitFieldNames ? '' : 'profile',
        subBuilder: UserProfile.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNicknameResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateNicknameResponse copyWith(
          void Function(UpdateNicknameResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateNicknameResponse))
          as UpdateNicknameResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateNicknameResponse create() => UpdateNicknameResponse._();
  @$core.override
  UpdateNicknameResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdateNicknameResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateNicknameResponse>(create);
  static UpdateNicknameResponse? _defaultInstance;

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

class FetchSystemStatsRequest extends $pb.GeneratedMessage {
  factory FetchSystemStatsRequest() => create();

  FetchSystemStatsRequest._();

  factory FetchSystemStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchSystemStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchSystemStatsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSystemStatsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSystemStatsRequest copyWith(
          void Function(FetchSystemStatsRequest) updates) =>
      super.copyWith((message) => updates(message as FetchSystemStatsRequest))
          as FetchSystemStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchSystemStatsRequest create() => FetchSystemStatsRequest._();
  @$core.override
  FetchSystemStatsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchSystemStatsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchSystemStatsRequest>(create);
  static FetchSystemStatsRequest? _defaultInstance;
}

class FetchSystemStatsResponse extends $pb.GeneratedMessage {
  factory FetchSystemStatsResponse({
    $core.bool? success,
    $core.String? message,
    SystemStatsSnapshot? stats,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (stats != null) result.stats = stats;
    return result;
  }

  FetchSystemStatsResponse._();

  factory FetchSystemStatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FetchSystemStatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchSystemStatsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<SystemStatsSnapshot>(3, _omitFieldNames ? '' : 'stats',
        subBuilder: SystemStatsSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSystemStatsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSystemStatsResponse copyWith(
          void Function(FetchSystemStatsResponse) updates) =>
      super.copyWith((message) => updates(message as FetchSystemStatsResponse))
          as FetchSystemStatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchSystemStatsResponse create() => FetchSystemStatsResponse._();
  @$core.override
  FetchSystemStatsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FetchSystemStatsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchSystemStatsResponse>(create);
  static FetchSystemStatsResponse? _defaultInstance;

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
  SystemStatsSnapshot get stats => $_getN(2);
  @$pb.TagNumber(3)
  set stats(SystemStatsSnapshot value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStats() => $_has(2);
  @$pb.TagNumber(3)
  void clearStats() => $_clearField(3);
  @$pb.TagNumber(3)
  SystemStatsSnapshot ensureStats() => $_ensure(2);
}

class SubmitSupportLikeRequest extends $pb.GeneratedMessage {
  factory SubmitSupportLikeRequest() => create();

  SubmitSupportLikeRequest._();

  factory SubmitSupportLikeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmitSupportLikeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitSupportLikeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSupportLikeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSupportLikeRequest copyWith(
          void Function(SubmitSupportLikeRequest) updates) =>
      super.copyWith((message) => updates(message as SubmitSupportLikeRequest))
          as SubmitSupportLikeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitSupportLikeRequest create() => SubmitSupportLikeRequest._();
  @$core.override
  SubmitSupportLikeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubmitSupportLikeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitSupportLikeRequest>(create);
  static SubmitSupportLikeRequest? _defaultInstance;
}

class SubmitSupportLikeResponse extends $pb.GeneratedMessage {
  factory SubmitSupportLikeResponse({
    $core.bool? success,
    $core.String? message,
    SystemStatsSnapshot? stats,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (stats != null) result.stats = stats;
    return result;
  }

  SubmitSupportLikeResponse._();

  factory SubmitSupportLikeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SubmitSupportLikeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitSupportLikeResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<SystemStatsSnapshot>(3, _omitFieldNames ? '' : 'stats',
        subBuilder: SystemStatsSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSupportLikeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitSupportLikeResponse copyWith(
          void Function(SubmitSupportLikeResponse) updates) =>
      super.copyWith((message) => updates(message as SubmitSupportLikeResponse))
          as SubmitSupportLikeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubmitSupportLikeResponse create() => SubmitSupportLikeResponse._();
  @$core.override
  SubmitSupportLikeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SubmitSupportLikeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitSupportLikeResponse>(create);
  static SubmitSupportLikeResponse? _defaultInstance;

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
  SystemStatsSnapshot get stats => $_getN(2);
  @$pb.TagNumber(3)
  set stats(SystemStatsSnapshot value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStats() => $_has(2);
  @$pb.TagNumber(3)
  void clearStats() => $_clearField(3);
  @$pb.TagNumber(3)
  SystemStatsSnapshot ensureStats() => $_ensure(2);
}

class ClaimSupportLikeRewardRequest extends $pb.GeneratedMessage {
  factory ClaimSupportLikeRewardRequest() => create();

  ClaimSupportLikeRewardRequest._();

  factory ClaimSupportLikeRewardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClaimSupportLikeRewardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClaimSupportLikeRewardRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimSupportLikeRewardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimSupportLikeRewardRequest copyWith(
          void Function(ClaimSupportLikeRewardRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ClaimSupportLikeRewardRequest))
          as ClaimSupportLikeRewardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClaimSupportLikeRewardRequest create() =>
      ClaimSupportLikeRewardRequest._();
  @$core.override
  ClaimSupportLikeRewardRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClaimSupportLikeRewardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClaimSupportLikeRewardRequest>(create);
  static ClaimSupportLikeRewardRequest? _defaultInstance;
}

class ClaimSupportLikeRewardResponse extends $pb.GeneratedMessage {
  factory ClaimSupportLikeRewardResponse({
    $core.bool? success,
    $core.String? message,
    UserProfile? profile,
    SystemStatsSnapshot? stats,
    $core.int? rewardCoins,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (profile != null) result.profile = profile;
    if (stats != null) result.stats = stats;
    if (rewardCoins != null) result.rewardCoins = rewardCoins;
    return result;
  }

  ClaimSupportLikeRewardResponse._();

  factory ClaimSupportLikeRewardResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClaimSupportLikeRewardResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClaimSupportLikeRewardResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<UserProfile>(3, _omitFieldNames ? '' : 'profile',
        subBuilder: UserProfile.create)
    ..aOM<SystemStatsSnapshot>(4, _omitFieldNames ? '' : 'stats',
        subBuilder: SystemStatsSnapshot.create)
    ..aI(5, _omitFieldNames ? '' : 'rewardCoins')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimSupportLikeRewardResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimSupportLikeRewardResponse copyWith(
          void Function(ClaimSupportLikeRewardResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ClaimSupportLikeRewardResponse))
          as ClaimSupportLikeRewardResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClaimSupportLikeRewardResponse create() =>
      ClaimSupportLikeRewardResponse._();
  @$core.override
  ClaimSupportLikeRewardResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClaimSupportLikeRewardResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClaimSupportLikeRewardResponse>(create);
  static ClaimSupportLikeRewardResponse? _defaultInstance;

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
  SystemStatsSnapshot get stats => $_getN(3);
  @$pb.TagNumber(4)
  set stats(SystemStatsSnapshot value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStats() => $_has(3);
  @$pb.TagNumber(4)
  void clearStats() => $_clearField(4);
  @$pb.TagNumber(4)
  SystemStatsSnapshot ensureStats() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.int get rewardCoins => $_getIZ(4);
  @$pb.TagNumber(5)
  set rewardCoins($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRewardCoins() => $_has(4);
  @$pb.TagNumber(5)
  void clearRewardCoins() => $_clearField(5);
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
        enumValues: BotDifficulty.values)
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

class CreateRoomRequest extends $pb.GeneratedMessage {
  factory CreateRoomRequest() => create();

  CreateRoomRequest._();

  factory CreateRoomRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateRoomRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateRoomRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoomRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoomRequest copyWith(void Function(CreateRoomRequest) updates) =>
      super.copyWith((message) => updates(message as CreateRoomRequest))
          as CreateRoomRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateRoomRequest create() => CreateRoomRequest._();
  @$core.override
  CreateRoomRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateRoomRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateRoomRequest>(create);
  static CreateRoomRequest? _defaultInstance;
}

class JoinRoomRequest extends $pb.GeneratedMessage {
  factory JoinRoomRequest({
    $core.String? roomCode,
  }) {
    final result = create();
    if (roomCode != null) result.roomCode = roomCode;
    return result;
  }

  JoinRoomRequest._();

  factory JoinRoomRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JoinRoomRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinRoomRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinRoomRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinRoomRequest copyWith(void Function(JoinRoomRequest) updates) =>
      super.copyWith((message) => updates(message as JoinRoomRequest))
          as JoinRoomRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JoinRoomRequest create() => JoinRoomRequest._();
  @$core.override
  JoinRoomRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static JoinRoomRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JoinRoomRequest>(create);
  static JoinRoomRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomCode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomCode() => $_clearField(1);
}

class LeaveRoomRequest extends $pb.GeneratedMessage {
  factory LeaveRoomRequest({
    $core.String? roomId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    return result;
  }

  LeaveRoomRequest._();

  factory LeaveRoomRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LeaveRoomRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaveRoomRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveRoomRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveRoomRequest copyWith(void Function(LeaveRoomRequest) updates) =>
      super.copyWith((message) => updates(message as LeaveRoomRequest))
          as LeaveRoomRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LeaveRoomRequest create() => LeaveRoomRequest._();
  @$core.override
  LeaveRoomRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LeaveRoomRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaveRoomRequest>(create);
  static LeaveRoomRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);
}

class RoomReadyRequest extends $pb.GeneratedMessage {
  factory RoomReadyRequest({
    $core.String? roomId,
    $core.bool? ready,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (ready != null) result.ready = ready;
    return result;
  }

  RoomReadyRequest._();

  factory RoomReadyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoomReadyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomReadyRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOB(2, _omitFieldNames ? '' : 'ready')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomReadyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomReadyRequest copyWith(void Function(RoomReadyRequest) updates) =>
      super.copyWith((message) => updates(message as RoomReadyRequest))
          as RoomReadyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomReadyRequest create() => RoomReadyRequest._();
  @$core.override
  RoomReadyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoomReadyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomReadyRequest>(create);
  static RoomReadyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get ready => $_getBF(1);
  @$pb.TagNumber(2)
  set ready($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReady() => $_has(1);
  @$pb.TagNumber(2)
  void clearReady() => $_clearField(2);
}

class AddBotRequest extends $pb.GeneratedMessage {
  factory AddBotRequest({
    $core.String? roomId,
    BotDifficulty? botDifficulty,
    $core.int? seatIndex,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (botDifficulty != null) result.botDifficulty = botDifficulty;
    if (seatIndex != null) result.seatIndex = seatIndex;
    return result;
  }

  AddBotRequest._();

  factory AddBotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddBotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddBotRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aE<BotDifficulty>(2, _omitFieldNames ? '' : 'botDifficulty',
        enumValues: BotDifficulty.values)
    ..aI(3, _omitFieldNames ? '' : 'seatIndex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddBotRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddBotRequest copyWith(void Function(AddBotRequest) updates) =>
      super.copyWith((message) => updates(message as AddBotRequest))
          as AddBotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddBotRequest create() => AddBotRequest._();
  @$core.override
  AddBotRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddBotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddBotRequest>(create);
  static AddBotRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  BotDifficulty get botDifficulty => $_getN(1);
  @$pb.TagNumber(2)
  set botDifficulty(BotDifficulty value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBotDifficulty() => $_has(1);
  @$pb.TagNumber(2)
  void clearBotDifficulty() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get seatIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set seatIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSeatIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeatIndex() => $_clearField(3);
}

class RemovePlayerRequest extends $pb.GeneratedMessage {
  factory RemovePlayerRequest({
    $core.String? roomId,
    $core.String? playerId,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (playerId != null) result.playerId = playerId;
    return result;
  }

  RemovePlayerRequest._();

  factory RemovePlayerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemovePlayerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemovePlayerRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOS(2, _omitFieldNames ? '' : 'playerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemovePlayerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemovePlayerRequest copyWith(void Function(RemovePlayerRequest) updates) =>
      super.copyWith((message) => updates(message as RemovePlayerRequest))
          as RemovePlayerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemovePlayerRequest create() => RemovePlayerRequest._();
  @$core.override
  RemovePlayerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemovePlayerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemovePlayerRequest>(create);
  static RemovePlayerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get playerId => $_getSZ(1);
  @$pb.TagNumber(2)
  set playerId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayerId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayerId() => $_clearField(2);
}

class ListFriendsRequest extends $pb.GeneratedMessage {
  factory ListFriendsRequest() => create();

  ListFriendsRequest._();

  factory ListFriendsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFriendsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFriendsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFriendsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFriendsRequest copyWith(void Function(ListFriendsRequest) updates) =>
      super.copyWith((message) => updates(message as ListFriendsRequest))
          as ListFriendsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFriendsRequest create() => ListFriendsRequest._();
  @$core.override
  ListFriendsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFriendsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFriendsRequest>(create);
  static ListFriendsRequest? _defaultInstance;
}

class ListFriendsResponse extends $pb.GeneratedMessage {
  factory ListFriendsResponse({
    $core.Iterable<OnlineUser>? users,
    FriendCenterSnapshot? snapshot,
  }) {
    final result = create();
    if (users != null) result.users.addAll(users);
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  ListFriendsResponse._();

  factory ListFriendsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListFriendsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFriendsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..pPM<OnlineUser>(1, _omitFieldNames ? '' : 'users',
        subBuilder: OnlineUser.create)
    ..aOM<FriendCenterSnapshot>(2, _omitFieldNames ? '' : 'snapshot',
        subBuilder: FriendCenterSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFriendsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFriendsResponse copyWith(void Function(ListFriendsResponse) updates) =>
      super.copyWith((message) => updates(message as ListFriendsResponse))
          as ListFriendsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListFriendsResponse create() => ListFriendsResponse._();
  @$core.override
  ListFriendsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListFriendsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFriendsResponse>(create);
  static ListFriendsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OnlineUser> get users => $_getList(0);

  @$pb.TagNumber(2)
  FriendCenterSnapshot get snapshot => $_getN(1);
  @$pb.TagNumber(2)
  set snapshot(FriendCenterSnapshot value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSnapshot() => $_has(1);
  @$pb.TagNumber(2)
  void clearSnapshot() => $_clearField(2);
  @$pb.TagNumber(2)
  FriendCenterSnapshot ensureSnapshot() => $_ensure(1);
}

class AddFriendRequest extends $pb.GeneratedMessage {
  factory AddFriendRequest({
    $core.String? account,
  }) {
    final result = create();
    if (account != null) result.account = account;
    return result;
  }

  AddFriendRequest._();

  factory AddFriendRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddFriendRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddFriendRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'account')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddFriendRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddFriendRequest copyWith(void Function(AddFriendRequest) updates) =>
      super.copyWith((message) => updates(message as AddFriendRequest))
          as AddFriendRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddFriendRequest create() => AddFriendRequest._();
  @$core.override
  AddFriendRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddFriendRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddFriendRequest>(create);
  static AddFriendRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get account => $_getSZ(0);
  @$pb.TagNumber(1)
  set account($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccount() => $_clearField(1);
}

class AddFriendResponse extends $pb.GeneratedMessage {
  factory AddFriendResponse({
    $core.bool? success,
    $core.String? message,
    FriendRequestEntry? request,
    FriendCenterSnapshot? snapshot,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (request != null) result.request = request;
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  AddFriendResponse._();

  factory AddFriendResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddFriendResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddFriendResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<FriendRequestEntry>(3, _omitFieldNames ? '' : 'request',
        subBuilder: FriendRequestEntry.create)
    ..aOM<FriendCenterSnapshot>(4, _omitFieldNames ? '' : 'snapshot',
        subBuilder: FriendCenterSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddFriendResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddFriendResponse copyWith(void Function(AddFriendResponse) updates) =>
      super.copyWith((message) => updates(message as AddFriendResponse))
          as AddFriendResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddFriendResponse create() => AddFriendResponse._();
  @$core.override
  AddFriendResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddFriendResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddFriendResponse>(create);
  static AddFriendResponse? _defaultInstance;

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
  FriendRequestEntry get request => $_getN(2);
  @$pb.TagNumber(3)
  set request(FriendRequestEntry value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRequest() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequest() => $_clearField(3);
  @$pb.TagNumber(3)
  FriendRequestEntry ensureRequest() => $_ensure(2);

  @$pb.TagNumber(4)
  FriendCenterSnapshot get snapshot => $_getN(3);
  @$pb.TagNumber(4)
  set snapshot(FriendCenterSnapshot value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSnapshot() => $_has(3);
  @$pb.TagNumber(4)
  void clearSnapshot() => $_clearField(4);
  @$pb.TagNumber(4)
  FriendCenterSnapshot ensureSnapshot() => $_ensure(3);
}

class RespondFriendRequestRequest extends $pb.GeneratedMessage {
  factory RespondFriendRequestRequest({
    $core.String? requestId,
    $core.bool? accept,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (accept != null) result.accept = accept;
    return result;
  }

  RespondFriendRequestRequest._();

  factory RespondFriendRequestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespondFriendRequestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespondFriendRequestRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aOB(2, _omitFieldNames ? '' : 'accept')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondFriendRequestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondFriendRequestRequest copyWith(
          void Function(RespondFriendRequestRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RespondFriendRequestRequest))
          as RespondFriendRequestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespondFriendRequestRequest create() =>
      RespondFriendRequestRequest._();
  @$core.override
  RespondFriendRequestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespondFriendRequestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespondFriendRequestRequest>(create);
  static RespondFriendRequestRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get accept => $_getBF(1);
  @$pb.TagNumber(2)
  set accept($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccept() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccept() => $_clearField(2);
}

class RespondFriendRequestResponse extends $pb.GeneratedMessage {
  factory RespondFriendRequestResponse({
    $core.bool? success,
    $core.String? message,
    FriendRequestEntry? request,
    FriendCenterSnapshot? snapshot,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (request != null) result.request = request;
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  RespondFriendRequestResponse._();

  factory RespondFriendRequestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespondFriendRequestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespondFriendRequestResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<FriendRequestEntry>(3, _omitFieldNames ? '' : 'request',
        subBuilder: FriendRequestEntry.create)
    ..aOM<FriendCenterSnapshot>(4, _omitFieldNames ? '' : 'snapshot',
        subBuilder: FriendCenterSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondFriendRequestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondFriendRequestResponse copyWith(
          void Function(RespondFriendRequestResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RespondFriendRequestResponse))
          as RespondFriendRequestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespondFriendRequestResponse create() =>
      RespondFriendRequestResponse._();
  @$core.override
  RespondFriendRequestResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespondFriendRequestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespondFriendRequestResponse>(create);
  static RespondFriendRequestResponse? _defaultInstance;

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
  FriendRequestEntry get request => $_getN(2);
  @$pb.TagNumber(3)
  set request(FriendRequestEntry value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRequest() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequest() => $_clearField(3);
  @$pb.TagNumber(3)
  FriendRequestEntry ensureRequest() => $_ensure(2);

  @$pb.TagNumber(4)
  FriendCenterSnapshot get snapshot => $_getN(3);
  @$pb.TagNumber(4)
  set snapshot(FriendCenterSnapshot value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSnapshot() => $_has(3);
  @$pb.TagNumber(4)
  void clearSnapshot() => $_clearField(4);
  @$pb.TagNumber(4)
  FriendCenterSnapshot ensureSnapshot() => $_ensure(3);
}

class DeleteFriendRequest extends $pb.GeneratedMessage {
  factory DeleteFriendRequest({
    $core.String? friendUserId,
  }) {
    final result = create();
    if (friendUserId != null) result.friendUserId = friendUserId;
    return result;
  }

  DeleteFriendRequest._();

  factory DeleteFriendRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteFriendRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteFriendRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'friendUserId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFriendRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFriendRequest copyWith(void Function(DeleteFriendRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteFriendRequest))
          as DeleteFriendRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteFriendRequest create() => DeleteFriendRequest._();
  @$core.override
  DeleteFriendRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteFriendRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteFriendRequest>(create);
  static DeleteFriendRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get friendUserId => $_getSZ(0);
  @$pb.TagNumber(1)
  set friendUserId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFriendUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearFriendUserId() => $_clearField(1);
}

class DeleteFriendResponse extends $pb.GeneratedMessage {
  factory DeleteFriendResponse({
    $core.bool? success,
    $core.String? message,
    FriendCenterSnapshot? snapshot,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  DeleteFriendResponse._();

  factory DeleteFriendResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteFriendResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteFriendResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<FriendCenterSnapshot>(3, _omitFieldNames ? '' : 'snapshot',
        subBuilder: FriendCenterSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFriendResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteFriendResponse copyWith(void Function(DeleteFriendResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteFriendResponse))
          as DeleteFriendResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteFriendResponse create() => DeleteFriendResponse._();
  @$core.override
  DeleteFriendResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteFriendResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteFriendResponse>(create);
  static DeleteFriendResponse? _defaultInstance;

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
  FriendCenterSnapshot get snapshot => $_getN(2);
  @$pb.TagNumber(3)
  set snapshot(FriendCenterSnapshot value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSnapshot() => $_has(2);
  @$pb.TagNumber(3)
  void clearSnapshot() => $_clearField(3);
  @$pb.TagNumber(3)
  FriendCenterSnapshot ensureSnapshot() => $_ensure(2);
}

class InvitePlayerRequest extends $pb.GeneratedMessage {
  factory InvitePlayerRequest({
    $core.String? roomId,
    $core.String? inviteeAccount,
    $core.int? seatIndex,
  }) {
    final result = create();
    if (roomId != null) result.roomId = roomId;
    if (inviteeAccount != null) result.inviteeAccount = inviteeAccount;
    if (seatIndex != null) result.seatIndex = seatIndex;
    return result;
  }

  InvitePlayerRequest._();

  factory InvitePlayerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InvitePlayerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvitePlayerRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'roomId')
    ..aOS(2, _omitFieldNames ? '' : 'inviteeAccount')
    ..aI(3, _omitFieldNames ? '' : 'seatIndex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePlayerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePlayerRequest copyWith(void Function(InvitePlayerRequest) updates) =>
      super.copyWith((message) => updates(message as InvitePlayerRequest))
          as InvitePlayerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvitePlayerRequest create() => InvitePlayerRequest._();
  @$core.override
  InvitePlayerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InvitePlayerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvitePlayerRequest>(create);
  static InvitePlayerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roomId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roomId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoomId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoomId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get inviteeAccount => $_getSZ(1);
  @$pb.TagNumber(2)
  set inviteeAccount($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInviteeAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearInviteeAccount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get seatIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set seatIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSeatIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearSeatIndex() => $_clearField(3);
}

class InvitePlayerResponse extends $pb.GeneratedMessage {
  factory InvitePlayerResponse({
    $core.bool? accepted,
    $core.String? message,
  }) {
    final result = create();
    if (accepted != null) result.accepted = accepted;
    if (message != null) result.message = message;
    return result;
  }

  InvitePlayerResponse._();

  factory InvitePlayerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory InvitePlayerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InvitePlayerResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'accepted')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePlayerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InvitePlayerResponse copyWith(void Function(InvitePlayerResponse) updates) =>
      super.copyWith((message) => updates(message as InvitePlayerResponse))
          as InvitePlayerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InvitePlayerResponse create() => InvitePlayerResponse._();
  @$core.override
  InvitePlayerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static InvitePlayerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InvitePlayerResponse>(create);
  static InvitePlayerResponse? _defaultInstance;

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

class RoomInvitationPush extends $pb.GeneratedMessage {
  factory RoomInvitationPush({
    $core.String? invitationId,
    $core.String? roomId,
    $core.String? roomCode,
    $core.String? inviterUserId,
    $core.String? inviterAccount,
    $core.String? inviterNickname,
    $core.int? seatIndex,
  }) {
    final result = create();
    if (invitationId != null) result.invitationId = invitationId;
    if (roomId != null) result.roomId = roomId;
    if (roomCode != null) result.roomCode = roomCode;
    if (inviterUserId != null) result.inviterUserId = inviterUserId;
    if (inviterAccount != null) result.inviterAccount = inviterAccount;
    if (inviterNickname != null) result.inviterNickname = inviterNickname;
    if (seatIndex != null) result.seatIndex = seatIndex;
    return result;
  }

  RoomInvitationPush._();

  factory RoomInvitationPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoomInvitationPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomInvitationPush',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'invitationId')
    ..aOS(2, _omitFieldNames ? '' : 'roomId')
    ..aOS(3, _omitFieldNames ? '' : 'roomCode')
    ..aOS(4, _omitFieldNames ? '' : 'inviterUserId')
    ..aOS(5, _omitFieldNames ? '' : 'inviterAccount')
    ..aOS(6, _omitFieldNames ? '' : 'inviterNickname')
    ..aI(7, _omitFieldNames ? '' : 'seatIndex')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomInvitationPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomInvitationPush copyWith(void Function(RoomInvitationPush) updates) =>
      super.copyWith((message) => updates(message as RoomInvitationPush))
          as RoomInvitationPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomInvitationPush create() => RoomInvitationPush._();
  @$core.override
  RoomInvitationPush createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoomInvitationPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomInvitationPush>(create);
  static RoomInvitationPush? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get invitationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set invitationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInvitationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvitationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get roomId => $_getSZ(1);
  @$pb.TagNumber(2)
  set roomId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoomId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoomId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get roomCode => $_getSZ(2);
  @$pb.TagNumber(3)
  set roomCode($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRoomCode() => $_has(2);
  @$pb.TagNumber(3)
  void clearRoomCode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get inviterUserId => $_getSZ(3);
  @$pb.TagNumber(4)
  set inviterUserId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInviterUserId() => $_has(3);
  @$pb.TagNumber(4)
  void clearInviterUserId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get inviterAccount => $_getSZ(4);
  @$pb.TagNumber(5)
  set inviterAccount($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInviterAccount() => $_has(4);
  @$pb.TagNumber(5)
  void clearInviterAccount() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get inviterNickname => $_getSZ(5);
  @$pb.TagNumber(6)
  set inviterNickname($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasInviterNickname() => $_has(5);
  @$pb.TagNumber(6)
  void clearInviterNickname() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get seatIndex => $_getIZ(6);
  @$pb.TagNumber(7)
  set seatIndex($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSeatIndex() => $_has(6);
  @$pb.TagNumber(7)
  void clearSeatIndex() => $_clearField(7);
}

class RespondRoomInvitationRequest extends $pb.GeneratedMessage {
  factory RespondRoomInvitationRequest({
    $core.String? invitationId,
    $core.bool? accept,
  }) {
    final result = create();
    if (invitationId != null) result.invitationId = invitationId;
    if (accept != null) result.accept = accept;
    return result;
  }

  RespondRoomInvitationRequest._();

  factory RespondRoomInvitationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespondRoomInvitationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespondRoomInvitationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'invitationId')
    ..aOB(2, _omitFieldNames ? '' : 'accept')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondRoomInvitationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondRoomInvitationRequest copyWith(
          void Function(RespondRoomInvitationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RespondRoomInvitationRequest))
          as RespondRoomInvitationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespondRoomInvitationRequest create() =>
      RespondRoomInvitationRequest._();
  @$core.override
  RespondRoomInvitationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespondRoomInvitationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespondRoomInvitationRequest>(create);
  static RespondRoomInvitationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get invitationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set invitationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInvitationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvitationId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get accept => $_getBF(1);
  @$pb.TagNumber(2)
  set accept($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccept() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccept() => $_clearField(2);
}

class RespondRoomInvitationResponse extends $pb.GeneratedMessage {
  factory RespondRoomInvitationResponse({
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

  RespondRoomInvitationResponse._();

  factory RespondRoomInvitationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RespondRoomInvitationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RespondRoomInvitationResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOM<RoomSnapshot>(3, _omitFieldNames ? '' : 'snapshot',
        subBuilder: RoomSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondRoomInvitationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RespondRoomInvitationResponse copyWith(
          void Function(RespondRoomInvitationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RespondRoomInvitationResponse))
          as RespondRoomInvitationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RespondRoomInvitationResponse create() =>
      RespondRoomInvitationResponse._();
  @$core.override
  RespondRoomInvitationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RespondRoomInvitationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RespondRoomInvitationResponse>(create);
  static RespondRoomInvitationResponse? _defaultInstance;

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

class RoomInvitationResultPush extends $pb.GeneratedMessage {
  factory RoomInvitationResultPush({
    $core.String? invitationId,
    InvitationResult? result,
    $core.String? inviteeUserId,
    $core.String? inviteeAccount,
    $core.String? inviteeNickname,
    $core.String? message,
  }) {
    final result$ = create();
    if (invitationId != null) result$.invitationId = invitationId;
    if (result != null) result$.result = result;
    if (inviteeUserId != null) result$.inviteeUserId = inviteeUserId;
    if (inviteeAccount != null) result$.inviteeAccount = inviteeAccount;
    if (inviteeNickname != null) result$.inviteeNickname = inviteeNickname;
    if (message != null) result$.message = message;
    return result$;
  }

  RoomInvitationResultPush._();

  factory RoomInvitationResultPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoomInvitationResultPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoomInvitationResultPush',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'invitationId')
    ..aE<InvitationResult>(2, _omitFieldNames ? '' : 'result',
        enumValues: InvitationResult.values)
    ..aOS(3, _omitFieldNames ? '' : 'inviteeUserId')
    ..aOS(4, _omitFieldNames ? '' : 'inviteeAccount')
    ..aOS(5, _omitFieldNames ? '' : 'inviteeNickname')
    ..aOS(6, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomInvitationResultPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoomInvitationResultPush copyWith(
          void Function(RoomInvitationResultPush) updates) =>
      super.copyWith((message) => updates(message as RoomInvitationResultPush))
          as RoomInvitationResultPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoomInvitationResultPush create() => RoomInvitationResultPush._();
  @$core.override
  RoomInvitationResultPush createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RoomInvitationResultPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoomInvitationResultPush>(create);
  static RoomInvitationResultPush? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get invitationId => $_getSZ(0);
  @$pb.TagNumber(1)
  set invitationId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInvitationId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvitationId() => $_clearField(1);

  @$pb.TagNumber(2)
  InvitationResult get result => $_getN(1);
  @$pb.TagNumber(2)
  set result(InvitationResult value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get inviteeUserId => $_getSZ(2);
  @$pb.TagNumber(3)
  set inviteeUserId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInviteeUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearInviteeUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get inviteeAccount => $_getSZ(3);
  @$pb.TagNumber(4)
  set inviteeAccount($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInviteeAccount() => $_has(3);
  @$pb.TagNumber(4)
  void clearInviteeAccount() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get inviteeNickname => $_getSZ(4);
  @$pb.TagNumber(5)
  set inviteeNickname($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInviteeNickname() => $_has(4);
  @$pb.TagNumber(5)
  void clearInviteeNickname() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get message => $_getSZ(5);
  @$pb.TagNumber(6)
  set message($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMessage() => $_has(5);
  @$pb.TagNumber(6)
  void clearMessage() => $_clearField(6);
}

class FriendCenterPush extends $pb.GeneratedMessage {
  factory FriendCenterPush({
    FriendCenterSnapshot? snapshot,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  FriendCenterPush._();

  factory FriendCenterPush.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FriendCenterPush.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FriendCenterPush',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..aOM<FriendCenterSnapshot>(1, _omitFieldNames ? '' : 'snapshot',
        subBuilder: FriendCenterSnapshot.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendCenterPush clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FriendCenterPush copyWith(void Function(FriendCenterPush) updates) =>
      super.copyWith((message) => updates(message as FriendCenterPush))
          as FriendCenterPush;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FriendCenterPush create() => FriendCenterPush._();
  @$core.override
  FriendCenterPush createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FriendCenterPush getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FriendCenterPush>(create);
  static FriendCenterPush? _defaultInstance;

  @$pb.TagNumber(1)
  FriendCenterSnapshot get snapshot => $_getN(0);
  @$pb.TagNumber(1)
  set snapshot(FriendCenterSnapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
  @$pb.TagNumber(1)
  FriendCenterSnapshot ensureSnapshot() => $_ensure(0);
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
    $core.int? seatIndex,
    $core.bool? ready,
    $core.bool? occupied,
  }) {
    final result = create();
    if (playerId != null) result.playerId = playerId;
    if (displayName != null) result.displayName = displayName;
    if (isBot != null) result.isBot = isBot;
    if (role != null) result.role = role;
    if (cardsLeft != null) result.cardsLeft = cardsLeft;
    if (roundScore != null) result.roundScore = roundScore;
    if (seatIndex != null) result.seatIndex = seatIndex;
    if (ready != null) result.ready = ready;
    if (occupied != null) result.occupied = occupied;
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
    ..aI(7, _omitFieldNames ? '' : 'seatIndex')
    ..aOB(8, _omitFieldNames ? '' : 'ready')
    ..aOB(9, _omitFieldNames ? '' : 'occupied')
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

  @$pb.TagNumber(7)
  $core.int get seatIndex => $_getIZ(6);
  @$pb.TagNumber(7)
  set seatIndex($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSeatIndex() => $_has(6);
  @$pb.TagNumber(7)
  void clearSeatIndex() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get ready => $_getBF(7);
  @$pb.TagNumber(8)
  set ready($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReady() => $_has(7);
  @$pb.TagNumber(8)
  void clearReady() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get occupied => $_getBF(8);
  @$pb.TagNumber(9)
  set occupied($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasOccupied() => $_has(8);
  @$pb.TagNumber(9)
  void clearOccupied() => $_clearField(9);
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
    $core.String? roomCode,
    $core.String? ownerPlayerId,
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
    if (roomCode != null) result.roomCode = roomCode;
    if (ownerPlayerId != null) result.ownerPlayerId = ownerPlayerId;
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
    ..aOS(16, _omitFieldNames ? '' : 'roomCode')
    ..aOS(17, _omitFieldNames ? '' : 'ownerPlayerId')
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

  @$pb.TagNumber(16)
  $core.String get roomCode => $_getSZ(15);
  @$pb.TagNumber(16)
  set roomCode($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasRoomCode() => $_has(15);
  @$pb.TagNumber(16)
  void clearRoomCode() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get ownerPlayerId => $_getSZ(16);
  @$pb.TagNumber(17)
  set ownerPlayerId($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasOwnerPlayerId() => $_has(16);
  @$pb.TagNumber(17)
  void clearOwnerPlayerId() => $_clearField(17);
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
  resetPasswordRequest,
  createRoomRequest,
  joinRoomRequest,
  roomReadyRequest,
  addBotRequest,
  removePlayerRequest,
  listFriendsRequest,
  addFriendRequest,
  invitePlayerRequest,
  respondRoomInvitationRequest,
  leaveRoomRequest,
  updateNicknameRequest,
  respondFriendRequestRequest,
  deleteFriendRequest,
  changePasswordRequest,
  fetchSystemStatsRequest,
  claimSupportLikeRewardRequest,
  submitSupportLikeRequest,
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
    ResetPasswordRequest? resetPasswordRequest,
    CreateRoomRequest? createRoomRequest,
    JoinRoomRequest? joinRoomRequest,
    RoomReadyRequest? roomReadyRequest,
    AddBotRequest? addBotRequest,
    RemovePlayerRequest? removePlayerRequest,
    ListFriendsRequest? listFriendsRequest,
    AddFriendRequest? addFriendRequest,
    InvitePlayerRequest? invitePlayerRequest,
    RespondRoomInvitationRequest? respondRoomInvitationRequest,
    LeaveRoomRequest? leaveRoomRequest,
    UpdateNicknameRequest? updateNicknameRequest,
    RespondFriendRequestRequest? respondFriendRequestRequest,
    DeleteFriendRequest? deleteFriendRequest,
    ChangePasswordRequest? changePasswordRequest,
    FetchSystemStatsRequest? fetchSystemStatsRequest,
    ClaimSupportLikeRewardRequest? claimSupportLikeRewardRequest,
    SubmitSupportLikeRequest? submitSupportLikeRequest,
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
    if (resetPasswordRequest != null)
      result.resetPasswordRequest = resetPasswordRequest;
    if (createRoomRequest != null) result.createRoomRequest = createRoomRequest;
    if (joinRoomRequest != null) result.joinRoomRequest = joinRoomRequest;
    if (roomReadyRequest != null) result.roomReadyRequest = roomReadyRequest;
    if (addBotRequest != null) result.addBotRequest = addBotRequest;
    if (removePlayerRequest != null)
      result.removePlayerRequest = removePlayerRequest;
    if (listFriendsRequest != null)
      result.listFriendsRequest = listFriendsRequest;
    if (addFriendRequest != null) result.addFriendRequest = addFriendRequest;
    if (invitePlayerRequest != null)
      result.invitePlayerRequest = invitePlayerRequest;
    if (respondRoomInvitationRequest != null)
      result.respondRoomInvitationRequest = respondRoomInvitationRequest;
    if (leaveRoomRequest != null) result.leaveRoomRequest = leaveRoomRequest;
    if (updateNicknameRequest != null)
      result.updateNicknameRequest = updateNicknameRequest;
    if (respondFriendRequestRequest != null)
      result.respondFriendRequestRequest = respondFriendRequestRequest;
    if (deleteFriendRequest != null)
      result.deleteFriendRequest = deleteFriendRequest;
    if (changePasswordRequest != null)
      result.changePasswordRequest = changePasswordRequest;
    if (fetchSystemStatsRequest != null)
      result.fetchSystemStatsRequest = fetchSystemStatsRequest;
    if (claimSupportLikeRewardRequest != null)
      result.claimSupportLikeRewardRequest = claimSupportLikeRewardRequest;
    if (submitSupportLikeRequest != null)
      result.submitSupportLikeRequest = submitSupportLikeRequest;
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
    17: ClientMessage_Payload.resetPasswordRequest,
    18: ClientMessage_Payload.createRoomRequest,
    19: ClientMessage_Payload.joinRoomRequest,
    20: ClientMessage_Payload.roomReadyRequest,
    21: ClientMessage_Payload.addBotRequest,
    22: ClientMessage_Payload.removePlayerRequest,
    23: ClientMessage_Payload.listFriendsRequest,
    24: ClientMessage_Payload.addFriendRequest,
    25: ClientMessage_Payload.invitePlayerRequest,
    26: ClientMessage_Payload.respondRoomInvitationRequest,
    27: ClientMessage_Payload.leaveRoomRequest,
    28: ClientMessage_Payload.updateNicknameRequest,
    29: ClientMessage_Payload.respondFriendRequestRequest,
    30: ClientMessage_Payload.deleteFriendRequest,
    31: ClientMessage_Payload.changePasswordRequest,
    32: ClientMessage_Payload.fetchSystemStatsRequest,
    33: ClientMessage_Payload.claimSupportLikeRewardRequest,
    34: ClientMessage_Payload.submitSupportLikeRequest,
    0: ClientMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClientMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..oo(0, [
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34
    ])
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
    ..aOM<ResetPasswordRequest>(
        17, _omitFieldNames ? '' : 'resetPasswordRequest',
        subBuilder: ResetPasswordRequest.create)
    ..aOM<CreateRoomRequest>(18, _omitFieldNames ? '' : 'createRoomRequest',
        subBuilder: CreateRoomRequest.create)
    ..aOM<JoinRoomRequest>(19, _omitFieldNames ? '' : 'joinRoomRequest',
        subBuilder: JoinRoomRequest.create)
    ..aOM<RoomReadyRequest>(20, _omitFieldNames ? '' : 'roomReadyRequest',
        subBuilder: RoomReadyRequest.create)
    ..aOM<AddBotRequest>(21, _omitFieldNames ? '' : 'addBotRequest',
        subBuilder: AddBotRequest.create)
    ..aOM<RemovePlayerRequest>(22, _omitFieldNames ? '' : 'removePlayerRequest',
        subBuilder: RemovePlayerRequest.create)
    ..aOM<ListFriendsRequest>(23, _omitFieldNames ? '' : 'listFriendsRequest',
        subBuilder: ListFriendsRequest.create)
    ..aOM<AddFriendRequest>(24, _omitFieldNames ? '' : 'addFriendRequest',
        subBuilder: AddFriendRequest.create)
    ..aOM<InvitePlayerRequest>(25, _omitFieldNames ? '' : 'invitePlayerRequest',
        subBuilder: InvitePlayerRequest.create)
    ..aOM<RespondRoomInvitationRequest>(
        26, _omitFieldNames ? '' : 'respondRoomInvitationRequest',
        subBuilder: RespondRoomInvitationRequest.create)
    ..aOM<LeaveRoomRequest>(27, _omitFieldNames ? '' : 'leaveRoomRequest',
        subBuilder: LeaveRoomRequest.create)
    ..aOM<UpdateNicknameRequest>(
        28, _omitFieldNames ? '' : 'updateNicknameRequest',
        subBuilder: UpdateNicknameRequest.create)
    ..aOM<RespondFriendRequestRequest>(
        29, _omitFieldNames ? '' : 'respondFriendRequestRequest',
        subBuilder: RespondFriendRequestRequest.create)
    ..aOM<DeleteFriendRequest>(30, _omitFieldNames ? '' : 'deleteFriendRequest',
        subBuilder: DeleteFriendRequest.create)
    ..aOM<ChangePasswordRequest>(
        31, _omitFieldNames ? '' : 'changePasswordRequest',
        subBuilder: ChangePasswordRequest.create)
    ..aOM<FetchSystemStatsRequest>(
        32, _omitFieldNames ? '' : 'fetchSystemStatsRequest',
        subBuilder: FetchSystemStatsRequest.create)
    ..aOM<ClaimSupportLikeRewardRequest>(
        33, _omitFieldNames ? '' : 'claimSupportLikeRewardRequest',
        subBuilder: ClaimSupportLikeRewardRequest.create)
    ..aOM<SubmitSupportLikeRequest>(
        34, _omitFieldNames ? '' : 'submitSupportLikeRequest',
        subBuilder: SubmitSupportLikeRequest.create)
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
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  ClientMessage_Payload whichPayload() =>
      _ClientMessage_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
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

  @$pb.TagNumber(17)
  ResetPasswordRequest get resetPasswordRequest => $_getN(9);
  @$pb.TagNumber(17)
  set resetPasswordRequest(ResetPasswordRequest value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasResetPasswordRequest() => $_has(9);
  @$pb.TagNumber(17)
  void clearResetPasswordRequest() => $_clearField(17);
  @$pb.TagNumber(17)
  ResetPasswordRequest ensureResetPasswordRequest() => $_ensure(9);

  @$pb.TagNumber(18)
  CreateRoomRequest get createRoomRequest => $_getN(10);
  @$pb.TagNumber(18)
  set createRoomRequest(CreateRoomRequest value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasCreateRoomRequest() => $_has(10);
  @$pb.TagNumber(18)
  void clearCreateRoomRequest() => $_clearField(18);
  @$pb.TagNumber(18)
  CreateRoomRequest ensureCreateRoomRequest() => $_ensure(10);

  @$pb.TagNumber(19)
  JoinRoomRequest get joinRoomRequest => $_getN(11);
  @$pb.TagNumber(19)
  set joinRoomRequest(JoinRoomRequest value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasJoinRoomRequest() => $_has(11);
  @$pb.TagNumber(19)
  void clearJoinRoomRequest() => $_clearField(19);
  @$pb.TagNumber(19)
  JoinRoomRequest ensureJoinRoomRequest() => $_ensure(11);

  @$pb.TagNumber(20)
  RoomReadyRequest get roomReadyRequest => $_getN(12);
  @$pb.TagNumber(20)
  set roomReadyRequest(RoomReadyRequest value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasRoomReadyRequest() => $_has(12);
  @$pb.TagNumber(20)
  void clearRoomReadyRequest() => $_clearField(20);
  @$pb.TagNumber(20)
  RoomReadyRequest ensureRoomReadyRequest() => $_ensure(12);

  @$pb.TagNumber(21)
  AddBotRequest get addBotRequest => $_getN(13);
  @$pb.TagNumber(21)
  set addBotRequest(AddBotRequest value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasAddBotRequest() => $_has(13);
  @$pb.TagNumber(21)
  void clearAddBotRequest() => $_clearField(21);
  @$pb.TagNumber(21)
  AddBotRequest ensureAddBotRequest() => $_ensure(13);

  @$pb.TagNumber(22)
  RemovePlayerRequest get removePlayerRequest => $_getN(14);
  @$pb.TagNumber(22)
  set removePlayerRequest(RemovePlayerRequest value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasRemovePlayerRequest() => $_has(14);
  @$pb.TagNumber(22)
  void clearRemovePlayerRequest() => $_clearField(22);
  @$pb.TagNumber(22)
  RemovePlayerRequest ensureRemovePlayerRequest() => $_ensure(14);

  @$pb.TagNumber(23)
  ListFriendsRequest get listFriendsRequest => $_getN(15);
  @$pb.TagNumber(23)
  set listFriendsRequest(ListFriendsRequest value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasListFriendsRequest() => $_has(15);
  @$pb.TagNumber(23)
  void clearListFriendsRequest() => $_clearField(23);
  @$pb.TagNumber(23)
  ListFriendsRequest ensureListFriendsRequest() => $_ensure(15);

  @$pb.TagNumber(24)
  AddFriendRequest get addFriendRequest => $_getN(16);
  @$pb.TagNumber(24)
  set addFriendRequest(AddFriendRequest value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasAddFriendRequest() => $_has(16);
  @$pb.TagNumber(24)
  void clearAddFriendRequest() => $_clearField(24);
  @$pb.TagNumber(24)
  AddFriendRequest ensureAddFriendRequest() => $_ensure(16);

  @$pb.TagNumber(25)
  InvitePlayerRequest get invitePlayerRequest => $_getN(17);
  @$pb.TagNumber(25)
  set invitePlayerRequest(InvitePlayerRequest value) => $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasInvitePlayerRequest() => $_has(17);
  @$pb.TagNumber(25)
  void clearInvitePlayerRequest() => $_clearField(25);
  @$pb.TagNumber(25)
  InvitePlayerRequest ensureInvitePlayerRequest() => $_ensure(17);

  @$pb.TagNumber(26)
  RespondRoomInvitationRequest get respondRoomInvitationRequest => $_getN(18);
  @$pb.TagNumber(26)
  set respondRoomInvitationRequest(RespondRoomInvitationRequest value) =>
      $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasRespondRoomInvitationRequest() => $_has(18);
  @$pb.TagNumber(26)
  void clearRespondRoomInvitationRequest() => $_clearField(26);
  @$pb.TagNumber(26)
  RespondRoomInvitationRequest ensureRespondRoomInvitationRequest() =>
      $_ensure(18);

  @$pb.TagNumber(27)
  LeaveRoomRequest get leaveRoomRequest => $_getN(19);
  @$pb.TagNumber(27)
  set leaveRoomRequest(LeaveRoomRequest value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasLeaveRoomRequest() => $_has(19);
  @$pb.TagNumber(27)
  void clearLeaveRoomRequest() => $_clearField(27);
  @$pb.TagNumber(27)
  LeaveRoomRequest ensureLeaveRoomRequest() => $_ensure(19);

  @$pb.TagNumber(28)
  UpdateNicknameRequest get updateNicknameRequest => $_getN(20);
  @$pb.TagNumber(28)
  set updateNicknameRequest(UpdateNicknameRequest value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasUpdateNicknameRequest() => $_has(20);
  @$pb.TagNumber(28)
  void clearUpdateNicknameRequest() => $_clearField(28);
  @$pb.TagNumber(28)
  UpdateNicknameRequest ensureUpdateNicknameRequest() => $_ensure(20);

  @$pb.TagNumber(29)
  RespondFriendRequestRequest get respondFriendRequestRequest => $_getN(21);
  @$pb.TagNumber(29)
  set respondFriendRequestRequest(RespondFriendRequestRequest value) =>
      $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasRespondFriendRequestRequest() => $_has(21);
  @$pb.TagNumber(29)
  void clearRespondFriendRequestRequest() => $_clearField(29);
  @$pb.TagNumber(29)
  RespondFriendRequestRequest ensureRespondFriendRequestRequest() =>
      $_ensure(21);

  @$pb.TagNumber(30)
  DeleteFriendRequest get deleteFriendRequest => $_getN(22);
  @$pb.TagNumber(30)
  set deleteFriendRequest(DeleteFriendRequest value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasDeleteFriendRequest() => $_has(22);
  @$pb.TagNumber(30)
  void clearDeleteFriendRequest() => $_clearField(30);
  @$pb.TagNumber(30)
  DeleteFriendRequest ensureDeleteFriendRequest() => $_ensure(22);

  @$pb.TagNumber(31)
  ChangePasswordRequest get changePasswordRequest => $_getN(23);
  @$pb.TagNumber(31)
  set changePasswordRequest(ChangePasswordRequest value) =>
      $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasChangePasswordRequest() => $_has(23);
  @$pb.TagNumber(31)
  void clearChangePasswordRequest() => $_clearField(31);
  @$pb.TagNumber(31)
  ChangePasswordRequest ensureChangePasswordRequest() => $_ensure(23);

  @$pb.TagNumber(32)
  FetchSystemStatsRequest get fetchSystemStatsRequest => $_getN(24);
  @$pb.TagNumber(32)
  set fetchSystemStatsRequest(FetchSystemStatsRequest value) =>
      $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasFetchSystemStatsRequest() => $_has(24);
  @$pb.TagNumber(32)
  void clearFetchSystemStatsRequest() => $_clearField(32);
  @$pb.TagNumber(32)
  FetchSystemStatsRequest ensureFetchSystemStatsRequest() => $_ensure(24);

  @$pb.TagNumber(33)
  ClaimSupportLikeRewardRequest get claimSupportLikeRewardRequest => $_getN(25);
  @$pb.TagNumber(33)
  set claimSupportLikeRewardRequest(ClaimSupportLikeRewardRequest value) =>
      $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasClaimSupportLikeRewardRequest() => $_has(25);
  @$pb.TagNumber(33)
  void clearClaimSupportLikeRewardRequest() => $_clearField(33);
  @$pb.TagNumber(33)
  ClaimSupportLikeRewardRequest ensureClaimSupportLikeRewardRequest() =>
      $_ensure(25);

  @$pb.TagNumber(34)
  SubmitSupportLikeRequest get submitSupportLikeRequest => $_getN(26);
  @$pb.TagNumber(34)
  set submitSupportLikeRequest(SubmitSupportLikeRequest value) =>
      $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasSubmitSupportLikeRequest() => $_has(26);
  @$pb.TagNumber(34)
  void clearSubmitSupportLikeRequest() => $_clearField(34);
  @$pb.TagNumber(34)
  SubmitSupportLikeRequest ensureSubmitSupportLikeRequest() => $_ensure(26);
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
  resetPasswordResponse,
  listFriendsResponse,
  addFriendResponse,
  invitePlayerResponse,
  roomInvitationPush,
  respondRoomInvitationResponse,
  roomInvitationResultPush,
  updateNicknameResponse,
  respondFriendRequestResponse,
  deleteFriendResponse,
  friendCenterPush,
  changePasswordResponse,
  fetchSystemStatsResponse,
  claimSupportLikeRewardResponse,
  submitSupportLikeResponse,
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
    ResetPasswordResponse? resetPasswordResponse,
    ListFriendsResponse? listFriendsResponse,
    AddFriendResponse? addFriendResponse,
    InvitePlayerResponse? invitePlayerResponse,
    RoomInvitationPush? roomInvitationPush,
    RespondRoomInvitationResponse? respondRoomInvitationResponse,
    RoomInvitationResultPush? roomInvitationResultPush,
    UpdateNicknameResponse? updateNicknameResponse,
    RespondFriendRequestResponse? respondFriendRequestResponse,
    DeleteFriendResponse? deleteFriendResponse,
    FriendCenterPush? friendCenterPush,
    ChangePasswordResponse? changePasswordResponse,
    FetchSystemStatsResponse? fetchSystemStatsResponse,
    ClaimSupportLikeRewardResponse? claimSupportLikeRewardResponse,
    SubmitSupportLikeResponse? submitSupportLikeResponse,
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
    if (resetPasswordResponse != null)
      result.resetPasswordResponse = resetPasswordResponse;
    if (listFriendsResponse != null)
      result.listFriendsResponse = listFriendsResponse;
    if (addFriendResponse != null) result.addFriendResponse = addFriendResponse;
    if (invitePlayerResponse != null)
      result.invitePlayerResponse = invitePlayerResponse;
    if (roomInvitationPush != null)
      result.roomInvitationPush = roomInvitationPush;
    if (respondRoomInvitationResponse != null)
      result.respondRoomInvitationResponse = respondRoomInvitationResponse;
    if (roomInvitationResultPush != null)
      result.roomInvitationResultPush = roomInvitationResultPush;
    if (updateNicknameResponse != null)
      result.updateNicknameResponse = updateNicknameResponse;
    if (respondFriendRequestResponse != null)
      result.respondFriendRequestResponse = respondFriendRequestResponse;
    if (deleteFriendResponse != null)
      result.deleteFriendResponse = deleteFriendResponse;
    if (friendCenterPush != null) result.friendCenterPush = friendCenterPush;
    if (changePasswordResponse != null)
      result.changePasswordResponse = changePasswordResponse;
    if (fetchSystemStatsResponse != null)
      result.fetchSystemStatsResponse = fetchSystemStatsResponse;
    if (claimSupportLikeRewardResponse != null)
      result.claimSupportLikeRewardResponse = claimSupportLikeRewardResponse;
    if (submitSupportLikeResponse != null)
      result.submitSupportLikeResponse = submitSupportLikeResponse;
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
    18: ServerMessage_Payload.resetPasswordResponse,
    19: ServerMessage_Payload.listFriendsResponse,
    20: ServerMessage_Payload.addFriendResponse,
    21: ServerMessage_Payload.invitePlayerResponse,
    22: ServerMessage_Payload.roomInvitationPush,
    23: ServerMessage_Payload.respondRoomInvitationResponse,
    24: ServerMessage_Payload.roomInvitationResultPush,
    25: ServerMessage_Payload.updateNicknameResponse,
    26: ServerMessage_Payload.respondFriendRequestResponse,
    27: ServerMessage_Payload.deleteFriendResponse,
    28: ServerMessage_Payload.friendCenterPush,
    29: ServerMessage_Payload.changePasswordResponse,
    30: ServerMessage_Payload.fetchSystemStatsResponse,
    31: ServerMessage_Payload.claimSupportLikeRewardResponse,
    32: ServerMessage_Payload.submitSupportLikeResponse,
    0: ServerMessage_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'landlords.protocol'),
      createEmptyInstance: create)
    ..oo(0, [
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32
    ])
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
    ..aOM<ResetPasswordResponse>(
        18, _omitFieldNames ? '' : 'resetPasswordResponse',
        subBuilder: ResetPasswordResponse.create)
    ..aOM<ListFriendsResponse>(19, _omitFieldNames ? '' : 'listFriendsResponse',
        subBuilder: ListFriendsResponse.create)
    ..aOM<AddFriendResponse>(20, _omitFieldNames ? '' : 'addFriendResponse',
        subBuilder: AddFriendResponse.create)
    ..aOM<InvitePlayerResponse>(
        21, _omitFieldNames ? '' : 'invitePlayerResponse',
        subBuilder: InvitePlayerResponse.create)
    ..aOM<RoomInvitationPush>(22, _omitFieldNames ? '' : 'roomInvitationPush',
        subBuilder: RoomInvitationPush.create)
    ..aOM<RespondRoomInvitationResponse>(
        23, _omitFieldNames ? '' : 'respondRoomInvitationResponse',
        subBuilder: RespondRoomInvitationResponse.create)
    ..aOM<RoomInvitationResultPush>(
        24, _omitFieldNames ? '' : 'roomInvitationResultPush',
        subBuilder: RoomInvitationResultPush.create)
    ..aOM<UpdateNicknameResponse>(
        25, _omitFieldNames ? '' : 'updateNicknameResponse',
        subBuilder: UpdateNicknameResponse.create)
    ..aOM<RespondFriendRequestResponse>(
        26, _omitFieldNames ? '' : 'respondFriendRequestResponse',
        subBuilder: RespondFriendRequestResponse.create)
    ..aOM<DeleteFriendResponse>(
        27, _omitFieldNames ? '' : 'deleteFriendResponse',
        subBuilder: DeleteFriendResponse.create)
    ..aOM<FriendCenterPush>(28, _omitFieldNames ? '' : 'friendCenterPush',
        subBuilder: FriendCenterPush.create)
    ..aOM<ChangePasswordResponse>(
        29, _omitFieldNames ? '' : 'changePasswordResponse',
        subBuilder: ChangePasswordResponse.create)
    ..aOM<FetchSystemStatsResponse>(
        30, _omitFieldNames ? '' : 'fetchSystemStatsResponse',
        subBuilder: FetchSystemStatsResponse.create)
    ..aOM<ClaimSupportLikeRewardResponse>(
        31, _omitFieldNames ? '' : 'claimSupportLikeRewardResponse',
        subBuilder: ClaimSupportLikeRewardResponse.create)
    ..aOM<SubmitSupportLikeResponse>(
        32, _omitFieldNames ? '' : 'submitSupportLikeResponse',
        subBuilder: SubmitSupportLikeResponse.create)
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
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
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
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(25)
  @$pb.TagNumber(26)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
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

  @$pb.TagNumber(18)
  ResetPasswordResponse get resetPasswordResponse => $_getN(9);
  @$pb.TagNumber(18)
  set resetPasswordResponse(ResetPasswordResponse value) =>
      $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasResetPasswordResponse() => $_has(9);
  @$pb.TagNumber(18)
  void clearResetPasswordResponse() => $_clearField(18);
  @$pb.TagNumber(18)
  ResetPasswordResponse ensureResetPasswordResponse() => $_ensure(9);

  @$pb.TagNumber(19)
  ListFriendsResponse get listFriendsResponse => $_getN(10);
  @$pb.TagNumber(19)
  set listFriendsResponse(ListFriendsResponse value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasListFriendsResponse() => $_has(10);
  @$pb.TagNumber(19)
  void clearListFriendsResponse() => $_clearField(19);
  @$pb.TagNumber(19)
  ListFriendsResponse ensureListFriendsResponse() => $_ensure(10);

  @$pb.TagNumber(20)
  AddFriendResponse get addFriendResponse => $_getN(11);
  @$pb.TagNumber(20)
  set addFriendResponse(AddFriendResponse value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasAddFriendResponse() => $_has(11);
  @$pb.TagNumber(20)
  void clearAddFriendResponse() => $_clearField(20);
  @$pb.TagNumber(20)
  AddFriendResponse ensureAddFriendResponse() => $_ensure(11);

  @$pb.TagNumber(21)
  InvitePlayerResponse get invitePlayerResponse => $_getN(12);
  @$pb.TagNumber(21)
  set invitePlayerResponse(InvitePlayerResponse value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasInvitePlayerResponse() => $_has(12);
  @$pb.TagNumber(21)
  void clearInvitePlayerResponse() => $_clearField(21);
  @$pb.TagNumber(21)
  InvitePlayerResponse ensureInvitePlayerResponse() => $_ensure(12);

  @$pb.TagNumber(22)
  RoomInvitationPush get roomInvitationPush => $_getN(13);
  @$pb.TagNumber(22)
  set roomInvitationPush(RoomInvitationPush value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasRoomInvitationPush() => $_has(13);
  @$pb.TagNumber(22)
  void clearRoomInvitationPush() => $_clearField(22);
  @$pb.TagNumber(22)
  RoomInvitationPush ensureRoomInvitationPush() => $_ensure(13);

  @$pb.TagNumber(23)
  RespondRoomInvitationResponse get respondRoomInvitationResponse => $_getN(14);
  @$pb.TagNumber(23)
  set respondRoomInvitationResponse(RespondRoomInvitationResponse value) =>
      $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasRespondRoomInvitationResponse() => $_has(14);
  @$pb.TagNumber(23)
  void clearRespondRoomInvitationResponse() => $_clearField(23);
  @$pb.TagNumber(23)
  RespondRoomInvitationResponse ensureRespondRoomInvitationResponse() =>
      $_ensure(14);

  @$pb.TagNumber(24)
  RoomInvitationResultPush get roomInvitationResultPush => $_getN(15);
  @$pb.TagNumber(24)
  set roomInvitationResultPush(RoomInvitationResultPush value) =>
      $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasRoomInvitationResultPush() => $_has(15);
  @$pb.TagNumber(24)
  void clearRoomInvitationResultPush() => $_clearField(24);
  @$pb.TagNumber(24)
  RoomInvitationResultPush ensureRoomInvitationResultPush() => $_ensure(15);

  @$pb.TagNumber(25)
  UpdateNicknameResponse get updateNicknameResponse => $_getN(16);
  @$pb.TagNumber(25)
  set updateNicknameResponse(UpdateNicknameResponse value) =>
      $_setField(25, value);
  @$pb.TagNumber(25)
  $core.bool hasUpdateNicknameResponse() => $_has(16);
  @$pb.TagNumber(25)
  void clearUpdateNicknameResponse() => $_clearField(25);
  @$pb.TagNumber(25)
  UpdateNicknameResponse ensureUpdateNicknameResponse() => $_ensure(16);

  @$pb.TagNumber(26)
  RespondFriendRequestResponse get respondFriendRequestResponse => $_getN(17);
  @$pb.TagNumber(26)
  set respondFriendRequestResponse(RespondFriendRequestResponse value) =>
      $_setField(26, value);
  @$pb.TagNumber(26)
  $core.bool hasRespondFriendRequestResponse() => $_has(17);
  @$pb.TagNumber(26)
  void clearRespondFriendRequestResponse() => $_clearField(26);
  @$pb.TagNumber(26)
  RespondFriendRequestResponse ensureRespondFriendRequestResponse() =>
      $_ensure(17);

  @$pb.TagNumber(27)
  DeleteFriendResponse get deleteFriendResponse => $_getN(18);
  @$pb.TagNumber(27)
  set deleteFriendResponse(DeleteFriendResponse value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasDeleteFriendResponse() => $_has(18);
  @$pb.TagNumber(27)
  void clearDeleteFriendResponse() => $_clearField(27);
  @$pb.TagNumber(27)
  DeleteFriendResponse ensureDeleteFriendResponse() => $_ensure(18);

  @$pb.TagNumber(28)
  FriendCenterPush get friendCenterPush => $_getN(19);
  @$pb.TagNumber(28)
  set friendCenterPush(FriendCenterPush value) => $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasFriendCenterPush() => $_has(19);
  @$pb.TagNumber(28)
  void clearFriendCenterPush() => $_clearField(28);
  @$pb.TagNumber(28)
  FriendCenterPush ensureFriendCenterPush() => $_ensure(19);

  @$pb.TagNumber(29)
  ChangePasswordResponse get changePasswordResponse => $_getN(20);
  @$pb.TagNumber(29)
  set changePasswordResponse(ChangePasswordResponse value) =>
      $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasChangePasswordResponse() => $_has(20);
  @$pb.TagNumber(29)
  void clearChangePasswordResponse() => $_clearField(29);
  @$pb.TagNumber(29)
  ChangePasswordResponse ensureChangePasswordResponse() => $_ensure(20);

  @$pb.TagNumber(30)
  FetchSystemStatsResponse get fetchSystemStatsResponse => $_getN(21);
  @$pb.TagNumber(30)
  set fetchSystemStatsResponse(FetchSystemStatsResponse value) =>
      $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasFetchSystemStatsResponse() => $_has(21);
  @$pb.TagNumber(30)
  void clearFetchSystemStatsResponse() => $_clearField(30);
  @$pb.TagNumber(30)
  FetchSystemStatsResponse ensureFetchSystemStatsResponse() => $_ensure(21);

  @$pb.TagNumber(31)
  ClaimSupportLikeRewardResponse get claimSupportLikeRewardResponse =>
      $_getN(22);
  @$pb.TagNumber(31)
  set claimSupportLikeRewardResponse(ClaimSupportLikeRewardResponse value) =>
      $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasClaimSupportLikeRewardResponse() => $_has(22);
  @$pb.TagNumber(31)
  void clearClaimSupportLikeRewardResponse() => $_clearField(31);
  @$pb.TagNumber(31)
  ClaimSupportLikeRewardResponse ensureClaimSupportLikeRewardResponse() =>
      $_ensure(22);

  @$pb.TagNumber(32)
  SubmitSupportLikeResponse get submitSupportLikeResponse => $_getN(23);
  @$pb.TagNumber(32)
  set submitSupportLikeResponse(SubmitSupportLikeResponse value) =>
      $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasSubmitSupportLikeResponse() => $_has(23);
  @$pb.TagNumber(32)
  void clearSubmitSupportLikeResponse() => $_clearField(32);
  @$pb.TagNumber(32)
  SubmitSupportLikeResponse ensureSubmitSupportLikeResponse() => $_ensure(23);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
