// lib/widgets/piece_tray_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';
import '../utils/piece_assets.dart';

class PieceTrayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      final pieces = provider.unplacedPieces;
      final selected = provider.selectedTrayPiece;

      if (pieces.isEmpty) {
        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 28),
          const SizedBox(height: 6),
          Text('All pieces placed!',
            style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 12)),
        ]));
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: pieces.map((piece) {
            final isSelected = selected?.rank == piece.rank && selected?.owner == piece.owner && selected == piece;
            final rankColor = AppTheme.pieceRankColor(piece.rank.name);
            final isFlag = piece.rank == PieceRank.flag;

            return GestureDetector(
              onTap: () => provider.selectPieceFromTray(piece),
              child: Draggable<Piece>(
                data: piece,
                onDragStarted: () => provider.selectPieceFromTray(piece),
                feedback: Material(
                  color: Colors.transparent,
                  child: _TrayCard(piece: piece, rankColor: rankColor, isSelected: true, isFlag: isFlag),
                ),
                childWhenDragging: Opacity(opacity: 0.2,
                  child: _TrayCard(piece: piece, rankColor: rankColor, isSelected: false, isFlag: isFlag)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: isSelected ? BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: rankColor.withOpacity(0.6), blurRadius: 14, spreadRadius: 1)],
                  ) : null,
                  child: _TrayCard(piece: piece, rankColor: rankColor, isSelected: isSelected, isFlag: isFlag),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class _TrayCard extends StatelessWidget {
  final Piece piece;
  final Color rankColor;
  final bool isSelected;
  final bool isFlag;

  const _TrayCard({
    required this.piece, required this.rankColor,
    required this.isSelected, required this.isFlag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58, height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? rankColor.withOpacity(0.2)
            : isFlag
                ? AppTheme.phGold.withOpacity(0.08)
                : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? rankColor : isFlag ? AppTheme.phGold.withOpacity(0.5) : AppTheme.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 34, height: 34,
          child: Image.asset(
            PieceAssets.assetPath(piece.rank),
            fit: BoxFit.contain,
            color: rankColor,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => Center(
              child: Text(piece.label,
                style: TextStyle(color: rankColor, fontSize: 8, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(width: 24, height: 1.5,
          decoration: BoxDecoration(
            color: rankColor.withOpacity(isSelected ? 0.7 : 0.3),
            borderRadius: BorderRadius.circular(1),
          )),
      ]),
    );
  }
}
