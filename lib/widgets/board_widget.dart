// lib/widgets/board_widget.dart
// Board uses PieceIcon (vector) for own pieces, shield icon for enemy pieces.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../models/board_position.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';
import 'piece_tray_widget.dart'; // for PieceIcon

// ─── SETUP BOARD ─────────────────────────────────────────────────────────────

class SetupBoardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      final held = provider.selectedTrayPiece;
      return Padding(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio: 9 / 8,
          child: _BoardGrid(
            buildCell: (row, col) {
              final pos = BoardPosition(row, col);
              final isMyRow = provider.isMySetupRow(row);
              final placedPiece = provider.localSetupBoard[pos.key];
              final isHeld = held != null &&
                  placedPiece != null &&
                  identical(held, placedPiece);
              return _SetupCell(
                position: pos,
                piece: placedPiece,
                isMyRow: isMyRow,
                isHoldingAny: held != null && isMyRow,
                isHeld: isHeld,
                onTap: () => provider.tapSquareDuringSetup(pos),
                onDragAccept: (p) => provider.dropPieceOnSquare(p, pos),
              );
            },
          ),
        ),
      );
    });
  }
}

class _SetupCell extends StatelessWidget {
  final BoardPosition position;
  final Piece? piece;
  final bool isMyRow, isHoldingAny, isHeld;
  final VoidCallback onTap;
  final void Function(Piece) onDragAccept;

  const _SetupCell({
    required this.position,
    required this.piece,
    required this.isMyRow,
    required this.isHoldingAny,
    required this.isHeld,
    required this.onTap,
    required this.onDragAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Piece>(
      onAcceptWithDetails: (d) => onDragAccept(d.data),
      builder: (ctx, candidates, _) {
        final hovered = candidates.isNotEmpty;
        Color bg, borderColor;
        double borderWidth = 1;

        if (!isMyRow) {
          bg = AppTheme.boardDark.withOpacity(0.5);
          borderColor = AppTheme.border.withOpacity(0.15);
        } else if (hovered) {
          bg = AppTheme.validMoveBg;
          borderColor = AppTheme.accent;
          borderWidth = 2;
        } else if (isHeld) {
          bg = AppTheme.selectedBg;
          borderColor = AppTheme.accent;
          borderWidth = 2;
        } else if (isHoldingAny && piece == null) {
          bg = AppTheme.validMoveBg.withOpacity(0.25);
          borderColor = AppTheme.accent.withOpacity(0.35);
        } else {
          final even = (position.row + position.col) % 2 == 0;
          bg = even ? AppTheme.boardLight : AppTheme.boardDark;
          borderColor = AppTheme.border.withOpacity(0.3);
        }

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: piece != null
                ? _OwnPieceTile(
                    piece: piece!, isDraggable: true, isHeld: isHeld)
                : isMyRow
                    ? Center(
                        child: Icon(Icons.add,
                            color: AppTheme.textMuted.withOpacity(0.18),
                            size: 11))
                    : null,
          ),
        );
      },
    );
  }
}

// ─── GAME BOARD ──────────────────────────────────────────────────────────────

class GameBoardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      final validMoves = provider.selectedPosition != null
          ? provider.getValidMoves(provider.selectedPosition!)
          : <BoardPosition>[];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(children: [
          _PlayerBadge(isOpponent: true, provider: provider),
          const SizedBox(height: 4),
          Expanded(
            child: AspectRatio(
              aspectRatio: 9 / 8,
              child: _BoardGrid(
                buildCell: (row, col) {
                  final pos = BoardPosition(row, col);
                  final pieceData = provider.board[pos.key];
                  final isSelected = provider.selectedPosition == pos;
                  final isValidMove = validMoves.contains(pos);
                  Piece? piece;
                  if (pieceData != null) piece = Piece.fromMap(pieceData);
                  final isOwn = piece != null && _isMyPiece(piece, provider);
                  return _GameCell(
                    position: pos,
                    piece: piece,
                    isSelected: isSelected,
                    isValidMove: isValidMove,
                    isOwn: isOwn,
                    onTap: () => provider.selectSquare(pos),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          _PlayerBadge(isOpponent: false, provider: provider),
        ]),
      );
    });
  }

  bool _isMyPiece(Piece piece, GameProvider p) {
    if (p.playerRole == 'player1') return piece.owner == PieceOwner.player1;
    return piece.owner == PieceOwner.player2;
  }
}

