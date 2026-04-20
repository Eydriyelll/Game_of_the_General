// lib/utils/piece_assets.dart

import '../models/piece.dart';

class PieceAssets {
  static String assetPath(PieceRank rank) {
    switch (rank) {
      case PieceRank.fiveStar:   return 'assets/pieces/gen5.png';
      case PieceRank.fourStar:   return 'assets/pieces/gen4.png';
      case PieceRank.threeStar:  return 'assets/pieces/gen3.png';
      case PieceRank.twoStar:    return 'assets/pieces/gen2.png';
      case PieceRank.oneStar:    return 'assets/pieces/gen1.png';
      case PieceRank.colonel:    return 'assets/pieces/colonel.png';
      case PieceRank.ltColonel:  return 'assets/pieces/ltcolonel.png';
      case PieceRank.major:      return 'assets/pieces/major.png';
      case PieceRank.captain:    return 'assets/pieces/captain.png';
      case PieceRank.firstLt:    return 'assets/pieces/firstlt.png';
      case PieceRank.secondLt:   return 'assets/pieces/secondlt.png';
      case PieceRank.sergeant:   return 'assets/pieces/sergeant.png';
      case PieceRank.spy:        return 'assets/pieces/spy.png';
      case PieceRank.private:    return 'assets/pieces/private.png';
      case PieceRank.flag:       return 'assets/pieces/flag.png';
    }
  }
}
