// lib/services/bot_ai.dart
// Bot difficulty levels for single-player mode.
// The bot plays as player2. Difficulty affects:
//   - How it places pieces during setup
//   - How it chooses moves during gameplay

import 'dart:math';
import 'package:flutter/material.dart' show Color;
import '../models/piece.dart';
import '../models/board_position.dart';

enum BotDifficulty { easy, medium, hard, extreme }

class BotMove {
  final BoardPosition from;
  final BoardPosition to;
  BotMove(this.from, this.to);
}

class BotAI {
  final BotDifficulty difficulty;
  final int rating; // 100 (easiest) – 3200 (hardest)
  final Random _rand = Random();

  BotAI(this.difficulty, {this.rating = 800});

  /// Create from a numeric rating (100–3200)
  factory BotAI.fromRating(int rating) {
    final clamped = rating.clamp(100, 3200);
    BotDifficulty diff;
    if (clamped < 700)
      diff = BotDifficulty.easy;
    else if (clamped < 1400)
      diff = BotDifficulty.medium;
    else if (clamped < 2200)
      diff = BotDifficulty.hard;
    else
      diff = BotDifficulty.extreme;
    return BotAI(diff, rating: clamped);
  }

  String get difficultyLabel {
    if (rating < 700) return 'Novice';
    if (rating < 1100) return 'Beginner';
    if (rating < 1400) return 'Amateur';
    if (rating < 1700) return 'Intermediate';
    if (rating < 2000) return 'Advanced';
    if (rating < 2400) return 'Expert';
    if (rating < 2800) return 'Master';
    return 'Grandmaster';
  }

  Color get difficultyColor {
    if (rating < 700) return const Color(0xFF9E9E9E); // grey
    if (rating < 1100) return const Color(0xFF4CAF50); // green
    if (rating < 1400) return const Color(0xFF8BC34A); // light green
    if (rating < 1700) return const Color(0xFFFFC107); // amber
    if (rating < 2000) return const Color(0xFFFF9800); // orange
    if (rating < 2400) return const Color(0xFFF44336); // red
    if (rating < 2800) return const Color(0xFF9C27B0); // purple
    return const Color(0xFFE91E63); // deep pink
  }

  // ─── SETUP: Place bot pieces on rows 5-7 ──────────────────────────────────

  /// Returns a map of position key → Piece for the bot's initial placement.
  Map<String, Piece> generateSetup({PieceOwner owner = PieceOwner.player2}) {
    final pieces = createPieceSet(owner);
    final positions = _allSetupPositions(owner: owner);
    positions.shuffle(_rand);

    Map<String, Piece> setup = {};

    switch (difficulty) {
      case BotDifficulty.easy:
        // Fully random placement
        for (int i = 0; i < pieces.length; i++) {
          setup[positions[i].key] = pieces[i];
        }
        break;

      case BotDifficulty.medium:
        // Flag placed in middle-ish, some structure
        _mediumSetup(pieces, positions, setup);
        break;

      case BotDifficulty.hard:
        // Flag protected, spies forward, privates as shield
        _hardSetup(pieces, positions, setup);
        break;

      case BotDifficulty.extreme:
        // Optimal: flag deep and surrounded, spies forward, generals back
        _extremeSetup(pieces, positions, setup);
        break;
    }

    return setup;
  }

  void _mediumSetup(List<Piece> pieces, List<BoardPosition> positions,
      Map<String, Piece> setup) {
    // Put flag somewhere in back row (row 7), rest random
    final flag = pieces.firstWhere((p) => p.rank == PieceRank.flag);
    final others = pieces.where((p) => p.rank != PieceRank.flag).toList();
    others.shuffle(_rand);

    // Flag in row 7
    final backRow = positions.where((p) => p.row == 7).toList()..shuffle(_rand);
    setup[backRow.first.key] = flag;

    final remaining = positions
        .where((p) => p.key != backRow.first.key)
        .toList()
      ..shuffle(_rand);
    for (int i = 0; i < others.length; i++) {
      setup[remaining[i].key] = others[i];
    }
  }

