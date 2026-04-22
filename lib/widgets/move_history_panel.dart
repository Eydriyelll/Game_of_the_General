// lib/widgets/move_history_panel.dart
// Chess-style move notation. Challenge outcomes shown by PLAYER only — no
// piece ranks are ever revealed (preserves hidden-information game rule).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';

class MoveHistoryPanel extends StatelessWidget {
  const MoveHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      final history = provider.moveHistory.reversed.toList();

      return Container(
        color: AppTheme.surface,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: Row(children: [
              Icon(Icons.history_rounded, color: AppTheme.accent, size: 15),
              const SizedBox(width: 6),
              Text('MOVE LOG',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${history.length}',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ),
            ]),
          ),
          // ── Legend ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: AppTheme.surfaceLight,
            child: Row(children: [
              _Dot(color: AppTheme.player1Color, label: 'P1'),
              const SizedBox(width: 10),
              _Dot(color: AppTheme.player2Color, label: 'P2'),
              const SizedBox(width: 10),
              Icon(Icons.bolt_rounded, color: AppTheme.challengeColor, size: 9),
              const SizedBox(width: 3),
              Text('= challenge',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 8)),
            ]),
          ),
          // ── Move list ──
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Text('No moves yet',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 11)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: history.length,
                    itemBuilder: (ctx, i) {
                      final move = history[i];
                      return _MoveEntry(
                        move: move,
                        number: history.length - i,
                        myRole: provider.playerRole ?? '',
                      );
                    },
                  ),
          ),
        ]),
      );
    });
  }
}

// ─── Small colour dot ────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 8)),
      ]);
}

// ─── Single move entry ────────────────────────────────────────────────────────

class _MoveEntry extends StatelessWidget {
  final MoveRecord move;
  final int number;
  final String myRole;

  const _MoveEntry(
      {required this.move, required this.number, required this.myRole});

  @override
  Widget build(BuildContext context) {
    final isP1 = move.playerRole == 'player1';
    final isMe = move.playerRole == myRole;
    final color = isP1 ? AppTheme.player1Color : AppTheme.player2Color;
    final bgColor = isMe ? color.withOpacity(0.05) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        border:
            Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.3))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Move notation line ──
        Row(children: [
          SizedBox(
              width: 24,
              child: Text('$number.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 9))),
          Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Text(
            move.chessNotation,
            style: const TextStyle(
              color: Color(0xFFF5F0E8),
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          if (move.wasChallenge) ...[
            const SizedBox(width: 5),
            Icon(Icons.bolt_rounded, color: AppTheme.challengeColor, size: 11),
          ],
        ]),
        // ── Challenge result line (player names only — NO rank info) ──
        if (move.wasChallenge && move.challenge != null) ...[
          const SizedBox(height: 3),
          _ChallengeResult(
            challenge: move.challenge!,
            myRole: myRole,
          ),
        ],
      ]),
    );
  }
}

// ─── Challenge result — shows winner/loser by player name only ───────────────
// IMPORTANT: Never reveals which piece won or lost. Only states which player
// came out ahead, preserving the hidden-information rule of the game.

class _ChallengeResult extends StatelessWidget {
  final ChallengeRecord challenge;
  final String myRole;

  const _ChallengeResult({required this.challenge, required this.myRole});

  @override
  Widget build(BuildContext context) {
    final attacker = challenge.attackerRole; // 'player1' or 'player2'
    final defender = attacker == 'player1' ? 'player2' : 'player1';

    final String winnerRole;
    final String loserRole;
    final bool bothOut;

    switch (challenge.outcome) {
      case ChallengeOutcome.attackerWins:
        winnerRole = attacker;
        loserRole = defender;
        bothOut = false;
        break;
      case ChallengeOutcome.defenderWins:
        winnerRole = defender;
        loserRole = attacker;
        bothOut = false;
        break;
      case ChallengeOutcome.bothEliminated:
        winnerRole = '';
        loserRole = '';
        bothOut = true;
        break;
    }

    final winnerColor =
        winnerRole == 'player1' ? AppTheme.player1Color : AppTheme.player2Color;
    final loserColor =
        loserRole == 'player1' ? AppTheme.player1Color : AppTheme.player2Color;

    // What to show — player label capitalised, no rank info
    final String winnerLabel = _playerLabel(winnerRole);
    final String loserLabel = _playerLabel(loserRole);

    // Personal suffix so the viewing player knows it was them
    final iWon = !bothOut && winnerRole == myRole;
    final iLost = !bothOut && loserRole == myRole;

    return Padding(
      padding: const EdgeInsets.only(left: 29),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (bothOut)
          // Both eliminated — neutral grey
          Row(children: [
            Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 10),
            const SizedBox(width: 3),
            Text('Challenge: Both Eliminated',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontStyle: FontStyle.italic)),
          ])
        else
          // One side won
          Row(children: [
            Icon(Icons.military_tech_rounded, color: winnerColor, size: 10),
            const SizedBox(width: 3),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 9),
                children: [
                  TextSpan(
                      text: 'Challenge: ',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic)),
                  TextSpan(
                      text: winnerLabel,
                      style: TextStyle(
                          color: winnerColor, fontWeight: FontWeight.w800)),
                  TextSpan(
                      text: ' Wins, ',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic)),
                  TextSpan(
                      text: loserLabel,
                      style: TextStyle(
                        color: loserColor.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: loserColor.withOpacity(0.5),
                      )),
                  TextSpan(
                      text: ' Eliminated',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ]),
        // Personal note for the viewing player
        if (iWon || iLost)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              iWon ? '→ You won this challenge ✓' : '→ You lost this challenge',
              style: TextStyle(
                color: iWon ? AppTheme.accent : AppTheme.danger,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ]),
    );
  }

  String _playerLabel(String role) {
    if (role == 'player1') return 'Player 1';
    if (role == 'player2') return 'Player 2';
    return '';
  }
}
