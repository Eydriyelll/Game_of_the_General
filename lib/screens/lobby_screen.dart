// lib/screens/lobby_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/game_provider.dart';
import '../services/bot_ai.dart';
import '../utils/app_theme.dart';
import '../widgets/ph_decorators.dart';
import 'setup_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  bool _isCreating = false;
  String? _error;
  bool _showJoinField = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _isCreating = true;
      _error = null;
    });
    final provider = context.read<GameProvider>();
    final code = await provider.createRoom();
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => WaitingForPlayerScreen(roomCode: code)),
      );
    }
    setState(() => _isCreating = false);
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _error = 'Enter a valid room code');
      return;
    }
    setState(() {
      _isJoining = true;
      _error = null;
    });
    final provider = context.read<GameProvider>();
    final success = await provider.joinRoom(code);
    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      } else {
        setState(() {
          _error = 'Room not found. Check the code and try again.';
          _isJoining = false;
        });
      }
    }
  }

  void _showBotDifficultyDialog() {
    showDialog(context: context, builder: (_) => const _BotDifficultyDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        const PhilippineBackground(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildCard(),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      // Philippine sun
      const PhSunWidget(size: 72),
      const SizedBox(height: 20),
      Text(
        'GAME OF THE',
        textAlign: TextAlign.center,
        style: GoogleFonts.cinzelDecorative(
          fontSize: 14,
          letterSpacing: 5,
          color: AppTheme.textSecondary,
        ),
      ).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 4),
      Text(
        'GENERALS',
        textAlign: TextAlign.center,
        style: GoogleFonts.cinzelDecorative(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: 3,
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
      const SizedBox(height: 2),
      Text(
        'Games of the General',
        textAlign: TextAlign.center,
        style: GoogleFonts.rajdhani(
          fontSize: 11,
          letterSpacing: 3,
          color: AppTheme.textSecondary.withOpacity(0.6),
          fontStyle: FontStyle.italic,
        ),
      ).animate().fadeIn(delay: 400.ms),
      const SizedBox(height: 6),
      // Philippine flag stripe
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 60, height: 3, color: AppTheme.phNavy),
        Container(width: 40, height: 3, color: AppTheme.phGold),
        Container(width: 60, height: 3, color: AppTheme.phRed),
      ]).animate().fadeIn(delay: 500.ms).scaleX(begin: 0),
      const SizedBox(height: 8),
      Text(
        'SALPAKAN',
        textAlign: TextAlign.center,
        style: GoogleFonts.rajdhani(
          fontSize: 12,
          letterSpacing: 8,
          color: AppTheme.accent,
          fontWeight: FontWeight.w600,
        ),
      ).animate().fadeIn(delay: 600.ms),
    ]);
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
              color: AppTheme.phNavy.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Section: Multiplayer
        _SectionLabel(label: 'MULTIPLAYER'),
        const SizedBox(height: 12),
        _PhButton(
          label: _isCreating ? 'CREATING ROOM...' : 'CREATE ROOM',
          icon: Icons.add_circle_outline_rounded,
          color: AppTheme.phNavy,
          borderColor: AppTheme.borderLight,
          onPressed: _isCreating || _isJoining ? null : _createRoom,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 10),
        if (!_showJoinField)
          _PhButton(
            label: 'JOIN ROOM',
            icon: Icons.login_rounded,
            color: AppTheme.surfaceLight,
            borderColor: AppTheme.borderLight,
            textColor: AppTheme.textPrimary,
            onPressed: () => setState(() => _showJoinField = true),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2)
        else
          Column(children: [
            TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: GoogleFonts.rajdhani(
                fontSize: 28,
                letterSpacing: 10,
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'ROOM CODE',
                hintStyle: GoogleFonts.rajdhani(
                    color: AppTheme.textMuted, letterSpacing: 4),
                counterText: '',
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.accent, width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.border)),
              ),
              onSubmitted: (_) => _joinRoom(),
            ).animate().fadeIn(duration: 200.ms),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _PhButton(
                      label: 'CANCEL',
                      icon: Icons.close,
                      color: AppTheme.surfaceLight,
                      borderColor: AppTheme.border,
                      textColor: AppTheme.textSecondary,
                      onPressed: () => setState(() {
                            _showJoinField = false;
                            _codeController.clear();
                            _error = null;
                          }))),
              const SizedBox(width: 8),
              Expanded(
                  child: _PhButton(
                      label: _isJoining ? 'JOINING...' : 'JOIN',
                      icon: Icons.check,
                      color: AppTheme.phRed,
                      onPressed: _isJoining ? null : _joinRoom)),
            ]),
          ]),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 20),
        _Divider(label: 'OR'),
        const SizedBox(height: 20),

        // Section: Single Player vs Bot
        _SectionLabel(label: 'VS COMPUTER'),
        const SizedBox(height: 12),
        _PhButton(
          label: 'PLAY VS BOT',
          icon: Icons.smart_toy_rounded,
          color: AppTheme.phGold,
          textColor: Colors.black,
          onPressed: _showBotDifficultyDialog,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'Filipino Strategy Board Game • Est. 1970',
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.05);
  }
}

