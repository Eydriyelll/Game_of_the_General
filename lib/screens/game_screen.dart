// lib/screens/game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/ph_decorators.dart';
import '../widgets/board_widget.dart';
import '../widgets/move_history_panel.dart';
import 'lobby_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      if (provider.phase == GamePhase.ended) {
        return _GameEndedScreen(provider: provider);
      }
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(children: [
          SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return isWide
                ? _WideLayout(provider: provider)
                : _NarrowLayout(provider: provider);
          })),
          if (provider.hasPendingChallenge)
            _ChallengeOverlay(pending: provider.challengePending!),
          if (provider.drawOfferedBy != null &&
              provider.drawOfferedBy != provider.playerRole)
            _DrawDialog(provider: provider),
          if (provider.botThinking) const _BotThinkingIndicator(),
        ]),
      );
    });
  }
}

class _WideLayout extends StatelessWidget {
  final GameProvider provider;
  const _WideLayout({required this.provider});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Column(children: [
          _Header(provider: provider),
          Expanded(child: GameBoardWidget()),
        ])),
        if (provider.showMoveHistory) ...[
          Container(width: 1, color: AppTheme.border),
          SizedBox(width: 240, child: MoveHistoryPanel()),
        ],
      ]);
}

class _NarrowLayout extends StatelessWidget {
  final GameProvider provider;
  const _NarrowLayout({required this.provider});
  @override
  Widget build(BuildContext context) => Column(children: [
        _Header(provider: provider),
        Expanded(child: GameBoardWidget()),
        if (provider.showMoveHistory)
          SizedBox(height: 150, child: MoveHistoryPanel()),
      ]);
}

class _Header extends StatelessWidget {
  final GameProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = provider.isMyTurn;
    final myColor = provider.playerRole == 'player1'
        ? AppTheme.player1Color
        : AppTheme.player2Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: [
        // Turn chip
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMyTurn ? myColor.withOpacity(0.15) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isMyTurn ? myColor : AppTheme.border,
                width: isMyTurn ? 1.5 : 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isMyTurn)
              Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 5),
                      decoration:
                          BoxDecoration(color: myColor, shape: BoxShape.circle))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(end: const Offset(1.5, 1.5), duration: 600.ms),
            Text(isMyTurn ? 'YOUR TURN' : "OPPONENT'S TURN",
                style: TextStyle(
                  color: isMyTurn ? myColor : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                )),
          ]),
        ),
        const Spacer(),
        // Philippine flag stripe accent
        Row(children: [
          Container(width: 3, height: 16, color: AppTheme.phNavy),
          Container(width: 3, height: 16, color: AppTheme.phGold),
          Container(width: 3, height: 16, color: AppTheme.phRed),
        ]),
        const SizedBox(width: 8),
        // History toggle
        IconButton(
          icon: Icon(Icons.history_rounded,
              color: provider.showMoveHistory
                  ? AppTheme.accent
                  : AppTheme.textMuted,
              size: 20),
          tooltip: 'Move history',
          onPressed: provider.toggleMoveHistory,
        ),
        // Menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppTheme.border)),
          onSelected: (v) {
            if (v == 'draw') provider.offerDraw();
            if (v == 'resign') _confirmResign(context, provider);
          },
          itemBuilder: (_) => [
            if (!provider.isBotGame)
              PopupMenuItem(
                  value: 'draw',
                  child: Row(children: [
                    Icon(Icons.handshake,
                        color: AppTheme.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Text('Offer Draw',
                        style: TextStyle(color: AppTheme.textPrimary)),
                  ])),
            PopupMenuItem(
                value: 'resign',
                child: Row(children: [
                  Icon(Icons.flag, color: AppTheme.danger, size: 16),
                  const SizedBox(width: 8),
                  Text('Resign', style: TextStyle(color: AppTheme.danger)),
                ])),
          ],
        ),
      ]),
    );
  }

  void _confirmResign(BuildContext context, GameProvider provider) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.border)),
              title: Text('Resign?',
                  style: TextStyle(color: AppTheme.textPrimary)),
              content: Text('You will forfeit the match.',
                  style: TextStyle(color: AppTheme.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary))),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.resign();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger),
                  child: const Text('Resign',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
  }
}

