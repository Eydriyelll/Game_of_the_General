// lib/services/firebase_service.dart

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/piece.dart';
import '../models/board_position.dart';
import '../models/game_state.dart';

class FirebaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference _roomRef(String roomCode) => _db.ref('rooms/$roomCode');
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

  // ─── SETUP ────────────────────────────────────────────────────────────────

  Future<void> placePiece({
    required String roomCode,
    required BoardPosition pos,
    required Piece piece,
  }) async {
    await _boardRef(roomCode).child(pos.key).set(piece.toMap());
  }

  Future<void> setReady({
    required String roomCode,
    required String playerRole,
  }) async {
    await _roomRef(roomCode).update({'${playerRole}Ready': true});
    final snap = await _roomRef(roomCode).get();
    final data = snap.value as Map<dynamic, dynamic>;
    if (data['player1Ready'] == true && data['player2Ready'] == true) {
      await _roomRef(roomCode).update({'phase': 'playing'});
    }
  }

  // ─── GAMEPLAY ─────────────────────────────────────────────────────────────

  /// Execute a move with a 3-second challenge reveal window.
  ///
  /// Challenge flow:
  ///   1. Broadcast 'challengePending' → both screens show a countdown
  ///   2. Wait 3 seconds
  ///   3. Resolve and broadcast result (attacker/defender/both rank names + outcome)
  ///   4. Wait 2 seconds for players to read the result
  ///   5. Apply board changes and advance turn
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
    final nextTurn = playerRole == 'player1' ? 'player2' : 'player1';

    if (targetPieceData == null) {
      // ── Simple move ──────────────────────────────────────────────────────
      final moveKey = DateTime.now().millisecondsSinceEpoch.toString();
      await _roomRef(roomCode).update({
        'board/${to.key}': movingPieceData,
        'board/${from.key}': null,
        'currentTurn': nextTurn,
        'moveHistory/$moveKey': MoveRecord(
          playerRole: playerRole,
          from: from,
          to: to,
          wasChallenge: false,
          timestamp: DateTime.now(),
        ).toMap(),
      });
    } else {
      // ── Challenge ────────────────────────────────────────────────────────
      final targetPiece = Piece.fromMap(targetPieceData);
      final result = resolveChallenge(movingPiece, targetPiece);

      // Map to ChallengeOutcome
      final outcome = result == ChallengeResult.attackerWins
          ? ChallengeOutcome.attackerWins
          : result == ChallengeResult.defenderWins
              ? ChallengeOutcome.defenderWins
              : ChallengeOutcome.bothEliminated;

      final challengeRec = ChallengeRecord(
        attackerRole: playerRole,
        attackerRank: movingPiece.rank.name,
        defenderRank: targetPiece.rank.name,
        outcome: outcome,
        pos: to,
      );

      // Step 1 — announce challenge (show countdown on both screens)
      await _roomRef(roomCode).update({
        'challengePending': {
          'attackerRole': playerRole,
          'attackerRank': movingPiece.rank.name,
          'defenderRank': targetPiece.rank.name,
          'fromKey': from.key,
          'toKey': to.key,
          'phase': 'countdown', // 'countdown' → 'reveal'
        },
      });

      // Step 2 — wait 5 seconds (players see countdown)
      await Future.delayed(const Duration(seconds: 5));

      // Step 3 — reveal result
      await _roomRef(roomCode).update({
        'challengePending/phase': 'reveal',
        'challengePending/outcome': outcome.name,
      });

      // Step 4 — wait 2 seconds (players read who won)
      await Future.delayed(const Duration(seconds: 2));

      // Step 5 — apply board changes, record history, clear challenge
      final moveKey = DateTime.now().millisecondsSinceEpoch.toString();
      final boardUpdates = <String, dynamic>{};

      switch (result) {
        case ChallengeResult.attackerWins:
          boardUpdates['board/${to.key}'] = movingPieceData;
          boardUpdates['board/${from.key}'] = null;
          break;
        case ChallengeResult.defenderWins:
          boardUpdates['board/${from.key}'] = null;
          break;
        case ChallengeResult.bothEliminated:
          boardUpdates['board/${from.key}'] = null;
          boardUpdates['board/${to.key}'] = null;
          break;
      }

      boardUpdates['challengePending'] = null;
      boardUpdates['currentTurn'] = nextTurn;
      boardUpdates['moveHistory/$moveKey'] = MoveRecord(
        playerRole: playerRole,
        from: from,
        to: to,
        wasChallenge: true,
        timestamp: DateTime.now(),
        challenge: challengeRec,
      ).toMap();

      await _roomRef(roomCode).update(boardUpdates);

      // Check win conditions
      await _checkWinConditions(roomCode: roomCode, playerRole: playerRole);
      return;
    }

    // Win check after simple move too (flag march)
    await _checkWinConditions(roomCode: roomCode, playerRole: playerRole);
  }

  Future<void> _checkWinConditions({
    required String roomCode,
    required String playerRole,
  }) async {
    final snap = await _boardRef(roomCode).get();
    if (!snap.exists) return;

    final boardData = Map<String, dynamic>.from(snap.value as Map);
    final board = boardData.map(
        (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));

    bool p1FlagAlive = false, p2FlagAlive = false;
    bool p1FlagReachedEnd = false, p2FlagReachedEnd = false;

    board.forEach((key, pieceData) {
      final piece = Piece.fromMap(pieceData);
      if (piece.rank == PieceRank.flag) {
        final pos = BoardPosition.fromKey(key);
        // P1 starts at rows 0-2 (top), marches DOWN to row 7 to win.
        // P2 starts at rows 5-7 (bottom), marches UP to row 0 to win.
        if (piece.owner == PieceOwner.player1) {
          p1FlagAlive = true;
          if (pos.row == 7) p1FlagReachedEnd = true;
        } else {
          p2FlagAlive = true;
          if (pos.row == 0) p2FlagReachedEnd = true;
        }
      }
    });

    if (!p2FlagAlive) {
      await _roomRef(roomCode).update({
        'phase': 'ended',
        'winnerRole': 'player1',
        'winReason': 'flagCaptured'
      });
      return;
    }
    if (!p1FlagAlive) {
      await _roomRef(roomCode).update({
        'phase': 'ended',
        'winnerRole': 'player2',
        'winReason': 'flagCaptured'
      });
      return;
    }
    if (p1FlagReachedEnd) {
      final flagPos = _findFlag(board, PieceOwner.player1);
      if (flagPos != null && _isFlagSafe(flagPos, board, PieceOwner.player2)) {
        await _roomRef(roomCode).update({
          'phase': 'ended',
          'winnerRole': 'player1',
          'winReason': 'flagMarched'
        });
        return;
      }
    }
    if (p2FlagReachedEnd) {
      final flagPos = _findFlag(board, PieceOwner.player2);
      if (flagPos != null && _isFlagSafe(flagPos, board, PieceOwner.player1)) {
        await _roomRef(roomCode).update({
          'phase': 'ended',
          'winnerRole': 'player2',
          'winReason': 'flagMarched'
        });
        return;
      }
    }
  }

  BoardPosition? _findFlag(
      Map<String, Map<String, dynamic>> board, PieceOwner owner) {
    for (final e in board.entries) {
      final p = Piece.fromMap(e.value);
      if (p.rank == PieceRank.flag && p.owner == owner)
        return BoardPosition.fromKey(e.key);
    }
    return null;
  }

  bool _isFlagSafe(BoardPosition flagPos,
      Map<String, Map<String, dynamic>> board, PieceOwner enemy) {
    for (final e in board.entries) {
      final p = Piece.fromMap(e.value);
      if (p.owner == enemy) {
        final pos = BoardPosition.fromKey(e.key);
        if ((pos.row - flagPos.row).abs() <= 1 &&
            (pos.col - flagPos.col).abs() <= 1) return false;
      }
    }
    return true;
  }

  // ─── GAME ACTIONS ─────────────────────────────────────────────────────────

  Future<void> resign(
      {required String roomCode, required String playerRole}) async {
    final winner = playerRole == 'player1' ? 'player2' : 'player1';
    await _roomRef(roomCode).update(
        {'phase': 'ended', 'winnerRole': winner, 'winReason': 'resignation'});
  }

  Future<void> offerDraw(
      {required String roomCode, required String playerRole}) async {
    await _roomRef(roomCode).update({'drawOfferedBy': playerRole});
  }

  Future<void> acceptDraw({required String roomCode}) async {
    await _roomRef(roomCode)
        .update({'phase': 'ended', 'winnerRole': null, 'winReason': 'draw'});
  }

  Future<void> declineDraw({required String roomCode}) async {
    await _roomRef(roomCode).update({'drawOfferedBy': null});
  }

  Stream<DatabaseEvent> watchRoom(String roomCode) =>
      _roomRef(roomCode).onValue;
  Future<void> deleteRoom(String roomCode) async => _roomRef(roomCode).remove();
}