  void _hardSetup(List<Piece> pieces, List<BoardPosition> positions,
      Map<String, Piece> setup) {
    final flag = pieces.firstWhere((p) => p.rank == PieceRank.flag);
    final spies = pieces.where((p) => p.rank == PieceRank.spy).toList();
    final privates = pieces.where((p) => p.rank == PieceRank.private).toList();
    final generals = pieces
        .where((p) => [
              PieceRank.fiveStar,
              PieceRank.fourStar,
              PieceRank.threeStar,
              PieceRank.twoStar,
              PieceRank.oneStar
            ].contains(p.rank))
        .toList();
    final rest = pieces
        .where((p) =>
            p.rank != PieceRank.flag &&
            p.rank != PieceRank.spy &&
            p.rank != PieceRank.private &&
            !generals.contains(p))
        .toList()
      ..shuffle(_rand);

    final backRow = positions.where((p) => p.row == 7).toList()..shuffle(_rand);
    final midRow = positions.where((p) => p.row == 6).toList()..shuffle(_rand);
    final frontRow = positions.where((p) => p.row == 5).toList()
      ..shuffle(_rand);

    int bIdx = 0, mIdx = 0, fIdx = 0;

    // Flag in back row corner
    setup[backRow[bIdx++].key] = flag;
    // Generals in back row
    for (final g in generals) {
      if (bIdx < backRow.length) setup[backRow[bIdx++].key] = g;
    }
    // Privates as front-line shields
    for (final p in privates) {
      if (fIdx < frontRow.length) setup[frontRow[fIdx++].key] = p;
    }
    // Spies in middle
    for (final s in spies) {
      if (mIdx < midRow.length) setup[midRow[mIdx++].key] = s;
    }
    // Fill remaining
    final allRemaining = [
      ...backRow.skip(bIdx),
      ...midRow.skip(mIdx),
      ...frontRow.skip(fIdx)
    ]..shuffle(_rand);
    int rIdx = 0;
    for (final p in rest) {
      if (rIdx < allRemaining.length) setup[allRemaining[rIdx++].key] = p;
    }
  }

  void _extremeSetup(List<Piece> pieces, List<BoardPosition> positions,
      Map<String, Piece> setup) {
    final flag = pieces.firstWhere((p) => p.rank == PieceRank.flag);
    final spies = pieces.where((p) => p.rank == PieceRank.spy).toList();
    final privates = pieces.where((p) => p.rank == PieceRank.private).toList();
    final fiveStar = pieces.firstWhere((p) => p.rank == PieceRank.fiveStar);
    final highOfficers = pieces
        .where((p) => [
              PieceRank.fourStar,
              PieceRank.threeStar,
              PieceRank.twoStar,
              PieceRank.oneStar
            ].contains(p.rank))
        .toList();
    final midOfficers = pieces
        .where((p) => [
              PieceRank.colonel,
              PieceRank.ltColonel,
              PieceRank.major,
              PieceRank.captain
            ].contains(p.rank))
        .toList();
    final lowOfficers = pieces
        .where((p) => [
              PieceRank.firstLt,
              PieceRank.secondLt,
              PieceRank.sergeant
            ].contains(p.rank))
        .toList();

    // Back row: flag in col 0 or 8 (corner), 5-star nearby, privates flanking
    final backRow = positions.where((p) => p.row == 7).toList();
    backRow.sort((a, b) => a.col.compareTo(b.col));
    final midRow = positions.where((p) => p.row == 6).toList()..shuffle(_rand);
    final frontRow = positions.where((p) => p.row == 5).toList()
      ..shuffle(_rand);

    // Flag in corner col 0
    final flagPos =
        backRow.firstWhere((p) => p.col == 0, orElse: () => backRow[0]);
    setup[flagPos.key] = flag;

    // 5-Star next to flag
    final nearFlag = backRow.where((p) => p.key != flagPos.key).toList();
    nearFlag.sort((a, b) =>
        (a.col - flagPos.col).abs().compareTo((b.col - flagPos.col).abs()));
    int bIdx = 0;
    if (nearFlag.isNotEmpty) {
      setup[nearFlag[bIdx].key] = fiveStar;
      bIdx++;
    }

    // High officers fill back row
    for (final o in highOfficers) {
      if (bIdx < nearFlag.length) {
        setup[nearFlag[bIdx].key] = o;
        bIdx++;
      }
    }

    // Spies in front row (attackers)
    int fIdx = 0;
    for (final s in spies) {
      if (fIdx < frontRow.length) {
        setup[frontRow[fIdx].key] = s;
        fIdx++;
      }
    }
    // Privates spread front+mid
    int mIdx = 0;
    for (final p in privates) {
      if (fIdx < frontRow.length) {
        setup[frontRow[fIdx].key] = p;
        fIdx++;
      } else if (mIdx < midRow.length) {
        setup[midRow[mIdx].key] = p;
        mIdx++;
      }
    }
    // Mid officers in middle
    for (final o in midOfficers) {
      if (mIdx < midRow.length) {
        setup[midRow[mIdx].key] = o;
        mIdx++;
      }
    }
    // Low officers fill gaps
    final allKeys = {
      ...backRow.map((p) => p.key),
      ...midRow.map((p) => p.key),
      ...frontRow.map((p) => p.key)
    };
    final usedKeys = setup.keys.toSet();
    final freeSlots = allKeys.difference(usedKeys).toList()..shuffle(_rand);
    int sIdx = 0;
    for (final o in lowOfficers) {
      if (sIdx < freeSlots.length) {
        setup[freeSlots[sIdx]] = o;
        sIdx++;
      }
    }
  }

