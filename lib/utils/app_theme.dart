// lib/utils/app_theme.dart
// Philippine-inspired theme: deep navy, crimson red, gold sun, white

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color phNavy       = Color(0xFF0038A8);
  static const Color phRed        = Color(0xFFCE1126);
  static const Color phGold       = Color(0xFFFCD116);
  static const Color phWhite      = Color(0xFFF5F0E8);

  static const Color background   = Color(0xFF0A0F1E);
  static const Color surface      = Color(0xFF0D1530);
  static const Color surfaceLight = Color(0xFF162044);
  static const Color border       = Color(0xFF1E2E5A);
  static const Color borderLight  = Color(0xFF2A4080);

  static const Color accent       = Color(0xFFFCD116);
  static const Color accentDim    = Color(0xFFB89A10);
  static const Color danger       = Color(0xFFCE1126);
  static const Color dangerDim    = Color(0xFF8B0D1A);
  static const Color success      = Color(0xFF2ECC71);

  static const Color textPrimary   = Color(0xFFF5F0E8);
  static const Color textSecondary = Color(0xFFAAB8D8);
  static const Color textMuted     = Color(0xFF4A5E8A);

  static const Color player1Color  = Color(0xFF388BFD);
  static const Color player2Color  = Color(0xFFCE1126);
  static const Color challengeColor= Color(0xFFFCD116);

  static const Color boardLight    = Color(0xFF0F1D40);
  static const Color boardDark     = Color(0xFF0A1530);
  static const Color ownPieceBg    = Color(0xFF0D1E4A);
  static const Color enemyPieceBg  = Color(0xFF1A0A0E);
  static const Color selectedBg    = Color(0xFF2A3D00);
  static const Color validMoveBg   = Color(0xFF0E2E1A);
  static const Color attackTargetBg= Color(0xFF2E0A10);

  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.cinzelDecorative(
      fontSize: 40, fontWeight: FontWeight.w700,
      color: textPrimary, letterSpacing: 2,
    ),
    displayMedium: GoogleFonts.cinzelDecorative(
      fontSize: 28, fontWeight: FontWeight.w700,
      color: textPrimary, letterSpacing: 1.5,
    ),
    headlineLarge: GoogleFonts.cinzel(
      fontSize: 22, fontWeight: FontWeight.w600,
      color: textPrimary, letterSpacing: 1,
    ),
    headlineMedium: GoogleFonts.cinzel(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: GoogleFonts.rajdhani(
      fontSize: 15, color: textPrimary, fontWeight: FontWeight.w500,
    ),
    bodyMedium: GoogleFonts.rajdhani(
      fontSize: 13, color: textSecondary,
    ),
    labelLarge: GoogleFonts.rajdhani(
      fontSize: 13, fontWeight: FontWeight.w700,
      color: textPrimary, letterSpacing: 1.5,
    ),
    labelSmall: GoogleFonts.rajdhani(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: textMuted, letterSpacing: 1,
    ),
  );

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: phRed,
      surface: surface,
      error: danger,
    ),
    textTheme: textTheme,
    useMaterial3: true,
  );

  static Color pieceRankColor(String rankName) {
    switch (rankName) {
      case 'fiveStar':
      case 'fourStar':
      case 'threeStar':  return const Color(0xFFFCD116);
      case 'twoStar':
      case 'oneStar':    return const Color(0xFFE8E8E8);
      case 'colonel':
      case 'ltColonel':  return const Color(0xFF4FC3F7);
      case 'major':
      case 'captain':    return const Color(0xFF81C784);
      case 'firstLt':
      case 'secondLt':
      case 'sergeant':   return const Color(0xFFAAB8D8);
      case 'spy':        return const Color(0xFFCE1126);
      case 'private':    return const Color(0xFF5A6E9A);
      case 'flag':       return const Color(0xFFFCD116);
      default:           return textSecondary;
    }
  }
}
