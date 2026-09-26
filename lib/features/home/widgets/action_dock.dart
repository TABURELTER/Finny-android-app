import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/finny_tokens.dart';
import '../../../data/models/game_state.dart';

class ActionDockWidget extends StatelessWidget {
  final GameState state;
  final VoidCallback onWorkTap;
  final VoidCallback onShopTap;
  final VoidCallback onPlanTap;
  final VoidCallback onGoalTap;
  final VoidCallback onFinishDayTap;

  const ActionDockWidget({
    super.key,
    required this.state,
    required this.onWorkTap,
    required this.onShopTap,
    required this.onPlanTap,
    required this.onGoalTap,
    required this.onFinishDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 4 кнопки действий — чистый iOS-style dock
        Row(
          children: [
            _DockAction(
              emoji: '🌾',
              label: 'Работа',
              tag: state.workCompletedToday ? '✓' : '+10',
              tagColor: state.workCompletedToday
                  ? FinnyColors.textTertiary
                  : FinnyColors.success,
              onTap: onWorkTap,
            ),
            const Gap(10),
            _DockAction(
              emoji: '🏪',
              label: 'Лавка',
              tag: 'Купить',
              tagColor: FinnyColors.coin,
              onTap: onShopTap,
            ),
            const Gap(10),
            _DockAction(
              emoji: '📋',
              label: 'План',
              tag: state.plannedBudget?.isConfirmed == true ? '✓' : '•••',
              tagColor: state.plannedBudget?.isConfirmed == true
                  ? FinnyColors.success
                  : FinnyColors.textTertiary,
              onTap: onPlanTap,
            ),
            const Gap(10),
            _DockAction(
              emoji: '🎯',
              label: 'Мечта',
              tag: '${(state.goal.progress * 100).toInt()}%',
              tagColor: FinnyColors.accent,
              onTap: onGoalTap,
            ),
          ],
        ),
        const Gap(12),

        // CTA — Завершить день
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onFinishDayTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: FinnyColors.primary,
              foregroundColor: FinnyColors.textInverse,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: FinnyRadius.buttonRadius,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 16)),
                const Gap(8),
                Text(
                  'Завершить день',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ).animate().shimmer(
          duration: 2000.ms,
          delay: 1000.ms,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

// ── Кнопка дока ──

class _DockAction extends StatelessWidget {
  final String emoji;
  final String label;
  final String tag;
  final Color tagColor;
  final VoidCallback onTap;

  const _DockAction({
    required this.emoji,
    required this.label,
    required this.tag,
    required this.tagColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: FinnyColors.surface,
            borderRadius: BorderRadius.circular(FinnyRadius.md),
            border: Border.all(color: FinnyColors.border, width: 1),
            boxShadow: FinnyShadows.sm,
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const Gap(4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FinnyColors.textPrimary,
                ),
              ),
              const Gap(2),
              Text(
                tag,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: tagColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
