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
      final myReady = provider.playerRole == 'player1' ? provider.player1Ready : provider.player2Ready;
      final opponentReady = provider.playerRole == 'player1' ? provider.player2Ready : provider.player1Ready;

      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return isWide
              ? _WideLayout(myReady: myReady, opponentReady: opponentReady)
              : _NarrowLayout(myReady: myReady, opponentReady: opponentReady);
        })),
      );
    });
  }
}

class _WideLayout extends StatelessWidget {
  final bool myReady, opponentReady;
  const _WideLayout({required this.myReady, required this.opponentReady});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(flex: 3, child: Column(children: [
      _Header(myReady: myReady, opponentReady: opponentReady),
      Expanded(child: SetupBoardWidget()),
    ])),
    Container(width: 1, color: AppTheme.border),
    SizedBox(width: 260, child: Column(children: [
      _TrayHeader(),
      Expanded(child: PieceTrayWidget()),
      _ConfirmBtn(myReady: myReady),
    ])),
  ]);
}

class _NarrowLayout extends StatelessWidget {
  final bool myReady, opponentReady;
  const _NarrowLayout({required this.myReady, required this.opponentReady});
  @override
  Widget build(BuildContext context) => Column(children: [
    _Header(myReady: myReady, opponentReady: opponentReady),
    Expanded(flex: 3, child: SetupBoardWidget()),
    Container(height: 1, color: AppTheme.border),
    _TrayHeader(),
    SizedBox(height: 100, child: PieceTrayWidget()),
    _ConfirmBtn(myReady: myReady),
    const SizedBox(height: 8),
  ]);
}

class _Header extends StatelessWidget {
  final bool myReady, opponentReady;
  const _Header({required this.myReady, required this.opponentReady});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final myColor = provider.playerRole == 'player1' ? AppTheme.player1Color : AppTheme.player2Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(children: [
        Row(children: [
          _ReadyChip(label: 'YOU', ready: myReady, color: myColor),
          const Spacer(),
          Row(children: [
            Container(width: 3, height: 14, color: AppTheme.phNavy),
            Container(width: 3, height: 14, color: AppTheme.phGold),
            Container(width: 3, height: 14, color: AppTheme.phRed),
            const SizedBox(width: 8),
            Text('DEPLOY FORCES',
              style: GoogleFonts.cinzel(color: AppTheme.textPrimary, fontSize: 13, letterSpacing: 2)),
          ]),
          const Spacer(),
          _ReadyChip(
            label: provider.isBotGame ? 'BOT' : 'OPPONENT',
            ready: opponentReady,
            color: AppTheme.textSecondary,
          ),
        ]),
        const SizedBox(height: 6),
        Text('Place all 21 pieces on your first 3 rows. Tap to select then tap to place, or drag.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
          textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ReadyChip extends StatelessWidget {
  final String label;
  final bool ready;
  final Color color;
  const _ReadyChip({required this.label, required this.ready, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ready ? color.withOpacity(0.15) : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ready ? color : AppTheme.border, width: ready ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ready ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
          size: 11, color: ready ? color : AppTheme.textMuted),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: ready ? color : AppTheme.textMuted,
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ]),
    );
  }
}

class _TrayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final remaining = provider.unplacedPieces.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Text('PIECE TRAY', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: remaining > 0 ? AppTheme.danger.withOpacity(0.12) : AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: remaining > 0 ? AppTheme.danger : AppTheme.accent),
          ),
          child: Text('$remaining left',
            style: TextStyle(color: remaining > 0 ? AppTheme.danger : AppTheme.accent,
              fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _ConfirmBtn extends StatelessWidget {
  final bool myReady;
  const _ConfirmBtn({required this.myReady});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    if (myReady) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.accent),
          ),
          child: Text('✓ READY — WAITING FOR OPPONENT',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(color: AppTheme.accent, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 13)),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .shimmer(duration: 1800.ms, color: AppTheme.accent.withOpacity(0.08)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        onPressed: provider.canConfirmSetup ? provider.confirmSetup : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.phGold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.border,
          disabledForegroundColor: AppTheme.textMuted,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 14),
        ),
        child: Text(provider.canConfirmSetup ? 'CONFIRM DEPLOYMENT' : 'PLACE ALL PIECES FIRST'),
      ),
    );
  }
}
