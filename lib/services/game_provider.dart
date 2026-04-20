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

  // ── Setup: tracks where THIS player placed pieces ────────────────────────
  // Key = position key, Value = Piece placed there
  Map<String, Piece> localSetupBoard = {};

  // Unplaced pieces still in the tray.
  // We track them as a list; since there are duplicates (2 spies, 6 privates),
  // we use index-based removal to avoid removing wrong duplicates.
  List<Piece> unplacedPieces = [];

  // Which piece from the tray is currently selected (held)
  Piece? _selectedTrayPiece;
  Piece? get selectedTrayPiece => _selectedTrayPiece;

  // Which board square is selected during gameplay
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

  /// Start a single-player game against the bot.
  Future<void> startBotGame(BotDifficulty difficulty) async {
    isBotGame = true;
    bot = BotAI(difficulty);
    final code = _generateRoomCode();
    roomCode = code;
    playerRole = 'player1';
    player2Joined = true;
    await _firebase.createRoom(code);
    _resetLocalSetup(PieceOwner.player1);
    _listenToRoom(code);
    // Bot immediately "joins"
    await _firebase.joinRoom(code);
    notifyListeners();
  }

  void _resetLocalSetup(PieceOwner owner) {
    localSetupBoard = {};
    unplacedPieces = createPieceSet(owner);
    _selectedTrayPiece = null;
    selectedPosition = null;
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int n = rand;
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
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      _updateFromFirebase(data);
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
    if (newFlash && !_challengeFlashLocal) {
      _triggerChallengeFlash();
    }

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

    // If it's bot's turn and game is playing, trigger bot move
    if (isBotGame && phase == GamePhase.playing && currentTurn == 'player2' && !_botThinking) {
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

    // Delay to feel natural
    final thinkTime = _botThinkDelay();
    await Future.delayed(thinkTime);

    if (phase != GamePhase.playing || currentTurn != 'player2') {
      _botThinking = false;
      notifyListeners();
      return;
    }

    final move = bot!.chooseMove(board);
    if (move != null) {
      await _firebase.executeMove(
        roomCode: roomCode!,
        playerRole: 'player2',
        from: move.from,
        to: move.to,
        currentBoard: board,
      );
    }

    _botThinking = false;
    notifyListeners();
  }

  Duration _botThinkDelay() {
    switch (bot?.difficulty) {
      case BotDifficulty.easy:    return Duration(milliseconds: 800 + _randomMs(400));
      case BotDifficulty.medium:  return Duration(milliseconds: 600 + _randomMs(400));
      case BotDifficulty.hard:    return Duration(milliseconds: 500 + _randomMs(300));
      case BotDifficulty.extreme: return Duration(milliseconds: 400 + _randomMs(200));
      default:                    return const Duration(milliseconds: 700);
    }
  }

  int _randomMs(int max) => (DateTime.now().millisecondsSinceEpoch % max);

  // ─── SETUP PHASE ──────────────────────────────────────────────────────────

  List<int> get setupRows {
    if (playerRole == 'player1') return [0, 1, 2];
    return [5, 6, 7];
  }

  bool isMySetupRow(int row) => setupRows.contains(row);

  void selectPieceFromTray(Piece piece) {
    _selectedTrayPiece = piece;
    selectedPosition = null;
    notifyListeners();
  }

  void deselectTrayPiece() {
    _selectedTrayPiece = null;
    notifyListeners();
  }

  /// Tap on a board square during setup.
  /// ── BUG FIX: piece moved from one square to another is properly tracked ──
  void tapSquareDuringSetup(BoardPosition pos) {
    if (!isMySetupRow(pos.row)) {
      // Tapped outside own rows — deselect
      _selectedTrayPiece = null;
      notifyListeners();
      return;
    }

    if (_selectedTrayPiece != null) {
      // ── Case A: holding a tray piece, place it ──────────────────────────
      final existing = localSetupBoard[pos.key];
      if (existing != null) {
        // Return existing piece to unplaced list (it's being displaced)
        unplacedPieces.add(existing);
      }
      localSetupBoard[pos.key] = _selectedTrayPiece!;
      // Remove exactly ONE matching piece from unplaced (handles duplicates correctly)
      final idx = unplacedPieces.indexWhere(
          (p) => p.rank == _selectedTrayPiece!.rank);
      if (idx != -1) unplacedPieces.removeAt(idx);
      _selectedTrayPiece = null;
      notifyListeners();
    } else if (localSetupBoard.containsKey(pos.key)) {
      // ── Case B: no piece held, pick up the placed piece ─────────────────
      // This lets player re-arrange: tap placed piece → it goes back to "held"
      final pickedUp = localSetupBoard[pos.key]!;
      localSetupBoard.remove(pos.key);
      // Add back to unplaced so count is correct
      unplacedPieces.add(pickedUp);
      // Now hold it
      _selectedTrayPiece = pickedUp;
      notifyListeners();
    }
    // Case C: tapped empty square with nothing held → do nothing
  }

  /// Drag-and-drop from tray onto board square.
  void dropPieceOnSquare(Piece piece, BoardPosition pos) {
    if (!isMySetupRow(pos.row)) return;

    // Remove from wherever it currently is
    // Check if it's already on the board (being repositioned)
    String? existingBoardKey;
    for (final entry in localSetupBoard.entries) {
      if (entry.value.rank == piece.rank && entry.value.owner == piece.owner) {
        // Could be a duplicate (spy/private) — find exact same object reference
        // We use a unique id approach: just find any piece of same rank from tray
        break;
      }
    }

    final existing = localSetupBoard[pos.key];
    if (existing != null) unplacedPieces.add(existing);
    localSetupBoard[pos.key] = piece;
    final idx = unplacedPieces.indexWhere((p) => p.rank == piece.rank);
    if (idx != -1) unplacedPieces.removeAt(idx);
    _selectedTrayPiece = null;
    notifyListeners();
  }

  /// Move a PLACED piece from one square to another (both in setup rows).
  /// This is the fix for the duplication bug: when swapping board→board,
  /// we must NOT re-add the piece to unplaced.
  void movePlacedPiece(BoardPosition from, BoardPosition to) {
    if (!isMySetupRow(from.row) || !isMySetupRow(to.row)) return;
    final pieceToMove = localSetupBoard[from.key];
    if (pieceToMove == null) return;

    final existing = localSetupBoard[to.key];
    if (existing != null) {
      // Swap: put existing piece back in from square
      localSetupBoard[from.key] = existing;
    } else {
      // Simple move: free up the from square
      localSetupBoard.remove(from.key);
    }
    localSetupBoard[to.key] = pieceToMove;
    _selectedTrayPiece = null;
    notifyListeners();
  }

  bool get canConfirmSetup => unplacedPieces.isEmpty;

  Future<void> confirmSetup() async {
    if (!canConfirmSetup || roomCode == null || playerRole == null) return;
    for (final entry in localSetupBoard.entries) {
      final pos = BoardPosition.fromKey(entry.key);
      await _firebase.placePiece(
        roomCode: roomCode!,
        pos: pos,
        piece: entry.value,
      );
    }
    await _firebase.setReady(roomCode: roomCode!, playerRole: playerRole!);

    // If bot game: bot auto-places and confirms
    if (isBotGame && bot != null) {
      final botSetup = bot!.generateSetup();
      for (final entry in botSetup.entries) {
        final pos = BoardPosition.fromKey(entry.key);
        await _firebase.placePiece(
          roomCode: roomCode!,
          pos: pos,
          piece: entry.value,
        );
      }
      await _firebase.setReady(roomCode: roomCode!, playerRole: 'player2');
    }
    notifyListeners();
  }

  // ─── GAMEPLAY ─────────────────────────────────────────────────────────────

  bool get isMyTurn => currentTurn == playerRole;

  void selectSquare(BoardPosition pos) {
    if (isBotGame && currentTurn == 'player2') return; // bot's turn
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
      } else if (pieceData != null) {
        final piece = Piece.fromMap(pieceData);
        if (_isMyPiece(piece)) {
          selectedPosition = pos;
          notifyListeners();
          return;
        }
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
    final rowDiff = (from.row - to.row).abs();
    final colDiff = (from.col - to.col).abs();
    if (rowDiff + colDiff != 1) return false;
    final targetData = board[to.key];
    if (targetData != null) {
      final target = Piece.fromMap(targetData);
      if (_isMyPiece(target)) return false;
    }
    return true;
  }

  List<BoardPosition> getValidMoves(BoardPosition pos) {
    return pos.adjacents.where((adj) {
      final targetData = board[adj.key];
      if (targetData != null) {
        final target = Piece.fromMap(targetData);
        if (_isMyPiece(target)) return false;
      }
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
    localSetupBoard = {};
    unplacedPieces = [];
    _selectedTrayPiece = null;
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
