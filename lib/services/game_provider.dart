// lib/services/game_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/piece.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';
import 'firebase_service.dart';
import 'bot_ai.dart';

class GameProvider extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();

  String? roomCode;
  String? playerRole;
  GamePhase phase = GamePhase.waiting;
  String currentTurn = 'player1';
  bool player1Ready = false;
  bool player2Ready = false;
  bool player2Joined = false;
  WinReason? winReason;
  String? winnerRole;
  bool showMoveHistory = false;
  String? drawOfferedBy;

  // Bot
  bool isBotGame = false;
  BotAI? bot;
  bool _botThinking = false;
  bool get botThinking => _botThinking;

  List<MoveRecord> moveHistory = [];
  Map<String, Map<String, dynamic>> board = {};

  // Challenge pending state — drives the challenge overlay
  Map<String, dynamic>? challengePending;
  bool get hasPendingChallenge => challengePending != null;
  String get challengePhase => challengePending?['phase'] ?? '';
  String get challengeAttackerRole => challengePending?['attackerRole'] ?? '';
  String get challengeAttackerRank => challengePending?['attackerRank'] ?? '';
  String get challengeDefenderRank => challengePending?['defenderRank'] ?? '';
  String get challengeOutcome => challengePending?['outcome'] ?? '';

  // Setup state (unique-indexed)
  Map<String, _IndexedPiece> _setupBoard = {};
  List<_IndexedPiece> _trayPieces = [];
  _IndexedPiece? _heldPiece;

  Map<String, Piece> get localSetupBoard =>
      _setupBoard.map((k, v) => MapEntry(k, v.piece));
  List<Piece> get unplacedPieces => _trayPieces.map((ip) => ip.piece).toList();
  Piece? get selectedTrayPiece => _heldPiece?.piece;

  BoardPosition? selectedPosition;
  StreamSubscription<DatabaseEvent>? _subscription;

  // ─── ROOM SETUP ───────────────────────────────────────────────────────────

  Future<String> createRoom() async {
    isBotGame = false;
    bot = null;
    final code = _generateRoomCode();
    roomCode = code;
    playerRole = 'player1';
    await _firebase.createRoom(code);
    _resetLocalSetup(PieceOwner.player1);
    _listenToRoom(code);
    notifyListeners();
    return code;
  }

  Future<bool> joinRoom(String code) async {
    final exists = await _firebase.roomExists(code);
    if (!exists) return false;
    isBotGame = false;
    bot = null;
    roomCode = code;
    playerRole = 'player2';
    await _firebase.joinRoom(code);
    _resetLocalSetup(PieceOwner.player2);
    _listenToRoom(code);
    notifyListeners();
    return true;
  }

  Future<void> startBotGame(BotDifficulty difficulty,
      {String role = 'player1', int rating = 800}) async {
    isBotGame = true;
    bot = BotAI.fromRating(rating);
    final code = _generateRoomCode();
    roomCode = code;
    playerRole = role;
    player2Joined = true;
    await _firebase.createRoom(code);
    final owner = role == 'player1' ? PieceOwner.player1 : PieceOwner.player2;
    _resetLocalSetup(owner);
    _listenToRoom(code);
    await _firebase.joinRoom(code);
    notifyListeners();
  }

  void _resetLocalSetup(PieceOwner owner) {
    _setupBoard = {};
    final pieces = createPieceSet(owner);
    _trayPieces =
        List.generate(pieces.length, (i) => _IndexedPiece(pieces[i], i));
    _heldPiece = null;
    selectedPosition = null;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    int n = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[n % chars.length];
      n ~/= chars.length;
    }
    return code;
  }

  // ─── REALTIME LISTENER ────────────────────────────────────────────────────

  void _listenToRoom(String code) {
    _subscription?.cancel();
    _subscription = _firebase.watchRoom(code).listen((event) {
      if (!event.snapshot.exists) return;
      _updateFromFirebase(event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  void _updateFromFirebase(Map<dynamic, dynamic> data) {
    phase = GamePhase.values.firstWhere(
        (p) => p.name == (data['phase'] ?? 'waiting'),
        orElse: () => GamePhase.waiting);
    currentTurn = data['currentTurn'] ?? 'player1';
    player1Ready = data['player1Ready'] ?? false;
    player2Ready = data['player2Ready'] ?? false;
    if (!isBotGame) player2Joined = data['player2Joined'] ?? false;
    drawOfferedBy = data['drawOfferedBy'];
    if (data['winnerRole'] != null) winnerRole = data['winnerRole'];
    if (data['winReason'] != null) {
      winReason = WinReason.values.firstWhere(
          (r) => r.name == data['winReason'],
          orElse: () => WinReason.draw);
    }

    // Challenge pending overlay
    if (data['challengePending'] != null) {
      challengePending =
          Map<String, dynamic>.from(data['challengePending'] as Map);
    } else {
      challengePending = null;
    }

    if (data['board'] != null) {
      final raw = data['board'] as Map<dynamic, dynamic>;
      board = raw.map((k, v) =>
          MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
    } else {
      board = {};
    }

    if (data['moveHistory'] != null) {
      final raw = data['moveHistory'] as Map<dynamic, dynamic>;
      moveHistory = raw.values.map((v) => MoveRecord.fromMap(v as Map)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    notifyListeners();

    if (isBotGame &&
        phase == GamePhase.playing &&
        currentTurn != playerRole &&
        !_botThinking &&
        !hasPendingChallenge) {
      _scheduleBotMove();
    }
  }

  // ─── BOT MOVE ─────────────────────────────────────────────────────────────

  void _scheduleBotMove() async {
    if (_botThinking || bot == null || roomCode == null) return;
    _botThinking = true;
    notifyListeners();
    await Future.delayed(_botThinkDelay());
    if (phase != GamePhase.playing || currentTurn == playerRole) {
      _botThinking = false;
      notifyListeners();
      return;
    }
    final botRole = playerRole == 'player1' ? 'player2' : 'player1';
    final move = bot!.chooseMove(board);
    if (move != null) {
      await _firebase.executeMove(
        roomCode: roomCode!,
        playerRole: botRole,
        from: move.from,
        to: move.to,
        currentBoard: board,
      );
    }
    _botThinking = false;
    notifyListeners();
  }

  Duration _botThinkDelay() {
    // Keep delays short and snappy — max 800ms even at highest difficulty
    final rating = bot?.rating ?? 800;
    // Scale 300ms (rating 100) to 750ms (rating 3200)
    final ms = 300 + ((rating - 100) / 3100 * 450).round();
    return Duration(milliseconds: ms);
  }

  // ─── SETUP PHASE ──────────────────────────────────────────────────────────
  //
  // DATA LAYER (Firebase):
  //   Player 1 pieces are stored at rows 0-2 (top of the data grid)
  //   Player 2 pieces are stored at rows 5-7 (bottom of the data grid)
  //
  // VIEW LAYER (each player's screen):
  //   The board is FLIPPED for Player 2 so both players always see
  //   their own pieces at the BOTTOM of their screen — exactly like chess.com.
  //   The _CoordBoard widget in board_widget.dart handles the visual flip.
  //
  // Result: same board data, different perspectives — no conflict.
  List<int> get setupRows => playerRole == 'player1' ? [0, 1, 2] : [5, 6, 7];
  bool isMySetupRow(int row) => setupRows.contains(row);

  void selectPieceFromTray(Piece piece) {
    if (_trayPieces.isEmpty) return;
    _IndexedPiece? found;
    for (final ip in _trayPieces) {
      if (identical(ip.piece, piece)) {
        found = ip;
        break;
      }
    }
    found ??= _trayPieces.firstWhere((ip) => ip.piece.rank == piece.rank,
        orElse: () => _trayPieces.first);
    _heldPiece = found;
    notifyListeners();
  }

  void tapSquareDuringSetup(BoardPosition pos) {
    if (!isMySetupRow(pos.row)) {
      _heldPiece = null;
      notifyListeners();
      return;
    }
    final destOccupant = _setupBoard[pos.key];
    if (_heldPiece != null) {
      final held = _heldPiece!;
      final sourceKey = _findOnBoard(held);
      if (sourceKey == pos.key) {
        _heldPiece = null;
        notifyListeners();
        return;
      }
      if (sourceKey != null) {
        _setupBoard.remove(sourceKey);
      } else {
        _trayPieces.removeWhere((ip) => ip.index == held.index);
      }
      if (destOccupant != null) {
        if (sourceKey != null) {
          _setupBoard[sourceKey] = destOccupant;
        } else {
          _trayPieces.add(destOccupant);
        }
      }
      _setupBoard[pos.key] = held;
      _heldPiece = null;
      notifyListeners();
    } else if (destOccupant != null) {
      _heldPiece = destOccupant;
      notifyListeners();
    }
  }

  void dropPieceOnSquare(Piece piece, BoardPosition pos) {
    if (!isMySetupRow(pos.row)) return;
    _IndexedPiece? ip;
    for (final t in _trayPieces) {
      if (identical(t.piece, piece)) {
        ip = t;
        break;
      }
    }
    if (ip == null) {
      for (final e in _setupBoard.entries) {
        if (identical(e.value.piece, piece)) {
          ip = e.value;
          break;
        }
      }
    }
    if (ip == null) return;
    final sourceKey = _findOnBoard(ip);
    final destOccupant = _setupBoard[pos.key];
    if (sourceKey == pos.key) return;
    if (sourceKey != null) {
      _setupBoard.remove(sourceKey);
    } else {
      _trayPieces.removeWhere((t) => t.index == ip!.index);
    }
    if (destOccupant != null) {
      if (sourceKey != null) {
        _setupBoard[sourceKey] = destOccupant;
      } else {
        _trayPieces.add(destOccupant);
      }
    }
    _setupBoard[pos.key] = ip;
    _heldPiece = null;
    notifyListeners();
  }

  String? _findOnBoard(_IndexedPiece ip) {
    for (final e in _setupBoard.entries) {
      if (e.value.index == ip.index) return e.key;
    }
    return null;
  }

  bool get canConfirmSetup {
    if (_trayPieces.isNotEmpty) return false;
    if (_heldPiece != null && _findOnBoard(_heldPiece!) == null) return false;
    return true;
  }

  Future<void> confirmSetup() async {
    if (!canConfirmSetup || roomCode == null || playerRole == null) return;
    for (final entry in _setupBoard.entries) {
      await _firebase.placePiece(
          roomCode: roomCode!,
          pos: BoardPosition.fromKey(entry.key),
          piece: entry.value.piece);
    }
    await _firebase.setReady(roomCode: roomCode!, playerRole: playerRole!);
    if (isBotGame && bot != null) {
      final botOwner =
          playerRole == 'player1' ? PieceOwner.player2 : PieceOwner.player1;
      final botRole = playerRole == 'player1' ? 'player2' : 'player1';
      final botSetup = bot!.generateSetup(owner: botOwner);
      for (final entry in botSetup.entries) {
        await _firebase.placePiece(
            roomCode: roomCode!,
            pos: BoardPosition.fromKey(entry.key),
            piece: entry.value);
      }
      await _firebase.setReady(roomCode: roomCode!, playerRole: botRole);
    }
    notifyListeners();
  }

  // ─── GAMEPLAY ─────────────────────────────────────────────────────────────

  bool get isMyTurn => currentTurn == playerRole;

  void selectSquare(BoardPosition pos) {
    if (hasPendingChallenge) return; // block moves during challenge
    if (isBotGame && currentTurn != playerRole) return;
    if (!isMyTurn || phase != GamePhase.playing) return;
    final pieceData = board[pos.key];
    if (selectedPosition == null) {
      if (pieceData != null && _isMyPiece(Piece.fromMap(pieceData))) {
        selectedPosition = pos;
        notifyListeners();
      }
    } else {
      if (selectedPosition == pos) {
        selectedPosition = null;
        notifyListeners();
        return;
      }
      if (_isValidMove(selectedPosition!, pos)) {
        _executeMove(selectedPosition!, pos);
      } else if (pieceData != null && _isMyPiece(Piece.fromMap(pieceData))) {
        selectedPosition = pos;
        notifyListeners();
        return;
      }
      selectedPosition = null;
      notifyListeners();
    }
  }

  bool _isMyPiece(Piece piece) {
    if (playerRole == 'player1') return piece.owner == PieceOwner.player1;
    if (playerRole == 'player2') return piece.owner == PieceOwner.player2;
    return false;
  }

  bool _isValidMove(BoardPosition from, BoardPosition to) {
    if ((from.row - to.row).abs() + (from.col - to.col).abs() != 1)
      return false;
    final t = board[to.key];
    if (t != null && _isMyPiece(Piece.fromMap(t))) return false;
    return true;
  }

  List<BoardPosition> getValidMoves(BoardPosition pos) {
    return pos.adjacents.where((adj) {
      final t = board[adj.key];
      if (t != null && _isMyPiece(Piece.fromMap(t))) return false;
      return true;
    }).toList();
  }

  Future<void> _executeMove(BoardPosition from, BoardPosition to) async {
    if (roomCode == null || playerRole == null) return;
    selectedPosition = null;
    notifyListeners();
    await _firebase.executeMove(
      roomCode: roomCode!,
      playerRole: playerRole!,
      from: from,
      to: to,
      currentBoard: board,
    );
  }

  Future<void> resign() async {
    if (roomCode == null || playerRole == null) return;
    await _firebase.resign(roomCode: roomCode!, playerRole: playerRole!);
  }

  Future<void> offerDraw() async {
    if (roomCode == null || playerRole == null) return;
    await _firebase.offerDraw(roomCode: roomCode!, playerRole: playerRole!);
  }

  Future<void> acceptDraw() async {
    if (roomCode == null) return;
    await _firebase.acceptDraw(roomCode: roomCode!);
  }

  Future<void> declineDraw() async {
    if (roomCode == null) return;
    await _firebase.declineDraw(roomCode: roomCode!);
  }

  void toggleMoveHistory() {
    showMoveHistory = !showMoveHistory;
    notifyListeners();
  }

  void resetGame() {
    _subscription?.cancel();
    roomCode = null;
    playerRole = null;
    phase = GamePhase.waiting;
    currentTurn = 'player1';
    player1Ready = false;
    player2Ready = false;
    player2Joined = false;
    winReason = null;
    winnerRole = null;
    drawOfferedBy = null;
    isBotGame = false;
    bot = null;
    _botThinking = false;
    moveHistory = [];
    board = {};
    _setupBoard = {};
    _trayPieces = [];
    _heldPiece = null;
    selectedPosition = null;
    challengePending = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class _IndexedPiece {
  final Piece piece;
  final int index;
  _IndexedPiece(this.piece, this.index);
}
