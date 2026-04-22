// lib/models/game_state.dart

import 'piece.dart';
import 'board_position.dart';

enum GamePhase { waiting, setup, playing, ended }

enum GameResult { player1Wins, player2Wins, draw }

enum WinReason { flagCaptured, flagMarched, resignation, draw }

enum ChallengeOutcome { attackerWins, defenderWins, bothEliminated }

class ChallengeRecord {
  final String attackerRole; // 'player1' or 'player2'
  final String attackerRank; // PieceRank.name
  final String defenderRank; // PieceRank.name
  final ChallengeOutcome outcome;
  final BoardPosition pos; // square where challenge happened

  ChallengeRecord({
    required this.attackerRole,
    required this.attackerRank,
    required this.defenderRank,
    required this.outcome,
    required this.pos,
  });

  String get winnerRole {
    switch (outcome) {
      case ChallengeOutcome.attackerWins:
        return attackerRole;
      case ChallengeOutcome.defenderWins:
        return attackerRole == 'player1' ? 'player2' : 'player1';
      case ChallengeOutcome.bothEliminated:
        return 'none';
    }
  }

  Map<String, dynamic> toMap() => {
        'attackerRole': attackerRole,
        'attackerRank': attackerRank,
        'defenderRank': defenderRank,
        'outcome': outcome.name,
        'posRow': pos.row,
        'posCol': pos.col,
      };

  factory ChallengeRecord.fromMap(Map<dynamic, dynamic> map) => ChallengeRecord(
        attackerRole: map['attackerRole'],
        attackerRank: map['attackerRank'],
        defenderRank: map['defenderRank'],
        outcome:
            ChallengeOutcome.values.firstWhere((o) => o.name == map['outcome']),
        pos: BoardPosition(map['posRow'], map['posCol']),
      );
}

class MoveRecord {
  final String playerRole;
  final BoardPosition from;
  final BoardPosition to;
  final bool wasChallenge;
  final DateTime timestamp;
  final ChallengeRecord? challenge; // populated when wasChallenge == true

  MoveRecord({
    required this.playerRole,
    required this.from,
    required this.to,
    required this.wasChallenge,
    required this.timestamp,
    this.challenge,
  });

  /// Chess-style coordinate label e.g. "A1", "E4" using col letters + row numbers
  /// Columns: A–I (0–8), Rows: 1–8 (displayed as 8–1 from top)
  static String coordLabel(BoardPosition pos) {
    const cols = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
    final col = cols[pos.col];
    final row = (8 - pos.row).toString(); // row 0 = "8", row 7 = "1"
    return '$col$row';
  }

  /// e.g. "A8-B8" or "A8xB8" for captures
  String get chessNotation {
    final f = coordLabel(from);
    final t = coordLabel(to);
    return wasChallenge ? '$f×$t' : '$f-$t';
  }

  Map<String, dynamic> toMap() => {
        'playerRole': playerRole,
        'fromRow': from.row,
        'fromCol': from.col,
        'toRow': to.row,
        'toCol': to.col,
        'wasChallenge': wasChallenge,
        'timestamp': timestamp.millisecondsSinceEpoch,
        if (challenge != null) 'challenge': challenge!.toMap(),
      };

  factory MoveRecord.fromMap(Map<dynamic, dynamic> map) => MoveRecord(
        playerRole: map['playerRole'],
        from: BoardPosition(map['fromRow'], map['fromCol']),
        to: BoardPosition(map['toRow'], map['toCol']),
        wasChallenge: map['wasChallenge'] ?? false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        challenge: map['challenge'] != null
            ? ChallengeRecord.fromMap(map['challenge'] as Map)
            : null,
      );
}

class GameState {
  final GamePhase phase;
  final String? currentTurn;
  final bool player1Ready;
  final bool player2Ready;
  final bool player2Joined;
  final GameResult? result;
  final WinReason? winReason;
  final String? winnerRole;
  final bool challengeFlash;
  final List<MoveRecord> moveHistory;
  final Map<String, Map<String, dynamic>> board;

  const GameState({
    this.phase = GamePhase.waiting,
    this.currentTurn,
    this.player1Ready = false,
    this.player2Ready = false,
    this.player2Joined = false,
    this.result,
    this.winReason,
    this.winnerRole,
    this.challengeFlash = false,
    this.moveHistory = const [],
    this.board = const {},
  });
}