// ─── Bot Difficulty Dialog ────────────────────────────────────────────────────

// ─── Bot Difficulty + Role Dialog (2-step) ──────────────────────────────────

class _BotDifficultyDialog extends StatefulWidget {
  const _BotDifficultyDialog();
  @override
  State<_BotDifficultyDialog> createState() => _BotDifficultyDialogState();
}

class _BotDifficultyDialogState extends State<_BotDifficultyDialog> {
  BotDifficulty? _selectedDifficulty;
  String? _selectedRole; // 'player1' or 'player2'

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const PhSunWidget(size: 36),
          const SizedBox(height: 14),
          Text('VS COMPUTER',
              style: GoogleFonts.cinzel(
                  fontSize: 15, color: AppTheme.textPrimary, letterSpacing: 2)),
          const SizedBox(height: 18),

          // ── Step 1: Difficulty ──
          _StepLabel(number: '1', label: 'SELECT DIFFICULTY'),
          const SizedBox(height: 8),
          ...BotDifficulty.values.map((d) => _DiffTile(
                difficulty: d,
                isSelected: _selectedDifficulty == d,
                onTap: () => setState(() => _selectedDifficulty = d),
              )),

          const SizedBox(height: 16),

          // ── Step 2: Choose Side ──
          _StepLabel(number: '2', label: 'CHOOSE YOUR SIDE'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _RoleTile(
              role: 'player1',
              label: 'PLAYER 1',
              subtitle: 'Moves first • Blue side',
              icon: Icons.looks_one_rounded,
              color: AppTheme.player1Color,
              isSelected: _selectedRole == 'player1',
              onTap: () => setState(() => _selectedRole = 'player1'),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: _RoleTile(
              role: 'player2',
              label: 'PLAYER 2',
              subtitle: 'Moves second • Red side',
              icon: Icons.looks_two_rounded,
              color: AppTheme.player2Color,
              isSelected: _selectedRole == 'player2',
              onTap: () => setState(() => _selectedRole = 'player2'),
            )),
          ]),

          const SizedBox(height: 20),

          // ── Start button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedDifficulty != null && _selectedRole != null)
                  ? () async {
                      final d = _selectedDifficulty!;
                      final r = _selectedRole!;
                      Navigator.pop(context);
                      final provider = context.read<GameProvider>();
                      await provider.startBotGame(d, role: r);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const SetupScreen()),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.phGold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppTheme.border,
                disabledForegroundColor: AppTheme.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 2),
              ),
              child: const Text('START BATTLE'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number, label;
  const _StepLabel({required this.number, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 20,
          height: 20,
          decoration:
              BoxDecoration(color: AppTheme.phGold, shape: BoxShape.circle),
          child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700)),
      ]);
}

class _DiffTile extends StatelessWidget {
  final BotDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;
  const _DiffTile(
      {required this.difficulty,
      required this.isSelected,
      required this.onTap});

