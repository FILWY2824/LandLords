part of 'local_demo_gateway.dart';

final _LocalDemoRuntime _localDemoRuntime = _LocalDemoRuntime();

class _LocalDemoRuntime {
  _LocalDemoRuntime() {
    _reset();
  }

  final Random _random = Random();
  final Map<String, _LocalUser> _usersByAccount = {};
  final Map<String, _LocalSession> _sessionsByToken = {};
  final Map<String, String> _activeSessionTokenByUserId = {};
  final Map<String, LocalDemoGateway> _gatewaysBySessionToken = {};
  final Map<String, _LocalPendingRoom> _pendingRoomsById = {};
  final Map<String, String> _pendingRoomIdByCode = {};
  final Map<String, _DemoRoom> _activeRoomsById = {};
  final Map<String, _LocalFriendRequest> _friendRequestsById = {};
  final Map<String, _LocalRoomInvitation> _invitationsById = {};
  final Map<String, _ResolvedRoomInvitation> _resolvedInvitationsById = {};
  final Map<String, String> _invitationIdByInviteeUserId = {};
  int _supportLikeCount = 0;

  void attachGateway(LocalDemoGateway gateway) {}

  void detachGateway(LocalDemoGateway gateway) {
    final sessionToken = gateway._sessionToken;
    if (sessionToken != null &&
        identical(_gatewaysBySessionToken[sessionToken], gateway)) {
      _gatewaysBySessionToken.remove(sessionToken);
    }
    gateway._sessionToken = null;
  }

  void register({
    required String account,
    required String nickname,
    required String password,
  }) {
    if (account.trim().isEmpty || nickname.trim().isEmpty || password.isEmpty) {
      throw Exception('昵称、账号和密码不能为空');
    }
    if (nickname.runes.length > 5) {
      throw Exception('昵称最多 5 个字');
    }
    if (_usersByAccount.containsKey(account)) {
      throw Exception('账号已存在');
    }
    _usersByAccount[account] = _LocalUser(
      profile: UserProfile(
        userId: _id('user'),
        account: account,
        nickname: nickname,
        coins: 100,
      ),
      password: password,
    );
  }

  SupportStats fetchSupportStats() {
    return SupportStats(supportLikeCount: _supportLikeCount);
  }

  SupportStats submitSupportLike() {
    _supportLikeCount += 1;
    return fetchSupportStats();
  }

  SupportRewardResult claimSupportLikeReward(String sessionToken) {
    final session = _requireSession(sessionToken);
    final user = _userById(session.userId);
    if (user.profile.coins >= 0) {
      throw Exception('support reward not available');
    }
    user.profile = user.profile.copyWith(coins: user.profile.coins + 50);
    _supportLikeCount += 1;
    return SupportRewardResult(
      profile: user.profile,
      stats: fetchSupportStats(),
      rewardCoins: 50,
    );
  }

  LoginResult login({
    required LocalDemoGateway gateway,
    required String account,
    required String password,
  }) {
    final user = _usersByAccount[account];
    if (user == null || user.password != password) {
      throw Exception('账号或密码错误');
    }

    if (gateway._sessionToken != null) {
      forgetSession(gateway);
    }

    final previousToken = _activeSessionTokenByUserId[user.profile.userId];
    var reconnectRoomId = '';
    if (previousToken != null) {
      final previousSession = _sessionsByToken.remove(previousToken);
      if (previousSession != null) {
        reconnectRoomId = _resolveReconnectableRoomId(
          user.profile.userId,
          previousSession.roomId,
        );
      }
      final previousGateway = _gatewaysBySessionToken.remove(previousToken);
      _activeSessionTokenByUserId.remove(user.profile.userId);
      if (previousGateway != null) {
        previousGateway._sessionToken = null;
        previousGateway._emitNotification(
          const SessionExpiredNotification('account logged in on another device'),
        );
      }
    }

    final sessionToken = _id('session');
    gateway._sessionToken = sessionToken;
    _sessionsByToken[sessionToken] = _LocalSession(
      sessionToken: sessionToken,
      userId: user.profile.userId,
      roomId: reconnectRoomId,
    );
    _activeSessionTokenByUserId[user.profile.userId] = sessionToken;
    _gatewaysBySessionToken[sessionToken] = gateway;

    _pushFriendCenterUpdates({...user.friendUserIds, user.profile.userId});
    return LoginResult(profile: user.profile, sessionToken: sessionToken);
  }

  void resetPassword({
    required String account,
    required String newPassword,
  }) {
    final user = _usersByAccount[account];
    if (user == null) {
      throw Exception('账号不存在');
    }
    if (newPassword.isEmpty) {
      throw Exception('新密码不能为空');
    }
    _usersByAccount[account] = _LocalUser(
      profile: user.profile,
      password: newPassword,
      friendUserIds: user.friendUserIds,
    );
  }

  void changePassword({
    required String sessionToken,
    required String currentPassword,
    required String newPassword,
  }) {
    final session = _requireSession(sessionToken);
    final user = _userById(session.userId);
    if (user.password != currentPassword) {
      throw Exception('当前密码错误');
    }
    if (newPassword.isEmpty) {
      throw Exception('新密码不能为空');
    }
    _usersByAccount[user.profile.account] = _LocalUser(
      profile: user.profile,
      password: newPassword,
      friendUserIds: user.friendUserIds,
    );
  }

  UserProfile updateNickname({
    required String sessionToken,
    required String nickname,
  }) {
    final session = _requireSession(sessionToken);
    final user = _userById(session.userId);
    user.profile = user.profile.copyWith(nickname: nickname);

    final pendingRoom = _pendingRoomsById[session.roomId];
    if (pendingRoom != null) {
      for (final seat in pendingRoom.seats) {
        if (seat.playerId == session.userId) {
          seat.displayName = user.profile.displayName;
        }
      }
      _pushPendingRoomSnapshots(pendingRoom);
    }
    return user.profile;
  }