  List<BoardPosition> _allSetupPositions(
      {PieceOwner owner = PieceOwner.player2}) {
    // Player 1 deploys at rows 0-2 (top of data grid).
    // Player 2 deploys at rows 5-7 (bottom of data grid).
    // The visual flip in _CoordBoard makes each player see their rows at the bottom.
    final rows = owner == PieceOwner.player1 ? [0, 1, 2] : [5, 6, 7];
    List<BoardPosition> positions = [];
    for (final row in rows) {
      for (int col = 0; col < 9; col++) {
        positions.add(BoardPosition(row, col));
      }
    }
    return positions; // 27 positions, 21 pieces = 6 empty
  }

  // ─── GAMEPLAY: Choose a move ───────────────────────────────────────────────

  /// Given the current board, pick the best move for the bot (player2).
  /// Returns null if no moves available.
  BotMove? chooseMove(Map<String, Map<String, dynamic>> board) {
    switch (difficulty) {
      case BotDifficulty.easy:
        return _easyMove(board);
      case BotDifficulty.medium:
        return _mediumMove(board);
      case BotDifficulty.hard:
        return _hardMove(board);
      case BotDifficulty.extreme:
        return _extremeMove(board);
    }
  }

  // Easy: completely random legal move
  BotMove? _easyMove(Map<String, Map<String, dynamic>> board) {
    final moves = _allLegalMoves(board);
    if (moves.isEmpty) return null;
    return moves[_rand.nextInt(moves.length)];
  }

  // Medium: prefer captures, otherwise random
  BotMove? _mediumMove(Map<String, Map<String, dynamic>> board) {
    final moves = _allLegalMoves(board);
    if (moves.isEmpty) return null;
    // 50% chance to pick a capture if available
    if (_rand.nextDouble() < 0.5) {
      final captures = moves.where((m) => board.containsKey(m.to.key)).toList();
      if (captures.isNotEmpty) return captures[_rand.nextInt(captures.length)];
    }
    return moves[_rand.nextInt(moves.length)];
  }