class _ChallengeOverlay extends StatefulWidget {
  final Map<String, dynamic> pending;
  const _ChallengeOverlay({required this.pending});
  @override
  State<_ChallengeOverlay> createState() => _ChallengeOverlayState();
}

class _ChallengeOverlayState extends State<_ChallengeOverlay> {
  int _countdown = 5; // 5-second countdown
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.pending['phase'] ?? 'countdown';
    final isReveal = phase == 'reveal';
    final attackerRole = widget.pending['attackerRole'] ?? '';
    final outcome = widget.pending['outcome'] ?? '';
    final atkColor = attackerRole == 'player1'
        ? AppTheme.player1Color
        : AppTheme.player2Color;
    final defColor = attackerRole == 'player1'
        ? AppTheme.player2Color
        : AppTheme.player1Color;

    return IgnorePointer(
      child: Container(
        color: Colors.black.withOpacity(0.70),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: isReveal
                ? _RevealCard(
                    key: const ValueKey('reveal'),
                    attackerRole: attackerRole,
                    outcome: outcome,
                    atkColor: atkColor,
                    defColor: defColor,
                  )
                : _CountdownCard(
                    key: ValueKey(_countdown),
                    countdown: _countdown,
                    atkColor: atkColor,
                    defColor: defColor,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final int countdown;
  final Color atkColor, defColor;
  const _CountdownCard(
      {super.key,
      required this.countdown,
      required this.atkColor,
      required this.defColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.challengeColor, width: 2),
        boxShadow: [
          BoxShadow(
              color: AppTheme.challengeColor.withOpacity(0.25), blurRadius: 30)
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bolt_rounded, color: AppTheme.challengeColor, size: 22),
          const SizedBox(width: 8),
          Text('CHALLENGE!',
              style: GoogleFonts.cinzel(
                  color: AppTheme.challengeColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3)),
          const SizedBox(width: 8),
          Icon(Icons.bolt_rounded, color: AppTheme.challengeColor, size: 22),
        ]),
        const SizedBox(height: 20),
        // Show only player color indicators — no rank names revealed
        Row(mainAxisSize: MainAxisSize.min, children: [
          _PlayerToken(color: atkColor, label: 'ATTACKER'),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('VS',
                  style: GoogleFonts.cinzel(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      letterSpacing: 3))),
          _PlayerToken(color: defColor, label: 'DEFENDER'),
        ]),
        const SizedBox(height: 24),
        Text('Arbiter is deciding...',
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 12),
        // Countdown circle
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.challengeColor, width: 3),
            color: AppTheme.surfaceLight,
          ),
          child: Center(
              child: Text('$countdown',
                  style: GoogleFonts.cinzel(
                      color: AppTheme.challengeColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w700))),
        ).animate(key: ValueKey(countdown)).scale(
            begin: const Offset(1.3, 1.3),
            duration: 300.ms,
            curve: Curves.easeOut),
      ]),
    );
  }
}

class _RevealCard extends StatelessWidget {
  final String attackerRole, outcome;
  final Color atkColor, defColor;
  const _RevealCard(
      {super.key,
      required this.attackerRole,
      required this.outcome,
      required this.atkColor,
      required this.defColor});

