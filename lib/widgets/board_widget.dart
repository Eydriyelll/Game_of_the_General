// lib/widgets/board_widget.dart
//
// DATA LAYER: Player 1 pieces stored at rows 0-2 (top). Player 2 at rows 5-7 (bottom).
// VIEW LAYER: Each player's screen flips so their pieces always appear at the BOTTOM.
//   • Player 1 sees the board normally  (row 0 at top,    row 7 at bottom)
//   • Player 2 sees the board flipped   (row 7 at top,    row 0 at bottom)
// This means Player 2's pieces at rows 5-7 appear at the BOTTOM of their screen,
// and Player 1's pieces at rows 0-2 appear at the BOTTOM of Player 1's screen.
// Both players always play "upward" from their own row-1 perspective.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../models/board_position.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';
import 'piece_tray_widget.dart'; // PieceIcon

// ─── SETUP BOARD ─────────────────────────────────────────────────────────────

class SetupBoardWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      // Player 2's view is flipped so their rows 5-7 appear at the bottom
      final isFlipped = provider.playerRole == 'player2';
      final held = provider.selectedTrayPiece;

      return Padding(
        padding: const EdgeInsets.all(4),
        child: _CoordBoard(
          isFlipped: isFlipped,
          buildCell: (dataRow, dataCol) {
            final pos = BoardPosition(dataRow, dataCol);
            final isMyRow = provider.isMySetupRow(dataRow);
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
        Color bg;
        Color borderColor;
        double bw = 1;

        if (!isMyRow) {
          bg = AppTheme.boardDark.withOpacity(0.5);
          borderColor = AppTheme.border.withOpacity(0.15);
        } else if (hovered) {
          bg = AppTheme.validMoveBg;
          borderColor = AppTheme.accent;
          bw = 2;
        } else if (isHeld) {
          bg = AppTheme.selectedBg;
          borderColor = AppTheme.accent;
          bw = 2;
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
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor, width: bw),
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
      // Flip board for Player 2 so their pieces appear at the bottom of their screen
      final isFlipped = provider.playerRole == 'player2';

      final validMoves = provider.selectedPosition != null
          ? provider.getValidMoves(provider.selectedPosition!)
          : <BoardPosition>[];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(children: [
          _PlayerBadge(isOpponent: true, provider: provider),
          const SizedBox(height: 4),
          Expanded(
            child: _CoordBoard(
              isFlipped: isFlipped,
              buildCell: (dataRow, dataCol) {
                final pos = BoardPosition(dataRow, dataCol);
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

// ─── Coordinate Board ─────────────────────────────────────────────────────────
//
// isFlipped = true  → Player 2's perspective: data row 7 shown at top visually,
//                     data row 0 shown at bottom. Labels: rows 1→8, cols I→A.
//                     Player 2's pieces (rows 5-7 in data) appear at the bottom.
//
// isFlipped = false → Player 1's perspective: data row 0 at top, row 7 at bottom.
//                     Labels: rows 8→1, cols A→I.
//                     Player 1's pieces (rows 0-2 in data) appear at the bottom.
//
// The buildCell callback always receives the TRUE data (row, col) coordinates
// so piece lookup, selection, and move logic are unaffected by the visual flip.

class _CoordBoard extends StatelessWidget {
  final bool isFlipped;
  final Widget Function(int dataRow, int dataCol) buildCell;

  const _CoordBoard({required this.isFlipped, required this.buildCell});

  @override
  Widget build(BuildContext context) {
    // Column labels A–I; when flipped reverse to I–A
    const colsNormal = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
    const colsFlipped = ['I', 'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A'];
    final colLabels = isFlipped ? colsFlipped : colsNormal;

    // Row labels: normal = 8→1 (top→bottom), flipped = 1→8 (top→bottom)
    // Normal:  display row 0 = data row 0 → label "8"
    // Flipped: display row 0 = data row 7 → label "1"
    final rowLabels = isFlipped
        ? ['1', '2', '3', '4', '5', '6', '7', '8'] // 1 at top when flipped
        : ['8', '7', '6', '5', '4', '3', '2', '1']; // 8 at top when normal

    const labelStyle = TextStyle(
      color: Color(0xFFAAB8D8),
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );

    return AspectRatio(
      // 9 board cols + 1 label col = 10 units wide
      // 8 board rows + 1 top label + 1 bottom label = 10 units tall → 10/10 = 1.0
      // But we want slightly wider than tall, so use 10/9
      aspectRatio: 10 / 9,
      child: Column(children: [
        // ── Top column labels ──
        SizedBox(
          height: 16,
          child: Row(children: [
            const SizedBox(width: 20),
            ...colLabels.map((c) => Expanded(
                  child: Center(child: Text(c, style: labelStyle)),
                )),
          ]),
        ),

        // ── Board rows + left row labels ──
        Expanded(
          child: Row(children: [
            // Left row labels
            SizedBox(
              width: 20,
              child: Column(
                children: rowLabels
                    .map((r) => Expanded(
                          child: Center(child: Text(r, style: labelStyle)),
                        ))
                    .toList(),
              ),
            ),
            // Grid
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Column(
                    children: List.generate(8, (displayRow) {
                      // Map display row → data row
                      // Normal:  displayRow 0 → dataRow 0
                      // Flipped: displayRow 0 → dataRow 7
                      final dataRow = isFlipped ? (7 - displayRow) : displayRow;

                      return Expanded(
                        child: Row(
                          children: List.generate(9, (displayCol) {
                            // Map display col → data col
                            // Normal:  displayCol 0 → dataCol 0 (A)
                            // Flipped: displayCol 0 → dataCol 8 (I)
                            final dataCol =
                                isFlipped ? (8 - displayCol) : displayCol;
                            return Expanded(child: buildCell(dataRow, dataCol));
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ]),
        ),

        // ── Bottom column labels (mirror of top) ──
        SizedBox(
          height: 16,
          child: Row(children: [
            const SizedBox(width: 20),
            ...colLabels.map((c) => Expanded(
                  child: Center(child: Text(c, style: labelStyle)),
                )),
          ]),
        ),
      ]),
    );
  }
}

// ─── Player Badge ─────────────────────────────────────────────────────────────

class _PlayerBadge extends StatelessWidget {
  final bool isOpponent;
  final GameProvider provider;
  const _PlayerBadge({required this.isOpponent, required this.provider});

  @override
  Widget build(BuildContext context) {
    // When board is flipped (Player 2), the opponent badge is at the top
    // and corresponds to Player 1 (their pieces are at the top of the flipped view).
    final myRole = provider.playerRole ?? 'player1';
    final oppRole = myRole == 'player1' ? 'player2' : 'player1';
    final role = isOpponent ? oppRole : myRole;

    final color =
        role == 'player1' ? AppTheme.player1Color : AppTheme.player2Color;
    final isActive = provider.currentTurn == role;

    final label = isOpponent
        ? (provider.isBotGame
            ? 'BOT · ${provider.bot?.difficultyLabel ?? ''} (${provider.bot?.rating ?? ''})'
            : 'OPPONENT')
        : 'YOU';

    return Row(children: [
      const SizedBox(width: 22),
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.3),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)]
              : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
            color: isActive ? color : color.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          )),
      if (isActive) ...[
        const SizedBox(width: 6),
        Text('▶ TURN',
            style: TextStyle(
                color: color.withOpacity(0.65), fontSize: 9, letterSpacing: 1)),
      ],
    ]);
  }
}

// ─── Game Cell ────────────────────────────────────────────────────────────────

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
    double bw = 1;
    List<BoxShadow>? shadows;

    if (isSelected) {
      bg = AppTheme.selectedBg;
      borderColor = AppTheme.accent;
      bw = 2;
      shadows = [
        BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: 8)
      ];
    } else if (isValidMove && piece != null) {
      bg = AppTheme.attackTargetBg;
      borderColor = AppTheme.danger.withOpacity(0.8);
      bw = 1.5;
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
          width: 8,
          height: 8,
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
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: bw),
          boxShadow: shadows,
        ),
        child: content,
      ),
    );
  }
}

// ─── Own Piece Tile ───────────────────────────────────────────────────────────

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
        border: Border.all(
          color: isHeld
              ? AppTheme.accent
              : (isFlag
                  ? AppTheme.phGold.withOpacity(0.7)
                  : rankColor.withOpacity(0.5)),
          width: isHeld ? 2 : 1,
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(3, 3, 3, 1),
              child: PieceIcon(rank: piece.rank, color: rankColor),
            )),
        Padding(
          padding: const EdgeInsets.fromLTRB(1, 0, 1, 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _pieceShortName(piece.rank),
              style: TextStyle(
                color: rankColor,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ]),
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

// ─── Enemy Tile ───────────────────────────────────────────────────────────────

class _EnemyTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.enemyPieceBg,
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Center(
          child: Icon(Icons.shield_rounded,
              color: AppTheme.textMuted.withOpacity(0.45), size: 13),
        ),
      );
}

// ─── Piece name helper ────────────────────────────────────────────────────────

String _pieceShortName(PieceRank rank) {
  switch (rank) {
    case PieceRank.fiveStar:
      return '5★ GEN';
    case PieceRank.fourStar:
      return '4★ GEN';
    case PieceRank.threeStar:
      return '3★ GEN';
    case PieceRank.twoStar:
      return '2★ GEN';
    case PieceRank.oneStar:
      return '1★ GEN';
    case PieceRank.colonel:
      return 'COL';
    case PieceRank.ltColonel:
      return 'LT COL';
    case PieceRank.major:
      return 'MAJ';
    case PieceRank.captain:
      return 'CPT';
    case PieceRank.firstLt:
      return '1st LT';
    case PieceRank.secondLt:
      return '2nd LT';
    case PieceRank.sergeant:
      return 'SGT';
    case PieceRank.spy:
      return 'SPY';
    case PieceRank.private:
      return 'PVT';
    case PieceRank.flag:
      return 'FLAG';
  }
}