  Color get _c {
    switch (difficulty) {
      case BotDifficulty.easy:
        return const Color(0xFF2ECC71);
      case BotDifficulty.medium:
        return const Color(0xFFF39C12);
      case BotDifficulty.hard:
        return const Color(0xFFE74C3C);
      case BotDifficulty.extreme:
        return const Color(0xFF8E44AD);
    }
  }

  String get _desc {
    switch (difficulty) {
      case BotDifficulty.easy:
        return 'Random moves';
      case BotDifficulty.medium:
        return 'Prefers captures';
      case BotDifficulty.hard:
        return 'Tactical + flag-aware';
      case BotDifficulty.extreme:
        return 'Minimax AI';
    }
  }

  String get _stars {
    switch (difficulty) {
      case BotDifficulty.easy:
        return '★☆☆☆';
      case BotDifficulty.medium:
        return '★★☆☆';
      case BotDifficulty.hard:
        return '★★★☆';
      case BotDifficulty.extreme:
        return '★★★★';
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _c.withOpacity(0.15) : _c.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _c : _c.withOpacity(0.25),
                  width: isSelected ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _c,
                  size: 16),
              const SizedBox(width: 10),
              Expanded(
                  child: Row(children: [
                Text(BotAI(difficulty).difficultyLabel.toUpperCase(),
                    style: TextStyle(
                        color: _c,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(width: 6),
                Text(_stars, style: TextStyle(color: _c, fontSize: 10)),
              ])),
              Text(_desc,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ]),
          ),
        ),
      );
}

class _RoleTile extends StatelessWidget {
  final String role, label, subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleTile({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected ? color : AppTheme.border,
                width: isSelected ? 2 : 1),
          ),
          child: Column(children: [
            Icon(icon,
                color: isSelected ? color : AppTheme.textMuted, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? color : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ─── Waiting for Player Screen ───────────────────────────────────────────────

class WaitingForPlayerScreen extends StatelessWidget {
  final String roomCode;
  const WaitingForPlayerScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      if (provider.player2Joined) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SetupScreen()),
          );
        });
      }
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(children: [
          const PhilippineBackground(),
          SafeArea(
              child: Center(
                  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PhSunWidget(size: 60)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.1, 1.1),
                            duration: 1500.ms),
                    const SizedBox(height: 32),
                    Text(
                      'AWAITING REINFORCEMENTS',
                      style: GoogleFonts.cinzel(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          letterSpacing: 2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share this room code with your opponent',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _RoomCodeDisplay(code: roomCode),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: AppTheme.phNavy, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('Both devices must be on the same network',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                    ]),
                  ]),
            ),
          ))),
        ]),
      );
    });
  }
}

class _RoomCodeDisplay extends StatelessWidget {
  final String code;
  const _RoomCodeDisplay({required this.code});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Code copied!'), duration: Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent, width: 2),
          boxShadow: [
            BoxShadow(color: AppTheme.accent.withOpacity(0.2), blurRadius: 20)
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(code,
              style: GoogleFonts.rajdhani(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
                letterSpacing: 10,
              )),
          const SizedBox(width: 14),
          Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: AppTheme.accent.withOpacity(0.15));
  }
}

// ─── Philippine Background Decoration ────────────────────────────────────────

// ─── Reusable UI Components ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.rajdhani(
        color: AppTheme.textMuted,
        fontSize: 10,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w700,
      ));
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Container(height: 1, color: AppTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.border)),
      ]);
}

class _PhButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? borderColor;
  final Color? textColor;
  final VoidCallback? onPressed;

  const _PhButton({
    required this.label,
    required this.icon,
    required this.color,
    this.borderColor,
    this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border:
                borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                color: onPressed == null ? fg.withOpacity(0.4) : fg, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.rajdhani(
                  color: onPressed == null ? fg.withOpacity(0.4) : fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 1.5,
                )),
          ]),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
        ),
        child: Text(message,
            style: TextStyle(color: AppTheme.danger, fontSize: 12),
            textAlign: TextAlign.center),
      );
}
