import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/finny_tokens.dart';
import '../../../data/models/game_state.dart';

class TopBarWidget extends StatelessWidget {
  final GameState state;
  final VoidCallback onAdultTap;
  final VoidCallback onProgressTap;
  final VoidCallback onDemoTap;

  const TopBarWidget({
    super.key,
    required this.state,
    required this.onAdultTap,
    required this.onProgressTap,
    required this.onDemoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          // День — pill badge с мягким градиентом
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FinnyColors.primary.withValues(alpha: 0.12),
                  FinnyColors.primary.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: FinnyRadius.chipRadius,
            ),
            child: Text(
              'День ${state.day}/10',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: FinnyColors.primary,
              ),
            ),
          ),
          const Spacer(),

          // Баланс монет
          _CoinPill(
            emoji: '🪙',
            value: state.balance,
            color: FinnyColors.coin,
            bgColor: FinnyColors.coinLight,
          ),
          const Gap(8),

          // Копилка
          _CoinPill(
            emoji: '🏦',
            value: state.savings,
            color: FinnyColors.piggy,
            bgColor: FinnyColors.piggyLight,
          ),
          const Spacer(),

          // Навигационные иконки — минималистичные, без рамок
          _NavIcon(
            icon: Icons.auto_stories_outlined,
            tooltip: 'Дневник',
            onTap: onProgressTap,
          ),
          _NavIcon(
            icon: Icons.shield_outlined,
            tooltip: 'Родителям',
            onTap: onAdultTap,
          ),
          _NavIcon(
            icon: Icons.bolt_rounded,
            tooltip: 'Демо',
            onTap: onDemoTap,
            color: FinnyColors.warning,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ── Пилюля с монетами ──

class _CoinPill extends StatelessWidget {
  final String emoji;
  final int value;
  final Color color;
  final Color bgColor;

  const _CoinPill({
    required this.emoji,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: FinnyRadius.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const Gap(4),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: value, end: value),
            duration: FinnyDurations.normal,
            builder: (context, val, _) {
              return Text(
                '$val',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Иконка навигации ──

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 20,
              color: color ?? FinnyColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
