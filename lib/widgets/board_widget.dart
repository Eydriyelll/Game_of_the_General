// lib/widgets/board_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../models/board_position.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';
import '../utils/piece_assets.dart';

// ─── SETUP BOARD ─────────────────────────────────────────────────────────────

class SetupBoardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio: 9 / 8,
          child: _BoardGrid(
            buildCell: (row, col) {
              final pos = BoardPosition(row, col);
              final isMyRow = provider.isMySetupRow(row);
              final placedPiece = provider.localSetupBoard[pos.key];
              final holdingPiece = provider.selectedTrayPiece;

              return _SetupCell(
                position: pos,
                piece: placedPiece,
                isMyRow: isMyRow,
                isHoldingPiece: holdingPiece != null && isMyRow,
                isHeld: holdingPiece != null && placedPiece == holdingPiece,
                onTap: () => provider.tapSquareDuringSetup(pos),
                onDragAccept: (piece) => provider.dropPieceOnSquare(piece, pos),
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
  final bool isMyRow;
  final bool isHoldingPiece;
  final bool isHeld;
  final VoidCallback onTap;
  final void Function(Piece) onDragAccept;

  const _SetupCell({
    required this.position, required this.piece, required this.isMyRow,
    required this.isHoldingPiece, required this.isHeld,
    required this.onTap, required this.onDragAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Piece>(
      onAcceptWithDetails: (d) => onDragAccept(d.data),
      builder: (context, candidates, _) {
        final hovered = candidates.isNotEmpty;
        Color bg, borderColor;
        double borderWidth = 1;

        if (!isMyRow) {
          bg = AppTheme.boardDark.withOpacity(0.6);
          borderColor = AppTheme.border.withOpacity(0.2);
        } else if (hovered) {
          bg = AppTheme.validMoveBg;
          borderColor = AppTheme.accent;
          borderWidth = 2;
        } else if (isHoldingPiece && piece == null) {
          bg = AppTheme.validMoveBg.withOpacity(0.3);
          borderColor = AppTheme.accent.withOpacity(0.4);
        } else {
          bg = AppTheme.boardLight;
          borderColor = AppTheme.border;
        }

        // Checkerboard subtle effect
        final isEven = (position.row + position.col) % 2 == 0;
        if (isMyRow) bg = isEven ? bg : Color.lerp(bg, Colors.white, 0.03)!;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: piece != null
                ? _PieceTile(piece: piece!, isOwn: true, isDraggable: true, isSetup: true)
                : isMyRow
                    ? Center(child: Icon(Icons.add, color: AppTheme.textMuted.withOpacity(0.2), size: 12))
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
                    position: pos, piece: piece, isSelected: isSelected,
                    isValidMove: isValidMove, isOwn: isOwn,
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
    final color = role == 'player1' ? AppTheme.player1Color : AppTheme.player2Color;
    final isActive = provider.currentTurn == role;
    final label = isOpponent
        ? (provider.isBotGame ? 'BOT (${provider.bot?.difficultyLabel ?? ''})' : 'OPPONENT')
        : 'YOU';

    return Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.3),
          shape: BoxShape.circle,
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)] : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
        style: TextStyle(
          color: isActive ? color : color.withOpacity(0.5),
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5,
        )),
      if (isActive) ...[
        const SizedBox(width: 6),
        Text('▶ TURN',
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, letterSpacing: 1)),
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
    required this.position, required this.piece, required this.isSelected,
    required this.isValidMove, required this.isOwn, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, borderColor;
    double borderWidth = 1;
    List<BoxShadow>? shadows;

    final isEven = (position.row + position.col) % 2 == 0;
    final baseColor = isEven ? AppTheme.boardLight : AppTheme.boardDark;

    if (isSelected) {
      bg = AppTheme.selectedBg;
      borderColor = AppTheme.accent;
      borderWidth = 2;
      shadows = [BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 8)];
    } else if (isValidMove && piece != null) {
      bg = AppTheme.attackTargetBg;
      borderColor = AppTheme.danger.withOpacity(0.8);
      borderWidth = 1.5;
    } else if (isValidMove) {
      bg = AppTheme.validMoveBg;
      borderColor = AppTheme.accent.withOpacity(0.5);
    } else {
      bg = baseColor;
      borderColor = AppTheme.border.withOpacity(0.4);
    }

    Widget? content;
    if (piece != null) {
      content = _PieceTile(piece: piece!, isOwn: isOwn);
    } else if (isValidMove) {
      content = Center(
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 4)]),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: content,
      ),
    );
  }
}

// ─── Piece Tile (with actual piece image) ────────────────────────────────────

class _PieceTile extends StatelessWidget {
  final Piece piece;
  final bool isOwn;
  final bool isDraggable;
  final bool isSetup;

  const _PieceTile({
    required this.piece, required this.isOwn,
    this.isDraggable = false, this.isSetup = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOwn) return _EnemyTile();

    final rankColor = AppTheme.pieceRankColor(piece.rank.name);
    final isFlag = piece.rank == PieceRank.flag;

    Widget tile = Container(
      decoration: BoxDecoration(
        color: isFlag
            ? AppTheme.phGold.withOpacity(0.15)
            : AppTheme.ownPieceBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isFlag ? AppTheme.phGold.withOpacity(0.8) : rankColor.withOpacity(0.5),
          width: isFlag ? 1.5 : 1,
        ),
      ),
      child: _PieceImage(piece: piece, rankColor: rankColor),
    );

    if (!isDraggable) return tile;

    return Draggable<Piece>(
      data: piece,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppTheme.ownPieceBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: rankColor, width: 2),
            boxShadow: [BoxShadow(color: rankColor.withOpacity(0.5), blurRadius: 16)],
          ),
          child: _PieceImage(piece: piece, rankColor: rankColor),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: tile),
      child: tile,
    );
  }
}

class _PieceImage extends StatelessWidget {
  final Piece piece;
  final Color rankColor;
  const _PieceImage({required this.piece, required this.rankColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Image.asset(
        PieceAssets.assetPath(piece.rank),
        fit: BoxFit.contain,
        color: rankColor,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, __, ___) => Center(
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Text(
                piece.label,
                style: TextStyle(
                  color: rankColor, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnemyTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: AppTheme.enemyPieceBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.border.withOpacity(0.6)),
      ),
      child: Center(
        child: Icon(Icons.shield_rounded, color: AppTheme.textMuted.withOpacity(0.5), size: 14),
      ),
    );
  }
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
          children: List.generate(8, (row) {
            return Expanded(
              child: Row(
                children: List.generate(9, (col) {
                  return Expanded(child: buildCell(row, col));
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