  RoomSnapshot startMatch({
    required LocalDemoGateway gateway,
    required String sessionToken,
    required MatchMode mode,
    required BotDifficulty botDifficulty,
  }) {
    final session = _requireSession(sessionToken);
    _releaseTransientBotRoom(session);
    if (!_ensureSessionRoomAvailable(session)) {
      throw Exception('already in room');
    }
    if (session.roomId.isNotEmpty) {
      session.roomId = '';
    }

    final owner = _userById(session.userId).profile;
    final room = _DemoRoom.create(
      roomId: _id('room'),
      random: _random,
      owner: owner,
      mode: mode,
    );
    _activeRoomsById[room.roomId] = room;
    session.roomId = room.roomId;
    room.driveBotsIfNeeded();
    _persistRoomScoreIfNeeded(room);
    _pushActiveRoomSnapshots(room);
    final snapshot = room.snapshotFor(session.userId);
    gateway._emitSnapshot(snapshot);
    return snapshot;
  }

  RoomSnapshot createRoom({
    required LocalDemoGateway gateway,
    required String sessionToken,
  }) {
    final session = _requireSession(sessionToken);
    _releaseTransientBotRoom(session);
    if (!_ensureSessionRoomAvailable(session)) {
      throw Exception('already in room');
    }

    final owner = _userById(session.userId).profile;
    final room = _LocalPendingRoom(
      roomId: _id('room'),
      roomCode: _generateRoomCode(),
      ownerPlayerId: owner.userId,
      seats: [
        _PendingSeat(
          playerId: owner.userId,
          displayName: owner.displayName,
        ),
        _PendingSeat.empty(),
        _PendingSeat.empty(),
      ],
    );
    _pendingRoomsById[room.roomId] = room;
    _pendingRoomIdByCode[room.roomCode] = room.roomId;
    session.roomId = room.roomId;
    final snapshot = _buildPendingRoomSnapshot(room, session.userId);
    gateway._emitSnapshot(snapshot);
    return snapshot;
  }

  RoomSnapshot joinRoom({
    required LocalDemoGateway gateway,
    required String sessionToken,
    required String roomCode,
  }) {
    final session = _requireSession(sessionToken);
    _releaseTransientBotRoom(session);
    if (!_ensureSessionRoomAvailable(session)) {
      throw Exception('already in room');
    }

    final roomId = _pendingRoomIdByCode[roomCode];
    if (roomId == null) {
      throw Exception('room not found');
    }
    final room = _pendingRoomsById[roomId];
    if (room == null) {
      _pendingRoomIdByCode.remove(roomCode);
      throw Exception('room not found');
    }

    var seatIndex = -1;
    for (var index = 0; index < room.seats.length; index++) {
      final seat = room.seats[index];
      if (seat.playerId == session.userId) {
        seatIndex = index;
        break;
      }
      if (seatIndex == -1 && seat.playerId.isEmpty) {
        seatIndex = index;
      }
    }
    if (seatIndex == -1) {
      throw Exception('room is full');
    }

    final user = _userById(session.userId).profile;
    room.seats[seatIndex] = _PendingSeat(
      playerId: user.userId,
      displayName: user.displayName,
    );
    session.roomId = room.roomId;
    _pushPendingRoomSnapshots(room);
    if (room.seats.every((seat) => seat.playerId.isNotEmpty)) {
      _expireInvitationsForRoom(room.roomId, 'room is full');
    }

    final snapshot = _buildPendingRoomSnapshot(room, session.userId);
    gateway._emitSnapshot(snapshot);
    return snapshot;
  }

  void leaveRoom({
    required LocalDemoGateway gateway,
    required String sessionToken,
    required String roomId,
  }) {
    final session = _requireSession(sessionToken);
    if (_pendingRoomsById.containsKey(roomId)) {
      _removeSessionFromPendingRoom(session, roomId);
      return;
    }

    final activeRoom = _activeRoomsById[roomId];
    if (activeRoom == null) {
      throw Exception('room not found');
    }
    if (session.roomId != roomId) {
      throw Exception('player not in room');
    }
    if (activeRoom.mode != MatchMode.vsBot) {
      throw Exception('room already started');
    }
    _activeRoomsById.remove(roomId);
    session.roomId = '';
  }

  RoomSnapshot setRoomReady({
    required LocalDemoGateway gateway,
    required String sessionToken,
    required String roomId,
    required bool ready,
  }) {
    final session = _requireSession(sessionToken);
    final room = _pendingRoomsById[roomId];
    if (room == null) {
      throw Exception('room already started');
    }

    var foundSeat = false;
    for (final seat in room.seats) {
      if (seat.playerId != session.userId) {
        continue;
      }
      seat.ready = ready;
      foundSeat = true;
      break;
    }
    if (!foundSeat) {
      throw Exception('player not in room');
    }

    if (_isPendingRoomReadyToStart(room)) {
      final activeRoom = _startPreparedRoom(room);
      final snapshot = activeRoom.snapshotFor(session.userId);
      gateway._emitSnapshot(snapshot);
      return snapshot;
    }

    _pushPendingRoomSnapshots(room);
    final snapshot = _buildPendingRoomSnapshot(room, session.userId);
    gateway._emitSnapshot(snapshot);
    return snapshot;
  }

