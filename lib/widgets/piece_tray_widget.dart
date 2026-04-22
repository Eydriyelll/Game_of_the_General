// lib/widgets/piece_tray_widget.dart
//
// Piece tray displayed as a game-inventory style GRID, pieces in rank order.
// Each of the 21 slots shows:
//   • Available (in tray) → selectable, draggable, full color
//   • Placed on board     → greyed-out ghost (so player can see the full set)
//   • Held (selected)     → highlighted with glow
//
// Vector icons drawn with CustomPainter — no image assets required.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';

// ── Canonical 21-slot order (rank, then duplicates in sequence) ──────────────
const List<PieceRank> _kTrayOrder = [
  PieceRank.fiveStar,
  PieceRank.fourStar,
  PieceRank.threeStar,
  PieceRank.twoStar,
  PieceRank.oneStar,
  PieceRank.colonel,
  PieceRank.ltColonel,
  PieceRank.major,
  PieceRank.captain,
  PieceRank.firstLt,
  PieceRank.secondLt,
  PieceRank.sergeant,
  PieceRank.spy, // slot 0
  PieceRank.spy, // slot 1
  PieceRank.private, // slot 0
  PieceRank.private, // slot 1
  PieceRank.private, // slot 2
  PieceRank.private, // slot 3
  PieceRank.private, // slot 4
  PieceRank.private, // slot 5
  PieceRank.flag,
];

// ── Slot state ────────────────────────────────────────────────────────────────
enum _SlotState { available, placed, held }

class _Slot {
  final PieceRank rank;
  final _SlotState state;
  final Piece? piece; // non-null when available or held

  const _Slot({required this.rank, required this.state, this.piece});
}

// ── Main Widget ───────────────────────────────────────────────────────────────

class PieceTrayWidget extends StatelessWidget {
  const PieceTrayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      final slots = _buildSlots(provider);

      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 72,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 0.68,
          ),
          itemCount: slots.length,
          itemBuilder: (ctx, i) {
            final slot = slots[i];
            return _TraySlot(
              slot: slot,
              onTap: slot.state == _SlotState.available ||
                      slot.state == _SlotState.held
                  ? () => provider.selectPieceFromTray(slot.piece!)
                  : null,
            );
          },
        ),
      );
    });
  }

  /// Build 21 slot descriptors from the current provider state.
  List<_Slot> _buildSlots(GameProvider provider) {
    // Count pieces in tray by rank
    final trayByRank = <PieceRank, List<Piece>>{};
    for (final p in provider.unplacedPieces) {
      trayByRank.putIfAbsent(p.rank, () => []).add(p);
    }

    // Count pieces placed on board by rank
    final boardByRank = <PieceRank, int>{};
    for (final p in provider.localSetupBoard.values) {
      boardByRank[p.rank] = (boardByRank[p.rank] ?? 0) + 1;
    }

    final heldPiece = provider.selectedTrayPiece;

    // Per-rank cursor so we assign tray pieces to slots in order
    final trayUsed = <PieceRank, int>{};
    final boardUsed = <PieceRank, int>{};

    return _kTrayOrder.map((rank) {
      final ti = trayUsed[rank] ?? 0;
      final bi = boardUsed[rank] ?? 0;
      final inTray = trayByRank[rank] ?? [];
      final onBoard = boardByRank[rank] ?? 0;

      _Slot slot;

      if (bi < onBoard) {
        // This slot corresponds to a placed piece
        boardUsed[rank] = bi + 1;
        slot = _Slot(rank: rank, state: _SlotState.placed);
      } else if (ti < inTray.length) {
        // This slot is in the tray
        final piece = inTray[ti];
        trayUsed[rank] = ti + 1;
        final isHeld = heldPiece != null && identical(heldPiece, piece);
        slot = _Slot(
          rank: rank,
          state: isHeld ? _SlotState.held : _SlotState.available,
          piece: piece,
        );
      } else {
        // Shouldn't happen, but treat as placed
        slot = _Slot(rank: rank, state: _SlotState.placed);
      }

      return slot;
    }).toList();
  }
}

