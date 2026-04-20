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
        const _PhilippineBackground(),
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
      const _PhSunWidget(size: 72),
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
            'This is a Beta Phase release. Expect some bugs and rough edges! A final polished version will be released in the future with more features and improvements.',
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.05);
  }
}

// ─── Bot Difficulty Dialog ────────────────────────────────────────────────────

class _BotDifficultyDialog extends StatelessWidget {
  const _BotDifficultyDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _PhSunWidget(size: 40),
          const SizedBox(height: 16),
          Text('SELECT DIFFICULTY',
              style: GoogleFonts.cinzel(
                  fontSize: 16, color: AppTheme.textPrimary, letterSpacing: 2)),
          const SizedBox(height: 20),
          ...BotDifficulty.values.map((d) => _DifficultyTile(difficulty: d)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ]),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final BotDifficulty difficulty;
  const _DifficultyTile({required this.difficulty});

  Color get _color {
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
        return 'Random moves. Great for beginners.';
      case BotDifficulty.medium:
        return 'Prefers captures. Some strategy.';
      case BotDifficulty.hard:
        return 'Tactical. Protects flag, uses spies.';
      case BotDifficulty.extreme:
        return 'Minimax AI. Will crush you.';
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          Navigator.pop(context);
          final provider = context.read<GameProvider>();
          await provider.startBotGame(difficulty);
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SetupScreen()),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _color.withOpacity(0.4)),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: _color.withOpacity(0.15), shape: BoxShape.circle),
              child: Center(
                  child:
                      Icon(Icons.smart_toy_rounded, color: _color, size: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text(BotAI(difficulty).difficultyLabel.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                            color: _color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(_stars, style: TextStyle(color: _color, fontSize: 11)),
                  ]),
                  Text(_desc,
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ])),
            Icon(Icons.chevron_right, color: _color, size: 18),
          ]),
        ),
      ),
    );
  }
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
          const _PhilippineBackground(),
          SafeArea(
              child: Center(
                  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _PhSunWidget(size: 60)
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

class _PhilippineBackground extends StatelessWidget {
  const _PhilippineBackground();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _PhBgPainter()),
    );
  }
}

class _PhBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle diagonal blue/red split (Philippine flag triangle)
    final paint = Paint()..style = PaintingStyle.fill;

    // Very subtle top-left navy gradient triangle
    paint.color = AppTheme.phNavy.withOpacity(0.07);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.45, 0)
      ..lineTo(0, size.height * 0.45)
      ..close();
    canvas.drawPath(path, paint);

    // Bottom-right subtle red
    paint.color = AppTheme.phRed.withOpacity(0.04);
    final path2 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width * 0.6, size.height)
      ..lineTo(size.width, size.height * 0.6)
      ..close();
    canvas.drawPath(path2, paint);

    // Horizontal stripe hints (very faint)
    paint.color = AppTheme.phNavy.withOpacity(0.03);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), paint);
    paint.color = AppTheme.phRed.withOpacity(0.03);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
        paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Philippine Sun Widget ────────────────────────────────────────────────────

class _PhSunWidget extends StatelessWidget {
  final double size;
  const _PhSunWidget({required this.size});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SunPainter()),
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final paint = Paint()
      ..color = AppTheme.phGold
      ..style = PaintingStyle.fill;

    // Draw 8 rays
    final rayPaint = Paint()
      ..color = AppTheme.phGold.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * pi / 180;
      final inner = r * 0.42;
      final outer = r * 0.88;
      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        rayPaint,
      );
    }

    // Sun circle
    canvas.drawCircle(center, r * 0.38, paint);

    // Inner detail circle
    final inner = Paint()
      ..color = AppTheme.background.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, r * 0.22, inner);

    // 3 stars (small)
    final starPaint = Paint()
      ..color = AppTheme.phGold
      ..style = PaintingStyle.fill;
    _drawStar(
        canvas, Offset(center.dx, center.dy - r * 0.18), r * 0.06, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = Offset(
        center.dx + radius * cos((i * 72 - 90) * pi / 180),
        center.dy + radius * sin((i * 72 - 90) * pi / 180),
      );
      final inner = Offset(
        center.dx + radius * 0.4 * cos(((i * 72 + 36) - 90) * pi / 180),
        center.dy + radius * 0.4 * sin(((i * 72 + 36) - 90) * pi / 180),
      );
      if (i == 0)
        path.moveTo(outer.dx, outer.dy);
      else
        path.lineTo(outer.dx, outer.dy);
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

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
