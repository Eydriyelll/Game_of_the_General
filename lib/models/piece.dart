// lib/models/piece.dart

enum PieceRank {
  fiveStar,   // 5-Star General (highest)
  fourStar,   // 4-Star General
  threeStar,  // 3-Star General
  twoStar,    // 2-Star General
  oneStar,    // 1-Star General
  colonel,
  ltColonel,
  major,
  captain,
  firstLt,
  secondLt,
  sergeant,
  spy,        // Eliminates all officers (5★ down to Sgt)
  private,    // Eliminates Spy
  flag,       // The objective piece
}

enum PieceOwner { player1, player2 }

class Piece {
  final PieceRank rank;
  final PieceOwner owner;
  bool isEliminated;

  Piece({
    required this.rank,
    required this.owner,
    this.isEliminated = false,
  });

  /// Display label shown on the piece tile
  String get label {
    switch (rank) {
      case PieceRank.fiveStar:   return '5★ Gen';
      case PieceRank.fourStar:   return '4★ Gen';
      case PieceRank.threeStar:  return '3★ Gen';
      case PieceRank.twoStar:    return '2★ Gen';
      case PieceRank.oneStar:    return '1★ Gen';
      case PieceRank.colonel:    return 'COL';
      case PieceRank.ltColonel:  return 'LTC';
      case PieceRank.major:      return 'MAJ';
      case PieceRank.captain:    return 'CPT';
      case PieceRank.firstLt:    return '1LT';
      case PieceRank.secondLt:   return '2LT';
      case PieceRank.sergeant:   return 'SGT';
      case PieceRank.spy:        return 'SPY';
      case PieceRank.private:    return 'PVT';
      case PieceRank.flag:       return 'FLAG';
    }
  }

  /// Full name for display
  String get fullName {
    switch (rank) {
      case PieceRank.fiveStar:   return '5-Star General';
      case PieceRank.fourStar:   return '4-Star General';
      case PieceRank.threeStar:  return '3-Star General';
      case PieceRank.twoStar:    return '2-Star General';
      case PieceRank.oneStar:    return '1-Star General';
      case PieceRank.colonel:    return 'Colonel';
      case PieceRank.ltColonel:  return 'Lt. Colonel';
      case PieceRank.major:      return 'Major';
      case PieceRank.captain:    return 'Captain';
      case PieceRank.firstLt:    return '1st Lieutenant';
      case PieceRank.secondLt:   return '2nd Lieutenant';
      case PieceRank.sergeant:   return 'Sergeant';
      case PieceRank.spy:        return 'Spy';
      case PieceRank.private:    return 'Private';
      case PieceRank.flag:       return 'Flag';
    }
  }

  /// Numeric rank value — higher = stronger officer
  /// Used for standard officer vs officer comparisons
  int get rankValue {
    switch (rank) {
      case PieceRank.fiveStar:   return 14;
      case PieceRank.fourStar:   return 13;
      case PieceRank.threeStar:  return 12;
      case PieceRank.twoStar:    return 11;
      case PieceRank.oneStar:    return 10;
      case PieceRank.colonel:    return 9;
      case PieceRank.ltColonel:  return 8;
      case PieceRank.major:      return 7;
      case PieceRank.captain:    return 6;
      case PieceRank.firstLt:    return 5;
      case PieceRank.secondLt:   return 4;
      case PieceRank.sergeant:   return 3;
      case PieceRank.spy:        return 2;
      case PieceRank.private:    return 1;
      case PieceRank.flag:       return 0;
    }
  }

  bool get isOfficer =>
      rankValue >= 3; // Sergeant and above are "officers" for SPY purposes

  /// Serialize to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'rank': rank.name,
      'owner': owner.name,
      'isEliminated': isEliminated,
    };
  }

  /// Deserialize from Firebase map
  factory Piece.fromMap(Map<dynamic, dynamic> map) {
    return Piece(
      rank: PieceRank.values.firstWhere((r) => r.name == map['rank']),
      owner: PieceOwner.values.firstWhere((o) => o.name == map['owner']),
      isEliminated: map['isEliminated'] ?? false,
    );
  }

  Piece copyWith({bool? isEliminated}) {
    return Piece(
      rank: rank,
      owner: owner,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }
}

/// Result of a challenge between two pieces
enum ChallengeResult { attackerWins, defenderWins, bothEliminated }

/// Automated arbiter: resolves challenge between attacker and defender
/// Returns who wins (or both eliminated)
ChallengeResult resolveChallenge(Piece attacker, Piece defender) {
  final a = attacker.rank;
  final d = defender.rank;

  // Equal ranks → both eliminated
  if (a == d) return ChallengeResult.bothEliminated;

  // FLAG special rules:
  // Flag actively moving into opponent flag = attacker wins
  if (a == PieceRank.flag && d == PieceRank.flag) {
    return ChallengeResult.attackerWins; // flag that moves wins
  }
  // Any piece can eliminate the flag
  if (d == PieceRank.flag) return ChallengeResult.attackerWins;
  if (a == PieceRank.flag) return ChallengeResult.defenderWins;

  // PRIVATE eliminates SPY
  if (a == PieceRank.private && d == PieceRank.spy) return ChallengeResult.attackerWins;
  if (d == PieceRank.private && a == PieceRank.spy) return ChallengeResult.defenderWins;

  // SPY eliminates all officers (Sergeant and above)
  if (a == PieceRank.spy && defender.isOfficer) return ChallengeResult.attackerWins;
  if (d == PieceRank.spy && attacker.isOfficer) return ChallengeResult.defenderWins;

  // PRIVATE loses to everyone except spy (handled above)
  if (a == PieceRank.private) return ChallengeResult.defenderWins;
  if (d == PieceRank.private) return ChallengeResult.attackerWins;

  // Standard rank comparison for officers
  if (attacker.rankValue > defender.rankValue) return ChallengeResult.attackerWins;
  if (defender.rankValue > attacker.rankValue) return ChallengeResult.defenderWins;

  return ChallengeResult.bothEliminated;
}

/// Returns the standard set of 21 pieces for one player
List<Piece> createPieceSet(PieceOwner owner) {
  return [
    Piece(rank: PieceRank.fiveStar, owner: owner),
    Piece(rank: PieceRank.fourStar, owner: owner),
    Piece(rank: PieceRank.threeStar, owner: owner),
    Piece(rank: PieceRank.twoStar, owner: owner),
    Piece(rank: PieceRank.oneStar, owner: owner),
    Piece(rank: PieceRank.colonel, owner: owner),
    Piece(rank: PieceRank.ltColonel, owner: owner),
    Piece(rank: PieceRank.major, owner: owner),
    Piece(rank: PieceRank.captain, owner: owner),
    Piece(rank: PieceRank.firstLt, owner: owner),
    Piece(rank: PieceRank.secondLt, owner: owner),
    Piece(rank: PieceRank.sergeant, owner: owner),
    Piece(rank: PieceRank.spy, owner: owner),
    Piece(rank: PieceRank.spy, owner: owner),
    Piece(rank: PieceRank.private, owner: owner),
    Piece(rank: PieceRank.private, owner: owner),
    Piece(rank: PieceRank.private, owner: owner),
    Piece(rank: PieceRank.private, owner: owner),
    Piece(rank: PieceRank.private, owner: owner),
    Piece(rank: PieceRank.private, owner: owner),
    Piece(rank: PieceRank.flag, owner: owner),
  ];
}