// ── Single Tray Slot ──────────────────────────────────────────────────────────

class _TraySlot extends StatelessWidget {
  final _Slot slot;
  final VoidCallback? onTap;

  const _TraySlot({required this.slot, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final rankColor = AppTheme.pieceRankColor(slot.rank.name);
    final isPlaced = slot.state == _SlotState.placed;
    final isHeld = slot.state == _SlotState.held;
    final isFlag = slot.rank == PieceRank.flag;

    Color bg;
    Color border;
    double borderWidth = 1;
    double opacity = isPlaced ? 0.28 : 1.0;

    if (isHeld) {
      bg = rankColor.withOpacity(0.22);
      border = rankColor;
      borderWidth = 2;
    } else if (isPlaced) {
      bg = AppTheme.background;
      border = AppTheme.border.withOpacity(0.25);
    } else if (isFlag) {
      bg = AppTheme.phGold.withOpacity(0.08);
      border = AppTheme.phGold.withOpacity(0.5);
    } else {
      bg = AppTheme.surfaceLight;
      border = AppTheme.border;
    }

    Widget card = Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: borderWidth),
          boxShadow: isHeld
              ? [
                  BoxShadow(
                      color: rankColor.withOpacity(0.45),
                      blurRadius: 10,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                child: PieceIcon(
                  rank: slot.rank,
                  color: isPlaced ? rankColor.withOpacity(0.3) : rankColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 2),
              child: Text(
                _shortLabel(slot.rank),
                style: TextStyle(
                  color: isPlaced ? rankColor.withOpacity(0.25) : rankColor,
                  fontSize: 6.8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 4),
              child: Text(
                _fullName(slot.rank),
                style: TextStyle(
                  color: isPlaced
                      ? AppTheme.textMuted.withOpacity(0.25)
                      : AppTheme.textSecondary.withOpacity(0.7),
                  fontSize: 5.8,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Non-interactive (placed)
    if (onTap == null) return card;

    // Interactive: tap + drag
    return GestureDetector(
      onTap: onTap,
      child: Draggable<Piece>(
        data: slot.piece,
        onDragStarted: onTap,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 54,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: rankColor, width: 2),
              boxShadow: [
                BoxShadow(color: rankColor.withOpacity(0.5), blurRadius: 16)
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: PieceIcon(rank: slot.rank, color: rankColor),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.2, child: card),
        child: card,
      ),
    );
  }

  static String _shortLabel(PieceRank rank) {
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

  static String _fullName(PieceRank rank) {
    switch (rank) {
      case PieceRank.fiveStar:
        return '5-Star General';
      case PieceRank.fourStar:
        return '4-Star General';
      case PieceRank.threeStar:
        return '3-Star General';
      case PieceRank.twoStar:
        return '2-Star General';
      case PieceRank.oneStar:
        return '1-Star General';
      case PieceRank.colonel:
        return 'Colonel';
      case PieceRank.ltColonel:
        return 'Lt. Colonel';
      case PieceRank.major:
        return 'Major';
      case PieceRank.captain:
        return 'Captain';
      case PieceRank.firstLt:
        return '1st Lieutenant';
      case PieceRank.secondLt:
        return '2nd Lieutenant';
      case PieceRank.sergeant:
        return 'Sergeant';
      case PieceRank.spy:
        return 'Spy';
      case PieceRank.private:
        return 'Private';
      case PieceRank.flag:
        return 'Flag';
    }
  }
}

// ── Vector Piece Icon (CustomPainter — no images) ─────────────────────────────

class PieceIcon extends StatelessWidget {
  final PieceRank rank;
  final Color color;
  const PieceIcon({required this.rank, required this.color, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _PieceIconPainter(rank: rank, color: color),
        child: const SizedBox.expand(),
      );
}

class _PieceIconPainter extends CustomPainter {
  final PieceRank rank;
  final Color color;
  _PieceIconPainter({required this.rank, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (rank) {
      case PieceRank.fiveStar:
        _stars(canvas, size, 5, fill);
        break;
      case PieceRank.fourStar:
        _stars(canvas, size, 4, fill);
        break;
      case PieceRank.threeStar:
        _stars(canvas, size, 3, fill);
        break;
      case PieceRank.twoStar:
        _stars(canvas, size, 2, fill);
        break;
      case PieceRank.oneStar:
        _stars(canvas, size, 1, fill);
        break;
      case PieceRank.colonel:
        _suns(canvas, size, 3, fill, stroke);
        break;
      case PieceRank.ltColonel:
        _suns(canvas, size, 2, fill, stroke);
        break;
      case PieceRank.major:
        _suns(canvas, size, 1, fill, stroke);
        break;
      case PieceRank.captain:
        _triangles(canvas, size, 3, fill);
        break;
      case PieceRank.firstLt:
        _triangles(canvas, size, 2, fill);
        break;
      case PieceRank.secondLt:
        _triangles(canvas, size, 1, fill);
        break;
      case PieceRank.sergeant:
        _chevrons(canvas, size, 2, stroke);
        break;
      case PieceRank.private:
        _chevrons(canvas, size, 1, stroke);
        break;
      case PieceRank.spy:
        _eyeglasses(canvas, size, stroke);
        break;
      case PieceRank.flag:
        _flag(canvas, size, fill, stroke);
        break;
    }
  }

  // ── Stars (Generals) ──────────────────────────────────────────────────────
  void _stars(Canvas canvas, Size sz, int n, Paint p) {
    final r = sz.width * 0.15;
    for (final pos in _starPositions(sz, n)) {
      _drawStar(canvas, pos, r, p);
    }
  }

  List<Offset> _starPositions(Size sz, int n) {
    final cx = sz.width / 2, cy = sz.height / 2;
    final sp = sz.width * 0.27;
    switch (n) {
      case 1:
        return [Offset(cx, cy)];
      case 2:
        return [Offset(cx - sp * .5, cy), Offset(cx + sp * .5, cy)];
      case 3:
        return [
          Offset(cx - sp, cy + sp * .25),
          Offset(cx, cy - sp * .35),
          Offset(cx + sp, cy + sp * .25),
        ];
      case 4:
        return [
          Offset(cx - sp * .55, cy - sp * .3),
          Offset(cx + sp * .55, cy - sp * .3),
          Offset(cx - sp * .55, cy + sp * .45),
          Offset(cx + sp * .55, cy + sp * .45),
        ];
      default:
        return [
          // 5
          Offset(cx - sp, cy + sp * .35),
          Offset(cx - sp * .38, cy - sp * .28),
          Offset(cx, cy + sp * .55),
          Offset(cx + sp * .38, cy - sp * .28),
          Offset(cx + sp, cy + sp * .35),
        ];
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final o = Offset(c.dx + r * cos((i * 72 - 90) * pi / 180),
          c.dy + r * sin((i * 72 - 90) * pi / 180));
      final inn = Offset(c.dx + r * .38 * cos(((i * 72 + 36) - 90) * pi / 180),
          c.dy + r * .38 * sin(((i * 72 + 36) - 90) * pi / 180));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      path.lineTo(inn.dx, inn.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  // ── Philippine sun badge (Colonel ranks) ─────────────────────────────────
  void _suns(Canvas canvas, Size sz, int n, Paint fill, Paint stroke) {
    final r = sz.width * 0.14;
    final sp = sz.width * 0.3;
    final cx = sz.width / 2, cy = sz.height / 2;
    List<Offset> positions;
    switch (n) {
      case 1:
        positions = [Offset(cx, cy)];
        break;
      case 2:
        positions = [Offset(cx - sp * .5, cy), Offset(cx + sp * .5, cy)];
        break;
      default:
        positions = [
          Offset(cx - sp, cy + sp * .2),
          Offset(cx, cy - sp * .3),
          Offset(cx + sp, cy + sp * .2),
        ];
    }
    for (final pos in positions) {
      canvas.drawCircle(pos, r, fill);
      for (int i = 0; i < 8; i++) {
        final a = i * 45 * pi / 180;
        canvas.drawLine(
          Offset(pos.dx + r * 1.25 * cos(a), pos.dy + r * 1.25 * sin(a)),
          Offset(pos.dx + r * 1.85 * cos(a), pos.dy + r * 1.85 * sin(a)),
          stroke..strokeWidth = r * 0.38,
        );
      }
    }
  }

  // ── Upward triangles (Captain ranks) ─────────────────────────────────────
  void _triangles(Canvas canvas, Size sz, int n, Paint p) {
    final th = sz.height * 0.33;
    final tw = sz.width * 0.26;
    final total = n * tw + (n - 1) * tw * 0.35;
    double x = (sz.width - total) / 2;
    final by = sz.height * 0.70;
    for (int i = 0; i < n; i++) {
      final path = Path()
        ..moveTo(x + tw / 2, by - th)
        ..lineTo(x, by)
        ..lineTo(x + tw, by)
        ..close();
      canvas.drawPath(path, p);
      x += tw * 1.35;
    }
  }

  // ── Chevrons (Sergeant / Private) ────────────────────────────────────────
  void _chevrons(Canvas canvas, Size sz, int n, Paint st) {
    st.strokeWidth = sz.width * 0.09;
    final w = sz.width * 0.62;
    final h = sz.height * 0.20;
    final gap = h * 1.7;
    final startY = sz.height / 2 - (n - 1) * gap / 2;
    for (int i = 0; i < n; i++) {
      final cy = startY + i * gap;
      final path = Path()
        ..moveTo((sz.width - w) / 2, cy + h)
        ..lineTo(sz.width / 2, cy)
        ..lineTo((sz.width + w) / 2, cy + h);
      canvas.drawPath(path, st);
    }
  }

  // ── Eyeglasses (Spy) ─────────────────────────────────────────────────────
  void _eyeglasses(Canvas canvas, Size sz, Paint st) {
    st.strokeWidth = sz.width * 0.08;
    final cy = sz.height * 0.50;
    final r = sz.width * 0.18;
    final gap = sz.width * 0.05;
    final lc = Offset(sz.width / 2 - r - gap / 2, cy);
    final rc = Offset(sz.width / 2 + r + gap / 2, cy);
    canvas.drawCircle(lc, r, st);
    canvas.drawCircle(rc, r, st);
    // Bridge
    canvas.drawLine(Offset(lc.dx + r, cy), Offset(rc.dx - r, cy), st);
    // Temple arms
    st.strokeWidth = sz.width * 0.065;
    canvas.drawLine(
        Offset(lc.dx - r, cy), Offset(lc.dx - r * 1.6, cy - r * 0.5), st);
    canvas.drawLine(
        Offset(rc.dx + r, cy), Offset(rc.dx + r * 1.6, cy - r * 0.5), st);
    // Lenses highlight dot
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lc, r * 0.28, dot);
    canvas.drawCircle(rc, r * 0.28, dot);
  }

  // ── Waving flag ──────────────────────────────────────────────────────────
  void _flag(Canvas canvas, Size sz, Paint fill, Paint st) {
    st.strokeWidth = sz.width * 0.07;
    final px = sz.width * 0.25;
    // Pole
    canvas.drawLine(
        Offset(px, sz.height * 0.12), Offset(px, sz.height * 0.88), st);
    // Waving flag body
    final path = Path()
      ..moveTo(px, sz.height * 0.15)
      ..cubicTo(
        sz.width * 0.68,
        sz.height * 0.12,
        sz.width * 0.92,
        sz.height * 0.28,
        sz.width * 0.78,
        sz.height * 0.44,
      )
      ..cubicTo(
        sz.width * 0.92,
        sz.height * 0.60,
        sz.width * 0.68,
        sz.height * 0.68,
        px,
        sz.height * 0.62,
      )
      ..close();
    canvas.drawPath(path, fill);
    // Small white star on flag
    _drawStar(
      canvas,
      Offset(sz.width * 0.60, sz.height * 0.39),
      sz.width * 0.10,
      Paint()
        ..color = AppTheme.background
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PieceIconPainter old) =>
      old.rank != rank || old.color != color;
}