class _PlayerBadge extends StatelessWidget {
  final bool isOpponent;
  final GameProvider provider;
  const _PlayerBadge({required this.isOpponent, required this.provider});

  @override
  Widget build(BuildContext context) {
    final role = isOpponent
        ? (provider.playerRole == 'player1' ? 'player2' : 'player1')
        : provider.playerRole ?? 'player1';
    final color =
        role == 'player1' ? AppTheme.player1Color : AppTheme.player2Color;
    final isActive = provider.currentTurn == role;
    final label = isOpponent
        ? (provider.isBotGame
            ? 'BOT (${provider.bot?.difficultyLabel ?? ''})'
            : 'OPPONENT')
        : 'YOU';

    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.3),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)]
              : null,
        ),
      ),
      const SizedBox(width: 5),
      Text(label,
          style: TextStyle(
              color: isActive ? color : color.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5)),
      if (isActive) ...[
        const SizedBox(width: 5),
        Text('▶ TURN',
            style: TextStyle(
                color: color.withOpacity(0.6), fontSize: 9, letterSpacing: 1)),
      ],
    ]);
  }
}

class _GameCell extends StatelessWidget {
  final BoardPosition position;
  final Piece? piece;
  final bool isSelected, isValidMove, isOwn;
  final VoidCallback onTap;

  const _GameCell({
    required this.position,
    required this.piece,
    required this.isSelected,
    required this.isValidMove,
    required this.isOwn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final even = (position.row + position.col) % 2 == 0;
    Color bg = even ? AppTheme.boardLight : AppTheme.boardDark;
    Color borderColor = AppTheme.border.withOpacity(0.3);
    double borderWidth = 1;
    List<BoxShadow>? shadows;

    if (isSelected) {
      bg = AppTheme.selectedBg;
      borderColor = AppTheme.accent;
      borderWidth = 2;
      shadows = [
        BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 8)
      ];
    } else if (isValidMove && piece != null) {
      bg = AppTheme.attackTargetBg;
      borderColor = AppTheme.danger.withOpacity(0.8);
      borderWidth = 1.5;
    } else if (isValidMove) {
      bg = AppTheme.validMoveBg;
      borderColor = AppTheme.accent.withOpacity(0.5);
    }

    Widget? content;
    if (piece != null) {
      content = isOwn ? _OwnPieceTile(piece: piece!) : _EnemyTile();
    } else if (isValidMove) {
      content = Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 4)
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: content,
      ),
    );
  }
}

// ── Piece tiles ────────────────────────────────────────────────────────────

class _OwnPieceTile extends StatelessWidget {
  final Piece piece;
  final bool isDraggable;
  final bool isHeld;
  const _OwnPieceTile(
      {required this.piece, this.isDraggable = false, this.isHeld = false});

  @override
  Widget build(BuildContext context) {
    final rankColor = AppTheme.pieceRankColor(piece.rank.name);
    final isFlag = piece.rank == PieceRank.flag;

    Widget tile = Container(
      decoration: BoxDecoration(
        color: isFlag ? AppTheme.phGold.withOpacity(0.15) : AppTheme.ownPieceBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isHeld
              ? AppTheme.accent
              : (isFlag
                  ? AppTheme.phGold.withOpacity(0.7)
                  : rankColor.withOpacity(0.5)),
          width: isHeld ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: PieceIcon(rank: piece.rank, color: rankColor),
    );

    if (!isDraggable) return tile;

    return Draggable<Piece>(
      data: piece,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.ownPieceBg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: rankColor, width: 2),
            boxShadow: [
              BoxShadow(color: rankColor.withOpacity(0.5), blurRadius: 14)
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: PieceIcon(rank: piece.rank, color: rankColor),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.2, child: tile),
      child: tile,
    );
  }
}

class _EnemyTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: AppTheme.enemyPieceBg,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Center(
            child: Icon(Icons.shield_rounded,
                color: AppTheme.textMuted.withOpacity(0.45), size: 13)),
      );
}

// ─── Board Grid ───────────────────────────────────────────────────────────────

class _BoardGrid extends StatelessWidget {
  final Widget Function(int row, int col) buildCell;
  const _BoardGrid({required this.buildCell});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: List.generate(
              8,
              (row) => Expanded(
                    child: Row(
                      children: List.generate(
                          9, (col) => Expanded(child: buildCell(row, col))),
                    ),
                  )),
        ),
      ),
    );
  }
}
