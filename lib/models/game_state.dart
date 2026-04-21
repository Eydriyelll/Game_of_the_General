// lib/models/game_state.dart

import 'piece.dart';
import 'board_position.dart';

enum GamePhase { waiting, setup, playing, ended }

enum GameResult { player1Wins, player2Wins, draw }

enum WinReason { flagCaptured, flagMarched, resignation, draw }

class MoveRecord {
  final String playerRole; // 'player1' or 'player2'
  final BoardPosition from;
  final BoardPosition to;
  final bool wasChallenge;
  final DateTime timestamp;

  MoveRecord({
    required this.playerRole,
    required this.from,
    required this.to,
    required this.wasChallenge,
    required this.timestamp,
  });

  String get description {
    final player = playerRole == 'player1' ? 'Player 1' : 'Player 2';
    final challenge = wasChallenge ? ' [Challenge!]' : '';
    return '$player: ${from.key} → ${to.key}$challenge';
  }

  Map<String, dynamic> toMap() => {
        'playerRole': playerRole,
        'fromRow': from.row,
        'fromCol': from.col,
        'toRow': to.row,
        'toCol': to.col,
        'wasChallenge': wasChallenge,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory MoveRecord.fromMap(Map<dynamic, dynamic> map) => MoveRecord(
        playerRole: map['playerRole'],
        from: BoardPosition(map['fromRow'], map['fromCol']),
        to: BoardPosition(map['toRow'], map['toCol']),
        wasChallenge: map['wasChallenge'] ?? false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      );
}

class GameState {
  final GamePhase phase;
  final String? currentTurn; // 'player1' or 'player2'
  final bool player1Ready;
  final bool player2Ready;
  final bool player2Joined;
  final GameResult? result;
  final WinReason? winReason;
  final String? winnerRole;
  final bool challengeFlash; // triggers animation on both screens
  final List<MoveRecord> moveHistory;

  // Board: key = "row_col", value = piece data
  // Stored in Firebase — clients only see opponent pieces as "hidden"
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

  GameState copyWith({
    GamePhase? phase,
    String? currentTurn,
    bool? player1Ready,
    bool? player2Ready,
    bool? player2Joined,
    GameResult? result,
    WinReason? winReason,
    String? winnerRole,
    bool? challengeFlash,
    List<MoveRecord>? moveHistory,
    Map<String, Map<String, dynamic>>? board,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      currentTurn: currentTurn ?? this.currentTurn,
      player1Ready: player1Ready ?? this.player1Ready,
      player2Ready: player2Ready ?? this.player2Ready,
      player2Joined: player2Joined ?? this.player2Joined,
      result: result ?? this.result,
      winReason: winReason ?? this.winReason,
      winnerRole: winnerRole ?? this.winnerRole,
      challengeFlash: challengeFlash ?? this.challengeFlash,
      moveHistory: moveHistory ?? this.moveHistory,
      board: board ?? this.board,
    );
  }
}