  RoomSnapshot addBot({
    required LocalDemoGateway gateway,
    required String sessionToken,
    required String roomId,
    required int seatIndex,
    required BotDifficulty botDifficulty,
  }) {
    final session = _requireSession(sessionToken);
    final room = _pendingRoomsById[roomId];
    if (room == null) {
      throw Exception('room not found');
    }
    if (room.ownerPlayerId != session.userId) {
      throw Exception('only host can add bot');
    }
    if (seatIndex < 0 || seatIndex >= room.seats.length) {
      throw Exception('invalid seat');
    }
    if (room.seats[seatIndex].playerId.isNotEmpty) {
      throw Exception('room is full');
    }

    room.seats[seatIndex] = _PendingSeat(
      playerId: _id('bot'),
      displayName: 'robot',
      isBot: true,
      ready: true,
      botDifficulty: botDifficulty,
    );
    if (_isPendingRoomReadyToStart(room)) {
      final activeRoom = _startPreparedRoom(room);
      final snapshot = activeRoom.snapshotFor(session.userId);
      gateway._emitSnapshot(snapshot);
      return snapshot;
    }

    _pushPendingRoomSnapshots(room);
    final snapshot = _buildPendingRoomSnapshot(room, session.userId);
    gateway._emitSnapshot(snapshot);
    return snapshot;
  }

  RoomSnapshot removePlayer({
    required LocalDemoGateway gateway,
    required String sessionToken,
    required String roomId,
    required String playerId,
  }) {
    final session = _requireSession(sessionToken);
    final room = _pendingRoomsById[roomId];
    if (room == null) {
      throw Exception('room not found');
    }
    if (room.ownerPlayerId != session.userId) {
      throw Exception('only host can remove players');
    }
    if (playerId == session.userId) {
      throw Exception('cannot remove yourself');
    }

    _PendingSeat? removedSeat;
    for (var index = 0; index < room.seats.length; index++) {
      if (room.seats[index].playerId != playerId) {
        continue;
      }
      removedSeat = room.seats[index];
      room.seats[index] = _PendingSeat.empty();
      break;
    }
    if (removedSeat == null) {
      throw Exception('player not found');
    }

    if (!removedSeat.isBot) {
      final removedToken = _activeSessionTokenByUserId[playerId];
      final removedSession =
          removedToken == null ? null : _sessionsByToken[removedToken];
      if (removedSession != null && removedSession.roomId == room.roomId) {
        removedSession.roomId = '';
      }
    }

    _expireInvitationsForRoom(room.roomId, 'room seats changed');
    _pushPendingRoomSnapshots(room);
    final snapshot = _buildPendingRoomSnapshot(room, session.userId);
    gateway._emitSnapshot(snapshot);
    return snapshot;
  }

  RoomSnapshot? refreshCurrentRoom(String sessionToken) {
    final session = _requireSession(sessionToken);
    if (session.roomId.isEmpty) {
      return null;
    }
    return currentSnapshot(sessionToken: sessionToken, roomId: session.roomId);
  }

  RoomSnapshot? currentSnapshot({
    required String sessionToken,
    required String roomId,
  }) {
    final session = _requireSession(sessionToken);
    if (roomId.isEmpty || session.roomId != roomId) {
      return null;
    }

    final pendingRoom = _pendingRoomsById[roomId];
    if (pendingRoom != null) {
      final playerInRoom = pendingRoom.seats.any(
        (seat) => seat.playerId == session.userId,
      );
      if (!playerInRoom) {
        session.roomId = '';
        return null;
      }
      return _buildPendingRoomSnapshot(pendingRoom, session.userId);
    }

    final activeRoom = _activeRoomsById[roomId];
    if (activeRoom == null ||
        !activeRoom.players.any((player) => player.playerId == session.userId)) {
      session.roomId = '';
      return null;
    }
    return activeRoom.snapshotFor(session.userId);
  }

  void rebindGateway(LocalDemoGateway gateway) {
    final sessionToken = gateway._sessionToken;
    if (sessionToken == null) {
      return;
    }
    _gatewaysBySessionToken[sessionToken] = gateway;
  }

  void forgetSession(LocalDemoGateway gateway) {
    final sessionToken = gateway._sessionToken;
    gateway._sessionToken = null;
    if (sessionToken == null) {
      return;
    }
    if (identical(_gatewaysBySessionToken[sessionToken], gateway)) {
      _gatewaysBySessionToken.remove(sessionToken);
    }

    final session = _sessionsByToken.remove(sessionToken);
    if (session == null) {
      return;
    }
    if (_activeSessionTokenByUserId[session.userId] == sessionToken) {
      _activeSessionTokenByUserId.remove(session.userId);
    }

    final pendingInvitationId = _invitationIdByInviteeUserId[session.userId];
    if (pendingInvitationId != null) {
      final invitation = _invitationsById[pendingInvitationId];
      if (invitation != null) {
        _rememberFailedInvitation(
          invitation: invitation,
          detail: 'player is offline',
          result: InvitationFeedbackStatus.expired,
        );
      }
    }

    if (_pendingRoomsById.containsKey(session.roomId)) {
      _removeSessionFromPendingRoom(session, session.roomId);
    } else {
      session.roomId = '';
    }

    final user = _userById(session.userId);
    _pushFriendCenterUpdates({...user.friendUserIds, user.profile.userId});
  }

  bool _ensureSessionRoomAvailable(_LocalSession session) {
    if (session.roomId.isEmpty) {
      return true;
    }
    if (_pendingRoomsById.containsKey(session.roomId)) {
      return false;
    }
    final activeRoom = _activeRoomsById[session.roomId];
    if (activeRoom == null) {
      return true;
    }
    return activeRoom.phase == RoomPhase.finished;
  }

  void _releaseTransientBotRoom(_LocalSession session) {
    if (session.roomId.isEmpty) {
      return;
    }
    final activeRoom = _activeRoomsById[session.roomId];
    if (activeRoom == null) {
      return;
    }
    if (activeRoom.phase == RoomPhase.finished ||
        activeRoom.mode == MatchMode.vsBot) {
      _activeRoomsById.remove(session.roomId);
      session.roomId = '';
    }
  }