  @override
  Widget build(BuildContext context) {
    final myRole = context.read<GameProvider>().playerRole ?? '';

    String headline;
    String subtext;
    Color resultColor;

    switch (outcome) {
      case 'attackerWins':
        final attackerIsMe = attackerRole == myRole;
        headline = attackerIsMe ? 'YOUR PIECE WINS' : 'OPPONENT WINS';
        subtext = attackerIsMe
            ? 'Your piece eliminated the defender!'
            : 'The attacker eliminated your piece.';
        resultColor = attackerIsMe ? AppTheme.accent : AppTheme.danger;
        break;
      case 'defenderWins':
        final defenderIsMe = attackerRole != myRole;
        headline = defenderIsMe ? 'YOUR PIECE WINS' : 'OPPONENT WINS';
        subtext = defenderIsMe
            ? 'Your piece held its ground!'
            : 'The defender eliminated your piece.';
        resultColor = defenderIsMe ? AppTheme.accent : AppTheme.danger;
        break;
      case 'bothEliminated':
        headline = 'BOTH ELIMINATED';
        subtext = 'Both pieces are removed from the board.';
        resultColor = AppTheme.textSecondary;
        break;
      default:
        headline = 'RESOLVED';
        subtext = '';
        resultColor = AppTheme.phGold;
    }

    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: resultColor, width: 2),
        boxShadow: [
          BoxShadow(color: resultColor.withOpacity(0.25), blurRadius: 30)
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('RESULT',
            style: GoogleFonts.cinzel(
                color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 5)),
        const SizedBox(height: 16),
        // Result icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: resultColor.withOpacity(0.15),
            border: Border.all(color: resultColor, width: 2),
          ),
          child: Center(
              child: Icon(
            outcome == 'bothEliminated'
                ? Icons.close_rounded
                : outcome == 'attackerWins'
                    ? (attackerRole == myRole
                        ? Icons.military_tech_rounded
                        : Icons.shield_outlined)
                    : (attackerRole != myRole
                        ? Icons.military_tech_rounded
                        : Icons.shield_outlined),
            color: resultColor,
            size: 28,
          )),
        ).animate().scale(
            begin: const Offset(0.6, 0.6),
            duration: 400.ms,
            curve: Curves.elasticOut),
        const SizedBox(height: 16),
        Text(headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
                color: resultColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2)),
        if (subtext.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(subtext,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
        ],
      ]),
    );
  }
}

// _PlayerToken: coloured circle with player label (no rank shown)
class _PlayerToken extends StatelessWidget {
  final Color color;
  final String label;
  const _PlayerToken({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
                child: Icon(Icons.person_rounded, color: color, size: 24)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      );
}

class _BotThinkingIndicator extends StatelessWidget {
  const _BotThinkingIndicator();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.phGold)),
          const SizedBox(width: 8),
          Text('Bot thinking...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _DrawDialog extends StatelessWidget {
  final GameProvider provider;
  const _DrawDialog({required this.provider});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
          child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.handshake, color: AppTheme.phGold, size: 40),
          const SizedBox(height: 16),
          Text('Draw Offered',
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Your opponent is offering a draw.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: provider.declineDraw,
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.border),
                        foregroundColor: AppTheme.textSecondary),
                    child: const Text('Decline'))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: provider.acceptDraw,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.phGold,
                        foregroundColor: Colors.black),
                    child: const Text('Accept'))),
          ]),
        ]),
      )),
    );
  }
}

// ─── Game Ended ───────────────────────────────────────────────────────────────

class _GameEndedScreen extends StatelessWidget {
  final GameProvider provider;
  const _GameEndedScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    final iWon = provider.winnerRole == provider.playerRole;
    final isDraw = provider.winReason == WinReason.draw;

    String headline, subtext;
    Color color;
    IconData icon;

    if (isDraw) {
      headline = 'STALEMATE';
      subtext = 'Both players agreed to a draw.';
      color = AppTheme.phGold;
      icon = Icons.handshake;
    } else if (iWon) {
      headline = 'VICTORY';
      color = AppTheme.accent;
      icon = Icons.military_tech_rounded;
      subtext = switch (provider.winReason) {
        WinReason.flagCaptured => 'You captured the enemy flag!',
        WinReason.flagMarched => 'Your flag reached enemy territory!',
        WinReason.resignation => 'Your opponent surrendered.',
        _ => '',
      };
    } else {
      headline = 'DEFEAT';
      color = AppTheme.phRed;
      icon = Icons.flag_rounded;
      subtext = switch (provider.winReason) {
        WinReason.flagCaptured => 'Your flag was captured.',
        WinReason.flagMarched => 'Enemy flag reached your territory.',
        WinReason.resignation => 'You resigned.',
        _ => '',
      };
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        const PhilippineBackground(),
        Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 80, color: color)
              .animate()
              .scale(duration: 700.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(headline,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 4,
              )).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
          const SizedBox(height: 12),
          Text(subtext,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center)
              .animate()
              .fadeIn(delay: 500.ms),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () {
              provider.resetGame();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LobbyScreen()),
                  (_) => false);
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('RETURN TO LOBBY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppTheme.borderLight)),
              textStyle: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 14),
            ),
          ).animate().fadeIn(delay: 700.ms),
        ])),
      ]),
    );
  }
}
