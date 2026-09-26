import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/finny_tokens.dart';
import '../../../core/theme/finny_widgets.dart';
import '../../../data/models/game_state.dart';
import '../../../game/content/goals.dart';

class GoalCardWidget extends StatelessWidget {
  final GameState state;
  final VoidCallback onTap;

  const GoalCardWidget({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final goalDef = kAvailableGoals.firstWhere(
      (g) => g.id == state.goal.goalId,
      orElse: () => kAvailableGoals.first,
    );

    final progress = state.goal.progress;
    final isComplete = state.goal.isCompleted;

    return FinnyCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: isComplete ? FinnyColors.coin : null,
      child: Row(
        children: [
          // Иконка цели
          FinnyIconBadge(
            emoji: goalDef.icon,
            backgroundColor: FinnyColors.accentLight,
            size: 38,
          ),
          const Gap(12),

          // Название + прогресс
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      goalDef.name,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FinnyColors.textPrimary,
                      ),
                    ),
                    const Gap(8),
                    FinnyBadge(
                      text: isComplete
                          ? 'Готово! ✨'
                          : '${state.goal.savedAmount}/${state.goal.targetAmount}',
                      color: isComplete
                          ? FinnyColors.successLight
                          : FinnyColors.accentLight,
                      textColor: isComplete
                          ? FinnyColors.success
                          : FinnyColors.accent,
                    ),
                  ],
                ),
                const Gap(8),
                FinnyProgressBar(
                  progress: progress,
                  height: 6,
                  startColor: FinnyColors.accent,
                  endColor: FinnyColors.primary,
                ),
              ],
            ),
          ),
          const Gap(8),

          // Стрелка
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: FinnyColors.textTertiary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }
}
