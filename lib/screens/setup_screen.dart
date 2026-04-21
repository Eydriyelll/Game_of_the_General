// lib/screens/setup_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_tray_widget.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      if (provider.phase.name == 'playing') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GameScreen()),
          );
        });
      }
      final myReady = provider.playerRole == 'player1'
          ? provider.player1Ready
          : provider.player2Ready;
      final opponentReady = provider.playerRole == 'player1'
          ? provider.player2Ready
          : provider.player1Ready;

      return WillPopScope(
        onWillPop: () async {
          _confirmReturnHome(context, provider);
          return false;
        },
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return isWide
                  ? _WideLayout(myReady: myReady, opponentReady: opponentReady)
                  : _NarrowLayout(
                      myReady: myReady, opponentReady: opponentReady);
            }),
          ),
        ),
      );
    });
  }
}

// ─── Layouts ─────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final bool myReady, opponentReady;
  const _WideLayout({required this.myReady, required this.opponentReady});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          flex: 3,
          child: Column(children: [
            _Header(myReady: myReady, opponentReady: opponentReady),
            Expanded(child: SetupBoardWidget()),
          ])),
      Container(width: 1, color: AppTheme.border),
      SizedBox(
        width: 300,
        child: Column(children: [
          _TrayHeader(),
          Expanded(child: PieceTrayWidget()),
          _ConfirmBtn(myReady: myReady),
          _ReturnHomeBtn(),
          const SizedBox(height: 8),
        ]),
      ),
    ]);
  }
}

class _NarrowLayout extends StatelessWidget {
  final bool myReady, opponentReady;
  const _NarrowLayout({required this.myReady, required this.opponentReady});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _Header(myReady: myReady, opponentReady: opponentReady),
      // Board takes the top 55%
      Expanded(
        flex: 11,
        child: SetupBoardWidget(),
      ),
      Container(height: 1, color: AppTheme.border),
      _TrayHeader(),
      // Tray grid takes remaining space
      Expanded(
        flex: 9,
        child: PieceTrayWidget(),
      ),
      _ConfirmBtn(myReady: myReady),
      _ReturnHomeBtn(),
      const SizedBox(height: 6),
    ]);
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool myReady, opponentReady;
  const _Header({required this.myReady, required this.opponentReady});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final myColor = provider.playerRole == 'player1'
        ? AppTheme.player1Color
        : AppTheme.player2Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(children: [
        Row(children: [
          _ReadyChip(label: 'YOU', ready: myReady, color: myColor),
          const Spacer(),
          Row(children: [
            Container(width: 3, height: 12, color: AppTheme.phNavy),
            Container(width: 3, height: 12, color: AppTheme.phGold),
            Container(width: 3, height: 12, color: AppTheme.phRed),
            const SizedBox(width: 8),
            Text('DEPLOY FORCES',
                style: GoogleFonts.cinzel(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    letterSpacing: 2)),
          ]),
          const Spacer(),
          _ReadyChip(
            label: provider.isBotGame ? 'BOT' : 'OPPONENT',
            ready: opponentReady,
            color: AppTheme.textSecondary,
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Tap a piece in the tray → tap a square to place it. '
          'Tap a placed piece to pick it up and move it.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _ReadyChip extends StatelessWidget {
  final String label;
  final bool ready;
  final Color color;
  const _ReadyChip(
      {required this.label, required this.ready, required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ready ? color.withOpacity(0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: ready ? color : AppTheme.border, width: ready ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
            size: 10,
            color: ready ? color : AppTheme.textMuted,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: ready ? color : AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ]),
      );
}

// ─── Tray Header ──────────────────────────────────────────────────────────────

class _TrayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final remaining = provider.unplacedPieces.length;
    final held = provider.selectedTrayPiece;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: [
        Text('PIECE TRAY',
            style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700)),
        if (held != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
            ),
            child: Text('${held.label} selected',
                style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ],
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: remaining > 0
                ? AppTheme.danger.withOpacity(0.12)
                : AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: remaining > 0 ? AppTheme.danger : AppTheme.accent),
          ),
          child: Text('$remaining left',
              style: TextStyle(
                  color: remaining > 0 ? AppTheme.danger : AppTheme.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─── Confirm Button ───────────────────────────────────────────────────────────

class _ConfirmBtn extends StatelessWidget {
  final bool myReady;
  const _ConfirmBtn({required this.myReady});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    if (myReady) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.accent),
          ),
          child: Text('✓ READY — WAITING',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 12)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
            duration: 1800.ms, color: AppTheme.accent.withOpacity(0.06)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: ElevatedButton(
        onPressed: provider.canConfirmSetup ? provider.confirmSetup : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.phGold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.border,
          disabledForegroundColor: AppTheme.textMuted,
          minimumSize: const Size(double.infinity, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 13),
        ),
        child: Text(provider.canConfirmSetup
            ? 'CONFIRM DEPLOYMENT'
            : 'PLACE ALL PIECES FIRST'),
      ),
    );
  }
}

// ─── Return Home Button ───────────────────────────────────────────────────────

class _ReturnHomeBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: TextButton.icon(
        onPressed: () =>
            _confirmReturnHome(context, context.read<GameProvider>()),
        icon: Icon(Icons.home_rounded, size: 15, color: AppTheme.textMuted),
        label: Text('Return to Lobby',
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
        style: TextButton.styleFrom(
          minimumSize: const Size(double.infinity, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

void _confirmReturnHome(BuildContext context, GameProvider provider) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      title: Text('Return to Lobby?',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      content: Text(
          'Your current setup will be lost and the game will be cancelled.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Stay', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            provider.resetGame();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LobbyScreen()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.home_rounded, size: 15),
          label: const Text('Go Home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.phNavy,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    ),
  );
}
