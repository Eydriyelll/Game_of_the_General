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
  String? playerRole; // 'player1' or 'player2'
  GamePhase phase = GamePhase.waiting;
  String currentTurn = 'player1';
  bool player1Ready = false;
  bool player2Ready = false;
  bool player2Joined = false;
  GameResult? gameResult;
  WinReason? winReason;
  String? winnerRole;
  bool showMoveHistory = false;
  String? drawOfferedBy;

  // Bot mode
  bool isBotGame = false;
  BotAI? bot;
  bool _botThinking = false;
  bool get botThinking => _botThinking;

  List<MoveRecord> moveHistory = [];
  Map<String, Map<String, dynamic>> board = {};

  // ── Setup state using unique-indexed pieces ──────────────────────────────
  // Every piece has a unique index (0-20) so duplicates are never confused.
  Map<String, _IndexedPiece> _setupBoard = {}; // posKey → placed piece
  List<_IndexedPiece> _trayPieces = []; // unplaced pieces
  _IndexedPiece? _heldPiece; // currently selected/held

  // Public getters for widgets
  Map<String, Piece> get localSetupBoard =>
      _setupBoard.map((k, v) => MapEntry(k, v.piece));
  List<Piece> get unplacedPieces => _trayPieces.map((ip) => ip.piece).toList();
  Piece? get selectedTrayPiece => _heldPiece?.piece;
  bool get isHoldingBoardPiece =>
      _heldPiece != null && _findOnBoard(_heldPiece!) != null;

  BoardPosition? selectedPosition;
  StreamSubscription<DatabaseEvent>? _subscription;

  bool _challengeFlashLocal = false;
  bool get showChallengeFlash => _challengeFlashLocal;

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
      {String role = 'player1'}) async {
    isBotGame = true;
    bot = BotAI(difficulty);
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

    final newFlash = data['challengeFlash'] ?? false;
    if (newFlash && !_challengeFlashLocal) _triggerChallengeFlash();

    if (data['winnerRole'] != null) winnerRole = data['winnerRole'];
    if (data['winReason'] != null) {
      winReason = WinReason.values.firstWhere(
          (r) => r.name == data['winReason'],
          orElse: () => WinReason.draw);
    }

    if (data['board'] != null) {
      final rawBoard = data['board'] as Map<dynamic, dynamic>;
      board = rawBoard.map((k, v) =>
          MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
    } else {
      board = {};
    }

    if (data['moveHistory'] != null) {
      final rawHistory = data['moveHistory'] as Map<dynamic, dynamic>;
      moveHistory = rawHistory.values
          .map((v) => MoveRecord.fromMap(v as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    notifyListeners();

    if (isBotGame &&
        phase == GamePhase.playing &&
        currentTurn != playerRole &&
        !_botThinking) {
      _scheduleBotMove();
    }
  }

  void _triggerChallengeFlash() async {
    _challengeFlashLocal = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _challengeFlashLocal = false;
    notifyListeners();
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
    final ms = DateTime.now().millisecondsSinceEpoch;
    switch (bot?.difficulty) {
      case BotDifficulty.easy:
        return Duration(milliseconds: 800 + ms % 400);
      case BotDifficulty.medium:
        return Duration(milliseconds: 600 + ms % 400);
      case BotDifficulty.hard:
        return Duration(milliseconds: 500 + ms % 300);
      case BotDifficulty.extreme:
        return Duration(milliseconds: 400 + ms % 200);
      default:
        return const Duration(milliseconds: 700);
    }
  }

  // ─── SETUP PHASE ──────────────────────────────────────────────────────────

  List<int> get setupRows => playerRole == 'player1' ? [0, 1, 2] : [5, 6, 7];

  bool isMySetupRow(int row) => setupRows.contains(row);

  /// Select a tray piece by object identity.
  void selectPieceFromTray(Piece piece) {
    if (_trayPieces.isEmpty) return;
    // Find by object identity first (most accurate)
    _IndexedPiece? found;
    for (final ip in _trayPieces) {
      if (identical(ip.piece, piece)) {
        found = ip;
        break;
      }
    }
    // Fallback: match by rank (for cases where piece object differs)
    found ??= _trayPieces.firstWhere((ip) => ip.piece.rank == piece.rank,
        orElse: () => _trayPieces.first);
    _heldPiece = found;
    notifyListeners();
  }

  void deselectHeld() {
    // If holding a board piece (picked up), put it back
    _heldPiece = null;
    notifyListeners();
  }

  /// THE AUTHORITATIVE setup tap handler.
  ///
  /// Uses unique _IndexedPiece.index to track identity — NEVER confuses duplicates.
  ///
  /// State machine:
  ///   [A] Holding ANY piece + tap valid square → place it there
  ///   [B] Nothing held + tap occupied square  → pick it up (board or tray mode)
  ///   [C] Nothing held + tap empty square     → no-op
  ///   [D] Tap outside own rows               → deselect
  void tapSquareDuringSetup(BoardPosition pos) {
    if (!isMySetupRow(pos.row)) {
      _heldPiece = null;
      notifyListeners();
      return;
    }

    final destOccupant = _setupBoard[pos.key]; // piece already on destination

    if (_heldPiece != null) {
      // ── [A] Place the held piece ─────────────────────────────────────────
      final held = _heldPiece!;
      final sourceKey = _findOnBoard(held); // null if coming from tray

      if (sourceKey == pos.key) {
        // Tapped the very square this piece is on → deselect only
        _heldPiece = null;
        notifyListeners();
        return;
      }

      // Remove held piece from its source
      if (sourceKey != null) {
        _setupBoard.remove(sourceKey); // was on board
      } else {
        _trayPieces.removeWhere((ip) => ip.index == held.index); // was in tray
      }

      // Handle destination occupant
      if (destOccupant != null) {
        if (sourceKey != null) {
          // Board-to-board swap: put destination piece where we came from
          _setupBoard[sourceKey] = destOccupant;
        } else {
          // Tray-to-board: displaced piece goes back to tray
          _trayPieces.add(destOccupant);
        }
      }

      // Place held piece on destination
      _setupBoard[pos.key] = held;
      _heldPiece = null;
      notifyListeners();
    } else if (destOccupant != null) {
      // ── [B] Pick up the piece on this square ─────────────────────────────
      _heldPiece = destOccupant;
      notifyListeners();
    }
    // [C] Empty square, nothing held → no-op
  }

  /// Drag-and-drop handler. Resolves identity the same way as tap.
  void dropPieceOnSquare(Piece piece, BoardPosition pos) {
    if (!isMySetupRow(pos.row)) return;

    // Locate the IndexedPiece by object identity
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

    if (sourceKey == pos.key) return; // same square

    if (sourceKey != null) {
      _setupBoard.remove(sourceKey);
    } else {
      _trayPieces.removeWhere((t) => t.index == ip!.index);
    }

    if (destOccupant != null) {
      if (sourceKey != null) {
        _setupBoard[sourceKey] = destOccupant; // swap
      } else {
        _trayPieces.add(destOccupant); // displace to tray
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

  /// True when all 21 pieces are on the board (tray empty) AND
  /// the player is not currently holding an unplaced tray piece.
  bool get canConfirmSetup {
    if (_trayPieces.isNotEmpty) return false;
    // If holding a piece that is NOT yet on the board → still unplaced
    if (_heldPiece != null && _findOnBoard(_heldPiece!) == null) return false;
    return true;
  }

  Future<void> confirmSetup() async {
    if (!canConfirmSetup || roomCode == null || playerRole == null) return;
    for (final entry in _setupBoard.entries) {
      await _firebase.placePiece(
        roomCode: roomCode!,
        pos: BoardPosition.fromKey(entry.key),
        piece: entry.value.piece,
      );
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
          piece: entry.value,
        );
      }
      await _firebase.setReady(roomCode: roomCode!, playerRole: botRole);
    }
    notifyListeners();
  }

  // ─── GAMEPLAY ─────────────────────────────────────────────────────────────

  bool get isMyTurn => currentTurn == playerRole;

  void selectSquare(BoardPosition pos) {
    if (isBotGame && currentTurn != playerRole) return;
    if (!isMyTurn || phase != GamePhase.playing) return;
    final pieceData = board[pos.key];
    if (selectedPosition == null) {
      if (pieceData != null) {
        final piece = Piece.fromMap(pieceData);
        if (_isMyPiece(piece)) {
          selectedPosition = pos;
          notifyListeners();
        }
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
    gameResult = null;
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
    _challengeFlashLocal = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Wrapper giving every piece a unique integer index (0–20).
/// This eliminates ALL duplication bugs with SPY×2 and PRIVATE×6
/// because we track by index, never by rank alone.
class _IndexedPiece {
  final Piece piece;
  final int index;
  _IndexedPiece(this.piece, this.index);
}