  bool _sessionCanJoinPendingRoom(_LocalSession session, String targetRoomId) {
    if (session.roomId.isEmpty || session.roomId == targetRoomId) {
      return true;
    }
    if (_pendingRoomsById.containsKey(session.roomId)) {
      return true;
    }
    final activeRoom = _activeRoomsById[session.roomId];
    if (activeRoom == null) {
      return true;
    }
    return activeRoom.phase == RoomPhase.finished;
  }

  void _persistRoomScoreIfNeeded(_DemoRoom room) {
    if (room.phase != RoomPhase.finished || room.scoresPersisted) {
      return;
    }
    room.scoresPersisted = true;
    for (final player in room.players) {
      if (player.isBot) {
        continue;
      }
      final user = _userById(player.playerId);
      user.profile = UserProfile(
        userId: user.profile.userId,
        account: user.profile.account,
        nickname: user.profile.nickname,
        coins: user.profile.coins + player.roundScore,
        landlordWins: user.profile.landlordWins +
            (player.isLandlord && player.roundScore > 0 ? 1 : 0),
        landlordGames: user.profile.landlordGames + (player.isLandlord ? 1 : 0),
        farmerWins:
            user.profile.farmerWins + (!player.isLandlord && player.roundScore > 0 ? 1 : 0),
        farmerGames: user.profile.farmerGames + (!player.isLandlord ? 1 : 0),
        onlineLandlordWins: user.profile.onlineLandlordWins +
            (room.mode == MatchMode.online && player.isLandlord && player.roundScore > 0 ? 1 : 0),
        onlineLandlordGames: user.profile.onlineLandlordGames +
            (room.mode == MatchMode.online && player.isLandlord ? 1 : 0),
        onlineFarmerWins: user.profile.onlineFarmerWins +
            (room.mode == MatchMode.online && !player.isLandlord && player.roundScore > 0 ? 1 : 0),
        onlineFarmerGames: user.profile.onlineFarmerGames +
            (room.mode == MatchMode.online && !player.isLandlord ? 1 : 0),
        botLandlordWins: user.profile.botLandlordWins +
            (room.mode == MatchMode.vsBot && player.isLandlord && player.roundScore > 0 ? 1 : 0),
        botLandlordGames: user.profile.botLandlordGames +
            (room.mode == MatchMode.vsBot && player.isLandlord ? 1 : 0),
        botFarmerWins: user.profile.botFarmerWins +
            (room.mode == MatchMode.vsBot && !player.isLandlord && player.roundScore > 0 ? 1 : 0),
        botFarmerGames: user.profile.botFarmerGames +
            (room.mode == MatchMode.vsBot && !player.isLandlord ? 1 : 0),
      );
    }
  }

  void _pushPendingRoomSnapshots(_LocalPendingRoom room) {
    for (final seat in room.seats) {
      if (seat.playerId.isEmpty || seat.isBot) {
        continue;
      }
      final sessionToken = _activeSessionTokenByUserId[seat.playerId];
      if (sessionToken == null) {
        continue;
      }
      final gateway = _gatewaysBySessionToken[sessionToken];
      if (gateway == null) {
        continue;
      }
      gateway._emitSnapshot(_buildPendingRoomSnapshot(room, seat.playerId));
    }
  }

  void _pushActiveRoomSnapshots(_DemoRoom room) {
    for (final player in room.players) {
      if (player.isBot) {
        continue;
      }
      final sessionToken = _activeSessionTokenByUserId[player.playerId];
      if (sessionToken == null) {
        continue;
      }
      final session = _sessionsByToken[sessionToken];
      final gateway = _gatewaysBySessionToken[sessionToken];
      if (session == null || gateway == null) {
        continue;
      }
      session.roomId = room.roomId;
      gateway._emitSnapshot(room.snapshotFor(player.playerId));
    }
  }

  RoomSnapshot _buildPendingRoomSnapshot(
    _LocalPendingRoom room,
    String audiencePlayerId,
  ) {
    final occupiedCount = room.seats.where((seat) => seat.playerId.isNotEmpty).length;
    final readyCount = room.seats.where((seat) => seat.ready).length;
    final statusText = occupiedCount < 3
        ? 'waiting_for_players'
        : readyCount < 3
            ? 'waiting_for_ready'
            : 'ready_to_start';

    return RoomSnapshot(
      roomId: room.roomId,
      roomCode: room.roomCode,
      ownerPlayerId: room.ownerPlayerId,
      mode: MatchMode.online,
      phase: RoomPhase.preparing,
      players: List<RoomPlayer>.generate(3, (index) {
        final seat = room.seats[index];
        final occupied = seat.playerId.isNotEmpty;
        return RoomPlayer(
          playerId: occupied ? seat.playerId : '',
          displayName: occupied ? seat.displayName : 'empty',
          isBot: seat.isBot,
          role: PlayerRole.farmer,
          cardsLeft: 0,
          roundScore: 0,
          seatIndex: index,
          ready: occupied && seat.ready,
          occupied: occupied,
        );
      }),
      selfCards: const [],
      landlordCards: const [],
      recentActions: const [],
      currentTurnPlayerId: '',
      statusText: statusText,
      cardCounter: const [],
      baseScore: 1,
      multiplier: 1,
      currentRoundScore: 0,
      springTriggered: false,
      turnSerial: 0,
    );
  }

  _DemoRoom _startPreparedRoom(_LocalPendingRoom room) {
    _expireInvitationsForRoom(room.roomId, 'room started');
    final activeRoom = _DemoRoom.fromPreparedSeats(
      roomId: room.roomId,
      random: _random,
      ownerId: room.ownerPlayerId,
      mode: MatchMode.online,
      seats: room.seats,
    );
    _activeRoomsById[room.roomId] = activeRoom;
    _pendingRoomIdByCode.remove(room.roomCode);
    _pendingRoomsById.remove(room.roomId);
    _pushActiveRoomSnapshots(activeRoom);
    return activeRoom;
  }

