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
        'GAMES OF THE',
        textAlign: TextAlign.center,
        style: GoogleFonts.cinzelDecorative(
          fontSize: 13,
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

        const SizedBox(height: 20),
        Divider(color: AppTheme.border.withOpacity(0.5)),
        const SizedBox(height: 12),
        // Bug report button
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showBugReportDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border.withOpacity(0.5)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.bug_report_rounded,
                  color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Text('Report a Bug / Suggest a Feature',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.5)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '🎖 Beta Version — This game is still being actively developed. '
            'More features, improvements, and fixes are on the way. '
            'Enjoy the current build and please use the button above '
            'to report any bugs or share your suggestions!',
            style: TextStyle(
                color: AppTheme.textMuted.withOpacity(0.7),
                fontSize: 9,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
      ]),
    ).animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.05);
  }
}

void _showBugReportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => _BugReportDialog(),
  );
}

class _BugReportDialog extends StatefulWidget {
  @override
  State<_BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<_BugReportDialog> {
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final subject = Uri.encodeComponent(_subjectCtrl.text.trim());
    final body = Uri.encodeComponent(_bodyCtrl.text.trim() +
        '\n\n--- Sent from Games of the General App ---');
    final mailtoUrl =
        'mailto:araos.adriel06@gmail.com?subject=$subject&body=$body';
    await _launchMailto(
        context, mailtoUrl, _subjectCtrl.text.trim(), _bodyCtrl.text.trim());
    if (mounted) {
      setState(() => _sending = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      title: Row(children: [
        Icon(Icons.bug_report_rounded, color: AppTheme.phGold, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text('Report Bug / Suggest Feature',
              style: GoogleFonts.cinzel(
                  color: AppTheme.textPrimary, fontSize: 13)),
        ),
      ]),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Your report will be copied to your clipboard so you can '
            'paste it into an email to the developer.',
            style: TextStyle(
                color: AppTheme.textSecondary, fontSize: 11, height: 1.45),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _subjectCtrl,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: _inputDeco('Subject (e.g. Bug: pieces duplicate)'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bodyCtrl,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration:
                _inputDeco('Describe the bug or suggestion in detail...'),
            maxLines: 4,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.phNavy.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(children: [
              Icon(Icons.mail_outline_rounded,
                  color: AppTheme.accent, size: 13),
              const SizedBox(width: 6),
              Flexible(
                child: Text('araos.adriel06@gmail.com',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: _sending ? null : _submit,
          icon: Icon(
              _sending ? Icons.hourglass_empty_rounded : Icons.send_rounded,
              size: 16),
          label: Text(_sending ? 'Preparing...' : 'Send Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.phGold,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      filled: true,
      fillColor: AppTheme.surfaceLight,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

Future<void> _launchMailto(
    BuildContext context, String mailtoUrl, String subject, String body) async {
  final fullReport = 'TO: araos.adriel06@gmail.com\n'
      'SUBJECT: $subject\n\n'
      '$body\n\n'
      '--- Sent from Games of the General App ---';

  // Copy immediately so even if dialog is dismissed the text is in clipboard
  await Clipboard.setData(ClipboardData(text: fullReport));

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      title: Row(children: [
        Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        Text('Report Copied!',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
      ]),
      content: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your report has been copied to clipboard. '
                'Open your email app and paste it in a new message to:',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.7)),
                ),
                child: SelectableText(
                  'araos.adriel06@gmail.com',
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              Text('Preview of your report:',
                  style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 1)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: SelectableText(
                  fullReport,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10, height: 1.5),
                ),
              ),
            ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Done', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: fullReport));
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Copied to clipboard again!'),
                duration: Duration(seconds: 2),
              ));
            }
          },
          icon: const Icon(Icons.copy_all_rounded, size: 15),
          label: const Text('Copy Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.phGold,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    ),
  );
}

// ─── Bot Difficulty Dialog ────────────────────────────────────────────────────

// ─── Bot Difficulty + Role Dialog (2-step) ──────────────────────────────────

class _BotDifficultyDialog extends StatefulWidget {
  const _BotDifficultyDialog();
  @override
  State<_BotDifficultyDialog> createState() => _BotDifficultyDialogState();
}

class _BotDifficultyDialogState extends State<_BotDifficultyDialog> {
  double _rating = 800; // 100 – 3200
  String? _selectedRole;

  BotAI get _previewBot => BotAI.fromRating(_rating.round());

  @override
  Widget build(BuildContext context) {
    final bot = _previewBot;
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const PhSunWidget(size: 34),
          const SizedBox(height: 12),
          Text('VS COMPUTER',
              style: GoogleFonts.cinzel(
                  fontSize: 15, color: AppTheme.textPrimary, letterSpacing: 2)),
          const SizedBox(height: 18),

          // ── Step 1: Rating Slider ──
          _StepLabel(number: '1', label: 'SET BOT RATING'),
          const SizedBox(height: 12),

          // Rating display badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bot.difficultyColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bot.difficultyColor.withOpacity(0.6)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${_rating.round()}',
                  style: GoogleFonts.cinzel(
                      color: bot.difficultyColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bot.difficultyLabel.toUpperCase(),
                    style: TextStyle(
                        color: bot.difficultyColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 1)),
                Text(_ratingDescription(_rating.round()),
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: bot.difficultyColor,
              thumbColor: bot.difficultyColor,
              overlayColor: bot.difficultyColor.withOpacity(0.2),
              inactiveTrackColor: AppTheme.border,
              trackHeight: 4,
            ),
            child: Slider(
              value: _rating,
              min: 100, max: 3200,
              divisions: 62, // steps of ~50
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('100\nEasiest',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 8),
                textAlign: TextAlign.center),
            Text('1600\nIntermediate',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 8),
                textAlign: TextAlign.center),
            Text('3200\nHardest',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 8),
                textAlign: TextAlign.center),
          ]),

          const SizedBox(height: 18),

          // ── Step 2: Choose Side ──
          _StepLabel(number: '2', label: 'CHOOSE YOUR SIDE'),
          const SizedBox(height: 10),
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

          // ── Start ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRole != null
                  ? () async {
                      final r = _selectedRole!;
                      final rating = _rating.round();
                      Navigator.pop(context);
                      final provider = context.read<GameProvider>();
                      await provider.startBotGame(BotDifficulty.easy,
                          role: r, rating: rating);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => const SetupScreen()));
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: bot.difficultyColor,
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
              child: Text('START BATTLE — Rating ${_rating.round()}'),
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

  String _ratingDescription(int r) {
    if (r < 400) return 'Random moves only';
    if (r < 700) return 'Slightly prefers captures';
    if (r < 1100) return 'Basic tactical awareness';
    if (r < 1400) return 'Targets high-value pieces';
    if (r < 1700) return 'Protects flag, uses spies';
    if (r < 2000) return 'Multi-step planning';
    if (r < 2400) return 'Strong tactical play';
    if (r < 2800) return 'Near-optimal strategy';
    return 'Virtually unbeatable';
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
                    const SizedBox(height: 32),
                    // Return to lobby button
                    TextButton.icon(
                      onPressed: () {
                        context.read<GameProvider>().resetGame();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LobbyScreen()),
                          (_) => false,
                        );
                      },
                      icon: Icon(Icons.arrow_back_rounded,
                          size: 16, color: AppTheme.textMuted),
                      label: Text('Back to Lobby',
                          style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              letterSpacing: 0.5)),
                      style: TextButton.styleFrom(
                        side: BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
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
