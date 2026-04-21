// lib/widgets/move_history_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../utils/app_theme.dart';

class MoveHistoryPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      final history = provider.moveHistory.reversed.toList();

      return Container(
        color: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: AppTheme.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'MOVE HISTORY',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text('${history.length}',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Text('No moves yet',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final move = history[index];
                        final moveNumber = history.length - index;
                        final isP1 = move.playerRole == 'player1';
                        final color = isP1
                            ? AppTheme.player1Color
                            : AppTheme.player2Color;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: AppTheme.border.withOpacity(0.5)),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text('$moveNumber.',
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 10)),
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              Text(
                                '${move.from.key} → ${move.to.key}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              if (move.wasChallenge) ...[
                                const Spacer(),
                                Icon(Icons.bolt,
                                    color: AppTheme.challengeColor, size: 12),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}
