// lib/models/board_position.dart

class BoardPosition {
  final int row;    // 0-7  (0 = player1 back row, 7 = player2 back row)
  final int col;    // 0-8

  const BoardPosition(this.row, this.col);

  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 9;

  /// Returns adjacent positions (up, down, left, right — no diagonals)
  List<BoardPosition> get adjacents {
    return [
      BoardPosition(row - 1, col),
      BoardPosition(row + 1, col),
      BoardPosition(row, col - 1),
      BoardPosition(row, col + 1),
    ].where((p) => p.isValid).toList();
  }

  String get key => '${row}_$col';

  @override
  bool operator ==(Object other) =>
      other is BoardPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row, $col)';

  factory BoardPosition.fromKey(String key) {
    final parts = key.split('_');
    return BoardPosition(int.parse(parts[0]), int.parse(parts[1]));
  }
}
