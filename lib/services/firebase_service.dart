// lib/services/firebase_service.dart

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/piece.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';

class FirebaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference _roomRef(String roomCode) =>
      _db.ref('rooms/$roomCode');

  DatabaseReference _boardRef(String roomCode) =>
      _db.ref('rooms/$roomCode/board');

  // ─── ROOM MANAGEMENT ──────────────────────────────────────────────────────

  Future<void> createRoom(String roomCode) async {
    await _roomRef(roomCode).set({
      'phase': 'waiting',
      'currentTurn': 'player1',
      'player1Ready': false,
      'player2Ready': false,
      'player2Joined': false,
      'challengeFlash': false,
      'board': {},
      'moveHistory': {},
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<bool> roomExists(String roomCode) async {
    final snap = await _roomRef(roomCode).get();
    return snap.exists;
  }

  Future<void> joinRoom(String roomCode) async {
    await _roomRef(roomCode).update({'player2Joined': true});
  }

  // ─── SETUP PHASE ──────────────────────────────────────────────────────────

  /// Place a piece during setup phase
  Future<void> placePiece({
    required String roomCode,
    required BoardPosition pos,
    required Piece piece,
  }) async {
    await _boardRef(roomCode).child(pos.key).set(piece.toMap());
  }

  /// Remove a piece from a square during setup
  Future<void> removePiece({
    required String roomCode,
    required BoardPosition pos,
  }) async {
    await _boardRef(roomCode).child(pos.key).remove();
  }

  /// Mark a player as ready
  Future<void> setReady({
    required String roomCode,
    required String playerRole, // 'player1' or 'player2'
  }) async {
    await _roomRef(roomCode).update({'${playerRole}Ready': true});
    // Check if both ready → start game
    final snap = await _roomRef(roomCode).get();
    final data = snap.value as Map<dynamic, dynamic>;
    if (data['player1Ready'] == true && data['player2Ready'] == true) {
      await _roomRef(roomCode).update({'phase': 'playing'});
    }
  }

  // ─── GAMEPLAY ─────────────────────────────────────────────────────────────

  /// Execute a move. Handles:
  ///  - Simple move (empty square)
  ///  - Challenge resolution (arbiter logic runs here)
  ///  - Win condition checks
  Future<void> executeMove({
    required String roomCode,
    required String playerRole,
    required BoardPosition from,
    required BoardPosition to,
    required Map<String, Map<String, dynamic>> currentBoard,
  }) async {
    final movingPieceData = currentBoard[from.key];
    if (movingPieceData == null) return;

    final movingPiece = Piece.fromMap(movingPieceData);
    final targetPieceData = currentBoard[to.key];
    final String nextTurn = playerRole == 'player1' ? 'player2' : 'player1';

    bool wasChallenge = false;
    Map<String, dynamic> updates = {};

    if (targetPieceData == null) {
      // ── Simple move ──
      updates['board/${to.key}'] = movingPieceData;
      updates['board/${from.key}'] = null;
    } else {
      // ── Challenge ──
      wasChallenge = true;
      final targetPiece = Piece.fromMap(targetPieceData);
      final result = resolveChallenge(movingPiece, targetPiece);

      switch (result) {
        case ChallengeResult.attackerWins:
          updates['board/${to.key}'] = movingPieceData;
          updates['board/${from.key}'] = null;
          break;
        case ChallengeResult.defenderWins:
          updates['board/${from.key}'] = null;
          // defender stays
          break;
        case ChallengeResult.bothEliminated:
          updates['board/${from.key}'] = null;
          updates['board/${to.key}'] = null;
          break;
      }

      // Trigger challenge flash animation
      updates['challengeFlash'] = true;
    }

    // Record move
    final moveKey = DateTime.now().millisecondsSinceEpoch.toString();
    updates['moveHistory/$moveKey'] = MoveRecord(
      playerRole: playerRole,
      from: from,
      to: to,
      wasChallenge: wasChallenge,
      timestamp: DateTime.now(),
    ).toMap();

    updates['currentTurn'] = nextTurn;

    await _roomRef(roomCode).update(updates);

    // Check win conditions after move
    await _checkWinConditions(
      roomCode: roomCode,
      currentBoard: currentBoard,
      updates: updates,
      movingPiece: movingPiece,
      to: to,
      playerRole: playerRole,
    );

    // Reset challenge flash after short delay
    if (wasChallenge) {
      await Future.delayed(const Duration(milliseconds: 1500));
      await _roomRef(roomCode).update({'challengeFlash': false});
    }
  }

  Future<void> _checkWinConditions({
    required String roomCode,
    required Map<String, Map<String, dynamic>> currentBoard,
    required Map<String, dynamic> updates,
    required Piece movingPiece,
    required BoardPosition to,
    required String playerRole,
  }) async {
    // Rebuild board after updates for accurate check
    final snap = await _boardRef(roomCode).get();
    if (!snap.exists) return;

    final boardData = Map<String, dynamic>.from(snap.value as Map);
    final board = boardData.map((k, v) =>
        MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));

    // Check if any flag is eliminated
    bool p1FlagAlive = false;
    bool p2FlagAlive = false;
    bool p1FlagReachedEnd = false;

    board.forEach((key, pieceData) {
      final piece = Piece.fromMap(pieceData);
      if (piece.rank == PieceRank.flag) {
        if (piece.owner == PieceOwner.player1) {
          p1FlagAlive = true;
          final pos = BoardPosition.fromKey(key);
          // Player1 flag needs to reach row 7 (opponent's back row)
          if (pos.row == 7) p1FlagReachedEnd = true;
        } else {
          p2FlagAlive = true;
        }
      }
    });

    bool p2FlagReachedEnd = false;
    board.forEach((key, pieceData) {
      final piece = Piece.fromMap(pieceData);
      if (piece.rank == PieceRank.flag && piece.owner == PieceOwner.player2) {
        final pos = BoardPosition.fromKey(key);
        // Player2 flag needs to reach row 0 (opponent's back row)
        if (pos.row == 0) p2FlagReachedEnd = true;
      }
    });

    // Flag captured
    if (!p2FlagAlive) {
      await _roomRef(roomCode).update({
        'phase': 'ended',
        'winnerRole': 'player1',
        'winReason': 'flagCaptured',
      });
      return;
    }
    if (!p1FlagAlive) {
      await _roomRef(roomCode).update({
        'phase': 'ended',
        'winnerRole': 'player2',
        'winReason': 'flagCaptured',
      });
      return;
    }

    // Flag marched — check 2-square safety rule
    if (p1FlagReachedEnd) {
      final flagPos = _findFlagPosition(board, PieceOwner.player1);
      if (flagPos != null && _isFlagSafe(flagPos, board, PieceOwner.player2)) {
        await _roomRef(roomCode).update({
          'phase': 'ended',
          'winnerRole': 'player1',
          'winReason': 'flagMarched',
        });
        return;
      }
    }
    if (p2FlagReachedEnd) {
      final flagPos = _findFlagPosition(board, PieceOwner.player2);
      if (flagPos != null && _isFlagSafe(flagPos, board, PieceOwner.player1)) {
        await _roomRef(roomCode).update({
          'phase': 'ended',
          'winnerRole': 'player2',
          'winReason': 'flagMarched',
        });
        return;
      }
    }
  }

  BoardPosition? _findFlagPosition(
      Map<String, Map<String, dynamic>> board, PieceOwner owner) {
    for (final entry in board.entries) {
      final piece = Piece.fromMap(entry.value);
      if (piece.rank == PieceRank.flag && piece.owner == owner) {
        return BoardPosition.fromKey(entry.key);
      }
    }
    return null;
  }

  /// Flag is safe if no enemy piece is adjacent (within 1 square)
  /// Per rules: flag must be at least 2 squares ahead of any opposing piece
  bool _isFlagSafe(BoardPosition flagPos,
      Map<String, Map<String, dynamic>> board, PieceOwner enemyOwner) {
    for (final entry in board.entries) {
      final piece = Piece.fromMap(entry.value);
      if (piece.owner == enemyOwner) {
        final pos = BoardPosition.fromKey(entry.key);
        // Check if enemy is adjacent (within 1 square in any direction)
        if ((pos.row - flagPos.row).abs() <= 1 &&
            (pos.col - flagPos.col).abs() <= 1) {
          return false;
        }
      }
    }
    return true;
  }

  // ─── GAME ACTIONS ─────────────────────────────────────────────────────────

  Future<void> resign({
    required String roomCode,
    required String playerRole,
  }) async {
    final winner = playerRole == 'player1' ? 'player2' : 'player1';
    await _roomRef(roomCode).update({
      'phase': 'ended',
      'winnerRole': winner,
      'winReason': 'resignation',
    });
  }

  Future<void> offerDraw({
    required String roomCode,
    required String playerRole,
  }) async {
    await _roomRef(roomCode).update({'drawOfferedBy': playerRole});
  }

  Future<void> acceptDraw({required String roomCode}) async {
    await _roomRef(roomCode).update({
      'phase': 'ended',
      'winnerRole': null,
      'winReason': 'draw',
    });
  }

  Future<void> declineDraw({required String roomCode}) async {
    await _roomRef(roomCode).update({'drawOfferedBy': null});
  }

  // ─── STREAM ───────────────────────────────────────────────────────────────

  Stream<DatabaseEvent> watchRoom(String roomCode) {
    return _roomRef(roomCode).onValue;
  }

  Future<void> deleteRoom(String roomCode) async {
    await _roomRef(roomCode).remove();
  }
}