  // Hard: scored moves — prefers safe captures, advances flag, protects flag
  BotMove? _hardMove(Map<String, Map<String, dynamic>> board) {
    final moves = _allLegalMoves(board);
    if (moves.isEmpty) return null;

    BotMove? best;
    int bestScore = -999;

    for (final move in moves) {
      final score = _scoreMove(move, board, depth: 1);
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best;
  }

  // Extreme: minimax-style with 2-ply lookahead + heuristics
  BotMove? _extremeMove(Map<String, Map<String, dynamic>> board) {
    final moves = _allLegalMoves(board);
    if (moves.isEmpty) return null;

    BotMove? best;
    int bestScore = -9999;

    for (final move in moves) {
      final score = _scoreMove(move, board, depth: 2);
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best;
  }

  int _scoreMove(BotMove move, Map<String, Map<String, dynamic>> board,
      {int depth = 1}) {
    int score = 0;
    final moverData = board[move.from.key];
    if (moverData == null) return 0;
    final mover = Piece.fromMap(moverData);

    // Capture scoring
    final targetData = board[move.to.key];
    if (targetData != null) {
      final target = Piece.fromMap(targetData);
      final result = resolveChallenge(mover, target);

      switch (result) {
        case ChallengeResult.attackerWins:
          score += _pieceValue(target.rank) + 10;
          // Extra for capturing flag = instant win
          if (target.rank == PieceRank.flag) score += 1000;
          break;
        case ChallengeResult.defenderWins:
          score -= _pieceValue(mover.rank) + 5;
          // Catastrophic to lose flag
          if (mover.rank == PieceRank.flag) score -= 500;
          break;
        case ChallengeResult.bothEliminated:
          score += _pieceValue(target.rank) - _pieceValue(mover.rank);
          break;
      }
    }

    // Advance toward enemy territory (lower row = enemy side for player2)
    if (targetData == null) {
      final advance =
          move.from.row - move.to.row; // positive = moving toward row 0
      score += advance * 2;
    }

    // Protect flag: penalize moving flag unless it's advancing to win
    if (mover.rank == PieceRank.flag) {
      final enemyAdjacent = move.to.adjacents.any((adj) {
        final d = board[adj.key];
        if (d == null) return false;
        final p = Piece.fromMap(d);
        return p.owner == PieceOwner.player1;
      });
      if (enemyAdjacent) score -= 50;
      // Flag march win bonus
      if (move.to.row == 0) score += 800;
    }

    // Spy should go after high-value officers
    if (mover.rank == PieceRank.spy && targetData != null) {
      final target = Piece.fromMap(targetData);
      if (target.isOfficer) score += 30;
    }

    // Private should not challenge officers (will lose)
    if (mover.rank == PieceRank.private && targetData != null) {
      final target = Piece.fromMap(targetData);
      if (target.rank != PieceRank.spy && target.rank != PieceRank.flag) {
        score -= 20; // private loses to all officers
      }
    }

    // Add small randomness to avoid deterministic play
    // Higher rating = less randomness in scoring
    final randomRange = (3200 - rating) ~/ 200 + 1;
    score += _rand.nextInt(randomRange.clamp(1, 15));

    return score;
  }

  int _pieceValue(PieceRank rank) {
    switch (rank) {
      case PieceRank.fiveStar:
        return 15;
      case PieceRank.fourStar:
        return 14;
      case PieceRank.threeStar:
        return 13;
      case PieceRank.twoStar:
        return 12;
      case PieceRank.oneStar:
        return 11;
      case PieceRank.colonel:
        return 10;
      case PieceRank.ltColonel:
        return 9;
      case PieceRank.major:
        return 8;
      case PieceRank.captain:
        return 7;
      case PieceRank.firstLt:
        return 6;
      case PieceRank.secondLt:
        return 5;
      case PieceRank.sergeant:
        return 4;
      case PieceRank.spy:
        return 8; // high value, special role
      case PieceRank.private:
        return 3;
      case PieceRank.flag:
        return 100;
    }
  }

  List<BotMove> _allLegalMoves(Map<String, Map<String, dynamic>> board) {
    List<BotMove> moves = [];
    for (final entry in board.entries) {
      final piece = Piece.fromMap(entry.value);
      if (piece.owner != PieceOwner.player2) continue;
      final pos = BoardPosition.fromKey(entry.key);
      for (final adj in pos.adjacents) {
        final targetData = board[adj.key];
        if (targetData != null) {
          final target = Piece.fromMap(targetData);
          if (target.owner == PieceOwner.player2) continue; // can't capture own
        }
        moves.add(BotMove(pos, adj));
      }
    }
    return moves;
  }
}