  void _removeSessionFromPendingRoom(_LocalSession session, String roomId) {
    final room = _pendingRoomsById[roomId];
    if (room == null) {
      session.roomId = '';
      return;
    }

    var removed = false;
    for (var index = 0; index < room.seats.length; index++) {
      if (room.seats[index].playerId != session.userId) {
        continue;
      }
      room.seats[index] = _PendingSeat.empty();
      removed = true;
      break;
    }
    session.roomId = '';
    if (!removed) {
      return;
    }

    if (room.ownerPlayerId == session.userId) {
      room.ownerPlayerId = '';
      for (final seat in room.seats) {
        if (seat.playerId.isNotEmpty && !seat.isBot) {
          room.ownerPlayerId = seat.playerId;
          break;
        }
      }
    }

    final hasAnyPlayer = room.seats.any((seat) => seat.playerId.isNotEmpty);
    if (!hasAnyPlayer) {
      _expireInvitationsForRoom(room.roomId, 'room closed');
      _pendingRoomIdByCode.remove(room.roomCode);
      _pendingRoomsById.remove(room.roomId);
      return;
    }

    _expireInvitationsForRoom(room.roomId, 'room seats changed');
    _pushPendingRoomSnapshots(room);
  }

  bool _isPendingRoomReadyToStart(_LocalPendingRoom room) {
    for (final seat in room.seats) {
      if (seat.playerId.isEmpty || !seat.ready) {
        return false;
      }
    }
    return true;
  }

  String _generateRoomCode() {
    late String roomCode;
    do {
      roomCode = List<String>.generate(
        6,
        (_) => _random.nextInt(10).toString(),
      ).join();
    } while (_pendingRoomIdByCode.containsKey(roomCode));
    return roomCode;
  }

  _DemoRoom _requireActiveRoom(String roomId) {
    final room = _activeRoomsById[roomId];
    if (room == null) {
      throw Exception('room not found');
    }
    return room;
  }

  Future<FriendCenterSnapshot> fetchFriendCenter(String sessionToken) async {
    return _buildFriendCenterSnapshot(_requireSession(sessionToken).userId);
  }

