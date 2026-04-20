// lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';
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
          if (provider.showChallengeFlash) const _ChallengeFlash(),
          if (provider.drawOfferedBy != null && provider.drawOfferedBy != provider.playerRole)
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
    Expanded(child: Column(children: [
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
    if (provider.showMoveHistory) SizedBox(height: 150, child: MoveHistoryPanel()),
  ]);
}

class _Header extends StatelessWidget {
  final GameProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = provider.isMyTurn;
    final myColor = provider.playerRole == 'player1' ? AppTheme.player1Color : AppTheme.player2Color;

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
            border: Border.all(color: isMyTurn ? myColor : AppTheme.border, width: isMyTurn ? 1.5 : 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isMyTurn)
              Container(width: 7, height: 7, margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(color: myColor, shape: BoxShape.circle))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(end: const Offset(1.5, 1.5), duration: 600.ms),
            Text(isMyTurn ? 'YOUR TURN' : "OPPONENT'S TURN",
              style: TextStyle(
                color: isMyTurn ? myColor : AppTheme.textMuted,
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
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
            color: provider.showMoveHistory ? AppTheme.accent : AppTheme.textMuted, size: 20),
          tooltip: 'Move history',
          onPressed: provider.toggleMoveHistory,
        ),
        // Menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppTheme.border)),
          onSelected: (v) {
            if (v == 'draw') provider.offerDraw();
            if (v == 'resign') _confirmResign(context, provider);
          },
          itemBuilder: (_) => [
            if (!provider.isBotGame)
              PopupMenuItem(value: 'draw', child: Row(children: [
                Icon(Icons.handshake, color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text('Offer Draw', style: TextStyle(color: AppTheme.textPrimary)),
              ])),
            PopupMenuItem(value: 'resign', child: Row(children: [
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
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.border)),
      title: Text('Resign?', style: TextStyle(color: AppTheme.textPrimary)),
      content: Text('You will forfeit the match.', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); provider.resign(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          child: const Text('Resign', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }
}

class _ChallengeFlash extends StatelessWidget {
  const _ChallengeFlash();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        color: AppTheme.phGold.withOpacity(0.06),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.phGold, width: 2),
              boxShadow: [BoxShadow(color: AppTheme.phGold.withOpacity(0.35), blurRadius: 24, spreadRadius: 4)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bolt_rounded, color: AppTheme.phGold, size: 22),
              const SizedBox(width: 10),
              Text('CHALLENGE!', style: GoogleFonts.cinzel(
                color: AppTheme.phGold, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 3)),
              const SizedBox(width: 10),
              Icon(Icons.bolt_rounded, color: AppTheme.phGold, size: 22),
            ]),
          ).animate().scale(begin: const Offset(0.8, 0.8), duration: 200.ms).fadeIn(duration: 200.ms),
        ),
      ),
    ).animate().fadeIn(duration: 150.ms).then().fadeOut(delay: 900.ms, duration: 300.ms);
  }
}

class _BotThinkingIndicator extends StatelessWidget {
  const _BotThinkingIndicator();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.phGold)),
          const SizedBox(width: 8),
          Text('Bot thinking...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
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
      child: Center(child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.handshake, color: AppTheme.phGold, size: 40),
          const SizedBox(height: 16),
          Text('Draw Offered', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Your opponent is offering a draw.', style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: provider.declineDraw,
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.border), foregroundColor: AppTheme.textSecondary),
              child: const Text('Decline'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: provider.acceptDraw,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.phGold, foregroundColor: Colors.black),
              child: const Text('Accept'))),
          ]),
        ]),
      )),
    );
  }
}

class _PhilippineBackground extends StatelessWidget {
  const _PhilippineBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.phNavy.withOpacity(0.1),
              AppTheme.phGold.withOpacity(0.1),
              AppTheme.phRed.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
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
      headline = 'STALEMATE'; subtext = 'Both players agreed to a draw.';
      color = AppTheme.phGold; icon = Icons.handshake;
    } else if (iWon) {
      headline = 'VICTORY'; color = AppTheme.accent; icon = Icons.military_tech_rounded;
      subtext = switch (provider.winReason) {
        WinReason.flagCaptured => 'You captured the enemy flag!',
        WinReason.flagMarched  => 'Your flag reached enemy territory!',
        WinReason.resignation  => 'Your opponent surrendered.',
        _ => '',
      };
    } else {
      headline = 'DEFEAT'; color = AppTheme.phRed; icon = Icons.flag_rounded;
      subtext = switch (provider.winReason) {
        WinReason.flagCaptured => 'Your flag was captured.',
        WinReason.flagMarched  => 'Enemy flag reached your territory.',
        WinReason.resignation  => 'You resigned.',
        _ => '',
      };
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        const _PhilippineBackground(),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 80, color: color)
              .animate().scale(duration: 700.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(headline,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 40, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 4,
            )).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
          const SizedBox(height: 12),
          Text(subtext, style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () {
              provider.resetGame();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LobbyScreen()), (_) => false);
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('RETURN TO LOBBY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight, foregroundColor: AppTheme.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppTheme.borderLight)),
              textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 14),
            ),
          ).animate().fadeIn(delay: 700.ms),
        ])),
      ]),
    );
  }
}