  FriendCenterSnapshot sendFriendRequest({
    required String sessionToken,
    required String account,
  }) {
    final requesterId = _requireSession(sessionToken).userId;
    final requester = _userById(requesterId);
    final receiver = _usersByAccount[account];
    if (receiver == null) {
      throw Exception('account not found');
    }
    if (receiver.profile.userId == requesterId) {
      throw Exception('cannot add yourself');
    }
    if (requester.friendUserIds.contains(receiver.profile.userId)) {
      throw Exception('friend already exists');
    }

    final existing = _findPendingFriendRequestBetween(
      requesterId,
      receiver.profile.userId,
    );
    if (existing != null) {
      throw Exception(
        existing.requesterUserId == requesterId
            ? 'friend request already sent'
            : 'target already sent you a request',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final request = _LocalFriendRequest(
      requestId: _id('friend-request'),
      requesterUserId: requesterId,
      receiverUserId: receiver.profile.userId,
      status: FriendRequestStatus.pending,
      createdAtMs: now,
      updatedAtMs: now,
    );
    _friendRequestsById[request.requestId] = request;
    _pushFriendCenterUpdates({requesterId, receiver.profile.userId});
    return _buildFriendCenterSnapshot(requesterId);
  }

  FriendCenterSnapshot respondFriendRequest({
    required String sessionToken,
    required String requestId,
    required bool accept,
  }) {
    final userId = _requireSession(sessionToken).userId;
    final request = _friendRequestsById[requestId];
    if (request == null || request.receiverUserId != userId) {
      throw Exception('friend request not found');
    }
    if (request.status != FriendRequestStatus.pending) {
      throw Exception('friend request already handled');
    }

    request.status =
        accept ? FriendRequestStatus.accepted : FriendRequestStatus.rejected;
    request.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    if (accept) {
      final requester = _userById(request.requesterUserId);
      final receiver = _userById(request.receiverUserId);
      requester.friendUserIds.add(receiver.profile.userId);
      receiver.friendUserIds.add(requester.profile.userId);
    }
    _pushFriendCenterUpdates({request.requesterUserId, request.receiverUserId});
    return _buildFriendCenterSnapshot(userId);
  }

  FriendCenterSnapshot deleteFriend({
    required String sessionToken,
    required String friendUserId,
  }) {
    final userId = _requireSession(sessionToken).userId;
    final user = _userById(userId);
    final friend = _userById(friendUserId);
    user.friendUserIds.remove(friendUserId);
    friend.friendUserIds.remove(userId);
    _pushFriendCenterUpdates({userId, friendUserId});
    return _buildFriendCenterSnapshot(userId);
  }

  void invitePlayer({
    required String sessionToken,
    required String roomId,
    required String targetAccount,
    required int seatIndex,
  }) {
    final inviterSession = _requireSession(sessionToken);
    final room = _pendingRoomsById[roomId];
    if (room == null) {
      throw Exception('room not found');
    }
    if (room.ownerPlayerId != inviterSession.userId) {
      throw Exception('only host can invite players');
    }
    if (targetAccount.isEmpty ||
        targetAccount == _userById(inviterSession.userId).profile.account) {
      throw Exception('invalid invite target');
    }
    if (seatIndex < 0 || seatIndex >= room.seats.length) {
      throw Exception('invalid seat');
    }

    final targetUser = _usersByAccount[targetAccount];
    if (targetUser == null) {
      throw Exception('player not found');
    }
    if (_invitationIdByInviteeUserId.containsKey(targetUser.profile.userId)) {
      throw Exception('player is handling another invitation');
    }

    var hasEmptySeat = false;
    var alreadyInRoom = false;
    for (final seat in room.seats) {
      if (seat.playerId.isEmpty) {
        hasEmptySeat = true;
      }
      if (seat.playerId == targetUser.profile.userId) {
        alreadyInRoom = true;
      }
    }
    if (!hasEmptySeat) {
      throw Exception('room is full');
    }
    if (alreadyInRoom) {
      throw Exception('player already in room');
    }
    if (room.seats[seatIndex].playerId.isNotEmpty) {
      throw Exception('seat is occupied');
    }

    final inviteeToken = _activeSessionTokenByUserId[targetUser.profile.userId];
    final inviteeSession =
        inviteeToken == null ? null : _sessionsByToken[inviteeToken];
    if (inviteeSession == null) {
      throw Exception('player is offline');
    }
    if (!_sessionCanJoinPendingRoom(inviteeSession, room.roomId)) {
      throw Exception('player is not available');
    }

    final inviter = _userById(inviterSession.userId).profile;
    final invitation = _LocalRoomInvitation(
      invitationId: _id('invite'),
      roomId: room.roomId,
      roomCode: room.roomCode,
      inviterUserId: inviter.userId,
      inviterAccount: inviter.account,
      inviterNickname: inviter.nickname,
      inviteeUserId: targetUser.profile.userId,
      inviteeAccount: targetUser.profile.account,
      inviteeNickname: targetUser.profile.nickname,
      seatIndex: seatIndex,
    );
    _invitationsById[invitation.invitationId] = invitation;
    _invitationIdByInviteeUserId[invitation.inviteeUserId] =
        invitation.invitationId;
    _sendInvitationReceived(invitation);
  }

  RoomSnapshot? respondInvitation({
    required LocalDemoGateway gateway,
    required String sessionToken,
    required String invitationId,
    required bool accept,
  }) {
    final session = _requireSession(sessionToken);
    final invitation = _invitationsById[invitationId];
    if (invitation == null) {
      final resolved = _resolvedInvitationsById[invitationId];
      if (resolved == null || resolved.invitation.inviteeUserId != session.userId) {
        throw Exception('invitation expired');
      }
      if (!resolved.success) {
        throw Exception(resolved.detail);
      }
      if (resolved.result == InvitationFeedbackStatus.accepted) {
        return refreshCurrentRoom(sessionToken);
      }
      return null;
    }
    if (invitation.inviteeUserId != session.userId) {
      throw Exception('invitation expired');
    }

    if (!accept) {
      _resolvedInvitationsById[invitationId] = _ResolvedRoomInvitation(
        invitation: invitation,
        success: true,
        result: InvitationFeedbackStatus.rejected,
        detail: 'invitation rejected',
      );
      _clearInvitation(invitationId);
      _sendInvitationFeedback(
        invitation,
        InvitationFeedbackStatus.rejected,
        'player rejected the invitation',
      );
      return null;
    }

    var room = _pendingRoomsById[invitation.roomId];
    if (room == null) {
      _rememberFailedInvitation(
        invitation: invitation,
        detail: 'room is no longer available',
        result: InvitationFeedbackStatus.expired,
      );
      throw Exception('room is no longer available');
    }
    if (!_sessionCanJoinPendingRoom(session, invitation.roomId)) {
      _rememberFailedInvitation(
        invitation: invitation,
        detail: 'player is currently in another room',
        result: InvitationFeedbackStatus.failed,
      );
      throw Exception('player is currently in another room');
    }

    var seatIndex = invitation.seatIndex;
    if (seatIndex < 0 || seatIndex >= room.seats.length) {
      seatIndex = -1;
    }
    if (seatIndex == -1) {
      for (var index = 0; index < room.seats.length; index++) {
        final seat = room.seats[index];
        if (seat.playerId == session.userId) {
          seatIndex = index;
          break;
        }
        if (seatIndex == -1 && seat.playerId.isEmpty) {
          seatIndex = index;
        }
      }
    } else if (room.seats[seatIndex].playerId.isNotEmpty &&
        room.seats[seatIndex].playerId != session.userId) {
      seatIndex = -1;
    }
    if (seatIndex == -1) {
      _rememberFailedInvitation(
        invitation: invitation,
        detail: 'room is full',
        result: InvitationFeedbackStatus.expired,
      );
      throw Exception('room is full');
    }

    if (session.roomId.isNotEmpty && session.roomId != invitation.roomId) {
      final previousRoomId = session.roomId;
      if (_pendingRoomsById.containsKey(previousRoomId)) {
        _removeSessionFromPendingRoom(session, previousRoomId);
        room = _pendingRoomsById[invitation.roomId];
        if (room == null) {
          _rememberFailedInvitation(
            invitation: invitation,
            detail: 'room is no longer available',
            result: InvitationFeedbackStatus.expired,
          );
          throw Exception('room is no longer available');
        }
      } else {
        session.roomId = '';
      }
    }

    final user = _userById(session.userId).profile;
    room.seats[seatIndex] = _PendingSeat(
      playerId: user.userId,
      displayName: user.displayName,
    );
    session.roomId = invitation.roomId;

    _resolvedInvitationsById[invitationId] = _ResolvedRoomInvitation(
      invitation: invitation,
      success: true,
      result: InvitationFeedbackStatus.accepted,
      detail: 'room_joined',
    );
    _clearInvitation(invitationId);
    _sendInvitationFeedback(
      invitation,
      InvitationFeedbackStatus.accepted,
      'player joined the room',
    );
    _pushPendingRoomSnapshots(room);
    if (room.seats.every((seat) => seat.playerId.isNotEmpty)) {
      _expireInvitationsForRoom(room.roomId, 'room is full');
    }

    final snapshot = _buildPendingRoomSnapshot(room, session.userId);
    gateway._emitSnapshot(snapshot);
    return snapshot;
  }

  RoomSnapshot playCards({
    required String sessionToken,
    required String roomId,
    required List<String> cardIds,
  }) {
    final session = _requireSession(sessionToken);
    final room = _requireActiveRoom(roomId);
    room.play(session.userId, cardIds);
    room.driveBotsIfNeeded();
    _persistRoomScoreIfNeeded(room);
    _pushActiveRoomSnapshots(room);
    return room.snapshotFor(session.userId);
  }

  RoomSnapshot setManaged({
    required String sessionToken,
    required String roomId,
    required bool managed,
  }) {
    final session = _requireSession(sessionToken);
    final room = _requireActiveRoom(roomId);
    room.statusText = managed ? 'managed on' : 'managed off';
    _pushActiveRoomSnapshots(room);
    return room.snapshotFor(session.userId);
  }

  RoomSnapshot pass({
    required String sessionToken,
    required String roomId,
  }) {
    final session = _requireSession(sessionToken);
    final room = _requireActiveRoom(roomId);
    room.pass(session.userId);
    room.driveBotsIfNeeded();
    _persistRoomScoreIfNeeded(room);
    _pushActiveRoomSnapshots(room);
    return room.snapshotFor(session.userId);
  }

  List<String> requestSuggestion({
    required String sessionToken,
    required String roomId,
  }) {
    final session = _requireSession(sessionToken);
    return _requireActiveRoom(roomId).suggest(session.userId);
  }

  _LocalFriendRequest? _findPendingFriendRequestBetween(
    String leftUserId,
    String rightUserId,
  ) {
    for (final request in _friendRequestsById.values) {
      final pairMatched =
          (request.requesterUserId == leftUserId &&
              request.receiverUserId == rightUserId) ||
          (request.requesterUserId == rightUserId &&
              request.receiverUserId == leftUserId);
      if (pairMatched && request.status == FriendRequestStatus.pending) {
        return request;
      }
    }
    return null;
  }

  void _sendInvitationReceived(_LocalRoomInvitation invitation) {
    final sessionToken = _activeSessionTokenByUserId[invitation.inviteeUserId];
    final gateway =
        sessionToken == null ? null : _gatewaysBySessionToken[sessionToken];
    if (gateway == null) {
      return;
    }
    gateway._emitNotification(
      RoomInvitationNotification(
        RoomInvitation(
          invitationId: invitation.invitationId,
          roomId: invitation.roomId,
          roomCode: invitation.roomCode,
          inviterUserId: invitation.inviterUserId,
          inviterAccount: invitation.inviterAccount,
          inviterNickname: invitation.inviterNickname,
          seatIndex: invitation.seatIndex,
        ),
      ),
    );
  }

  void _sendInvitationFeedback(
    _LocalRoomInvitation invitation,
    InvitationFeedbackStatus status,
    String detail,
  ) {
    final sessionToken = _activeSessionTokenByUserId[invitation.inviterUserId];
    final gateway =
        sessionToken == null ? null : _gatewaysBySessionToken[sessionToken];
    if (gateway == null) {
      return;
    }
    gateway._emitNotification(
      InvitationFeedbackNotification(
        InvitationFeedback(
          invitationId: invitation.invitationId,
          status: status,
          targetUserId: invitation.inviteeUserId,
          targetAccount: invitation.inviteeAccount,
          targetNickname: invitation.inviteeNickname,
          detail: detail,
        ),
      ),
    );
  }

  void _rememberFailedInvitation({
    required _LocalRoomInvitation invitation,
    required String detail,
    required InvitationFeedbackStatus result,
  }) {
    _resolvedInvitationsById[invitation.invitationId] = _ResolvedRoomInvitation(
      invitation: invitation,
      success: false,
      result: result,
      detail: detail,
    );
    _clearInvitation(invitation.invitationId);
    _sendInvitationFeedback(invitation, result, detail);
  }

  void _clearInvitation(String invitationId) {
    final invitation = _invitationsById.remove(invitationId);
    if (invitation != null &&
        _invitationIdByInviteeUserId[invitation.inviteeUserId] == invitationId) {
      _invitationIdByInviteeUserId.remove(invitation.inviteeUserId);
    }
  }

  void _expireInvitationsForRoom(String roomId, String detail) {
    final invitationIds = _invitationsById.values
        .where((invitation) => invitation.roomId == roomId)
        .map((invitation) => invitation.invitationId)
        .toList(growable: false);
    for (final invitationId in invitationIds) {
      final invitation = _invitationsById[invitationId];
      if (invitation == null) {
        continue;
      }
      _rememberFailedInvitation(
        invitation: invitation,
        detail: detail,
        result: InvitationFeedbackStatus.expired,
      );
    }
  }

  _LocalSession _requireSession(String sessionToken) {
    final session = _sessionsByToken[sessionToken];
    if (session == null) {
      throw Exception('请先登录');
    }
    if (_activeSessionTokenByUserId[session.userId] != sessionToken) {
      throw Exception('账号已在其他设备登录');
    }
    return session;
  }

  _LocalUser _userById(String userId) {
    return _usersByAccount.values.firstWhere(
      (user) => user.profile.userId == userId,
      orElse: () => throw Exception('玩家不存在'),
    );
  }

  void _pushFriendCenterUpdates(Iterable<String> userIds) {
    for (final userId in userIds.toSet()) {
      final sessionToken = _activeSessionTokenByUserId[userId];
      if (sessionToken == null) {
        continue;
      }
      final gateway = _gatewaysBySessionToken[sessionToken];
      if (gateway == null) {
        continue;
      }
      gateway._emitNotification(
        FriendCenterNotification(_buildFriendCenterSnapshot(userId)),
      );
    }
  }

  FriendCenterSnapshot _buildFriendCenterSnapshot(String userId) {
    final user = _userById(userId);
    final friends = user.friendUserIds
        .map(_userById)
        .map(_toOnlineUser)
        .toList()
      ..sort((left, right) {
        if (left.online != right.online) {
          return left.online ? -1 : 1;
        }
        final byName = left.displayName.compareTo(right.displayName);
        if (byName != 0) {
          return byName;
        }
        return left.account.compareTo(right.account);
      });

    final requests = _friendRequestsById.values
        .where(
          (request) =>
              request.requesterUserId == userId || request.receiverUserId == userId,
        )
        .toList()
      ..sort((left, right) => right.updatedAtMs.compareTo(left.updatedAtMs));

    final pendingRequests = <FriendRequestEntry>[];
    final historyRequests = <FriendRequestEntry>[];
    for (final request in requests) {
      final entry = _toFriendRequestEntry(request);
      final incoming = request.receiverUserId == userId;
      if (incoming && request.status == FriendRequestStatus.pending) {
        pendingRequests.add(entry);
      } else {
        historyRequests.add(entry);
      }
    }

    return FriendCenterSnapshot(
      friends: friends,
      pendingRequests: pendingRequests,
      historyRequests: historyRequests,
      pendingRequestCount: pendingRequests.length,
    );
  }

  OnlineUser _toOnlineUser(_LocalUser user) => OnlineUser(
        userId: user.profile.userId,
        account: user.profile.account,
        nickname: user.profile.nickname,
        online: _activeSessionTokenByUserId.containsKey(user.profile.userId),
      );

  FriendRequestEntry _toFriendRequestEntry(_LocalFriendRequest request) {
    final requester = _userById(request.requesterUserId);
    final receiver = _userById(request.receiverUserId);
    return FriendRequestEntry(
      requestId: request.requestId,
      requesterUserId: request.requesterUserId,
      requesterAccount: requester.profile.account,
      requesterNickname: requester.profile.nickname,
      receiverUserId: request.receiverUserId,
      receiverAccount: receiver.profile.account,
      receiverNickname: receiver.profile.nickname,
      status: request.status,
      createdAtMs: request.createdAtMs,
      updatedAtMs: request.updatedAtMs,
    );
  }

  String _resolveReconnectableRoomId(String userId, String preferredRoomId) {
    if (preferredRoomId.isNotEmpty) {
      final preferredPending = _pendingRoomsById[preferredRoomId];
      if (preferredPending != null &&
          preferredPending.seats.any((seat) => seat.playerId == userId)) {
        return preferredRoomId;
      }
      final preferredActive = _activeRoomsById[preferredRoomId];
      if (preferredActive != null &&
          preferredActive.players.any((player) => player.playerId == userId)) {
        return preferredRoomId;
      }
    }

    for (final room in _pendingRoomsById.values) {
      if (room.seats.any((seat) => seat.playerId == userId)) {
        return room.roomId;
      }
    }
    for (final room in _activeRoomsById.values) {
      if (room.players.any((player) => player.playerId == userId)) {
        return room.roomId;
      }
    }
    return '';
  }

  void _reset() {
    _usersByAccount
      ..clear()
      ..['player1'] = _LocalUser(
        profile: const UserProfile(
          userId: 'demo-user',
          account: 'player1',
          nickname: '玩家1',
          coins: 1888,
          landlordWins: 8,
          landlordGames: 15,
          farmerWins: 18,
          farmerGames: 29,
          onlineLandlordWins: 3,
          onlineLandlordGames: 7,
          onlineFarmerWins: 8,
          onlineFarmerGames: 14,
          botLandlordWins: 5,
          botLandlordGames: 8,
          botFarmerWins: 10,
          botFarmerGames: 15,
        ),
        password: 'player1',
      );
    _sessionsByToken.clear();
    _activeSessionTokenByUserId.clear();
    _gatewaysBySessionToken.clear();
    _pendingRoomsById.clear();
    _pendingRoomIdByCode.clear();
    _activeRoomsById.clear();
    _friendRequestsById.clear();
    _invitationsById.clear();
    _resolvedInvitationsById.clear();
    _invitationIdByInviteeUserId.clear();
    _supportLikeCount = 0;
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(99999)}';
}

class _LocalSession {
  _LocalSession({
    required this.sessionToken,
    required this.userId,
    required this.roomId,
  });

  final String sessionToken;
  final String userId;
  String roomId;
}

class _PendingSeat {
  _PendingSeat({
    required this.playerId,
    required this.displayName,
    this.isBot = false,
    this.ready = false,
    this.botDifficulty = BotDifficulty.normal,
  });

  _PendingSeat.empty()
      : playerId = '',
        displayName = '',
        isBot = false,
        ready = false,
        botDifficulty = BotDifficulty.normal;

  String playerId;
  String displayName;
  bool isBot;
  bool ready;
  BotDifficulty botDifficulty;
}

class _LocalPendingRoom {
  _LocalPendingRoom({
    required this.roomId,
    required this.roomCode,
    required this.ownerPlayerId,
    required this.seats,
  });

  final String roomId;
  final String roomCode;
  String ownerPlayerId;
  final List<_PendingSeat> seats;
}

class _LocalRoomInvitation {
  _LocalRoomInvitation({
    required this.invitationId,
    required this.roomId,
    required this.roomCode,
    required this.inviterUserId,
    required this.inviterAccount,
    required this.inviterNickname,
    required this.inviteeUserId,
    required this.inviteeAccount,
    required this.inviteeNickname,
    required this.seatIndex,
  });

  final String invitationId;
  final String roomId;
  final String roomCode;
  final String inviterUserId;
  final String inviterAccount;
  final String inviterNickname;
  final String inviteeUserId;
  final String inviteeAccount;
  final String inviteeNickname;
  final int seatIndex;
}

class _ResolvedRoomInvitation {
  _ResolvedRoomInvitation({
    required this.invitation,
    required this.success,
    required this.result,
    required this.detail,
  });

  final _LocalRoomInvitation invitation;
  final bool success;
  final InvitationFeedbackStatus result;
  final String detail;
}
