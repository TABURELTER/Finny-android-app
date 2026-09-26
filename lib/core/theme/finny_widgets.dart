/// Finny UI Components — Переиспользуемые виджеты дизайн-системы
///
/// Единый стиль для карточек, кнопок, бейджей, прогресс-баров,
/// bottom sheets, анимированных счётчиков.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'finny_tokens.dart';

// ─────────────────────────────────────────────
//  FinnyCard — Базовая карточка
// ─────────────────────────────────────────────

class FinnyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final double? borderRadius;

  const FinnyCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.shadow,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? FinnySpacing.cardPadding,
      decoration: BoxDecoration(
        color: color ?? FinnyColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? FinnyRadius.md),
        border: Border.all(color: borderColor ?? FinnyColors.border, width: 1),
        boxShadow: shadow ?? FinnyShadows.sm,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}

// ─────────────────────────────────────────────
//  FinnyGlassCard — Glassmorphism карточка
// ─────────────────────────────────────────────

class FinnyGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? tintColor;

  const FinnyGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? FinnySpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (tintColor ?? FinnyColors.accent).withValues(alpha: 0.08),
            (tintColor ?? FinnyColors.accent).withValues(alpha: 0.03),
          ],
        ),
        borderRadius: FinnyRadius.cardRadius,
        border: Border.all(
          color: (tintColor ?? FinnyColors.accent).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyBadge — Компактный бейдж
// ─────────────────────────────────────────────

class FinnyBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const FinnyBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? FinnyColors.primaryLight,
        borderRadius: FinnyRadius.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? FinnyColors.primary),
            const Gap(4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor ?? FinnyColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyIconBadge — Круглая иконка с фоном
// ─────────────────────────────────────────────

class FinnyIconBadge extends StatelessWidget {
  final String emoji;
  final Color? backgroundColor;
  final double size;

  const FinnyIconBadge({
    super.key,
    required this.emoji,
    this.backgroundColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? FinnyColors.surfaceMuted,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyButton — Кнопка с вариантами
// ─────────────────────────────────────────────

enum FinnyButtonVariant { primary, secondary, ghost, danger }

class FinnyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FinnyButtonVariant variant;
  final IconData? icon;
  final String? emoji;
  final bool isExpanded;
  final bool isLoading;

  const FinnyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FinnyButtonVariant.primary,
    this.icon,
    this.emoji,
    this.isExpanded = false,
    this.isLoading = false,
  });

  const FinnyButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.emoji,
    this.isExpanded = true,
    this.isLoading = false,
  }) : variant = FinnyButtonVariant.primary;

  const FinnyButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.emoji,
    this.isExpanded = false,
    this.isLoading = false,
  }) : variant = FinnyButtonVariant.secondary;

  const FinnyButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.emoji,
    this.isExpanded = false,
    this.isLoading = false,
  }) : variant = FinnyButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == FinnyButtonVariant.primary
                  ? FinnyColors.textInverse
                  : FinnyColors.primary,
            ),
          ),
          const Gap(8),
        ] else ...[
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 16)),
            const Gap(6),
          ],
          if (icon != null) ...[Icon(icon, size: 18), const Gap(6)],
        ],
        Text(label),
      ],
    );

    Widget button;
    switch (variant) {
      case FinnyButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case FinnyButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case FinnyButtonVariant.ghost:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case FinnyButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: FinnyColors.danger,
            foregroundColor: FinnyColors.textInverse,
          ),
          child: child,
        );
    }

    if (isExpanded) {
      return SizedBox(width: double.infinity, height: 52, child: button);
    }
    return button;
  }
}

// ─────────────────────────────────────────────
//  FinnyChip — Фильтр-чип с анимацией
// ─────────────────────────────────────────────

class FinnyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;

  const FinnyChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: FinnyDurations.fast,
        curve: FinnyCurves.defaultCurve,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FinnyColors.primary : FinnyColors.surface,
          borderRadius: FinnyRadius.chipRadius,
          border: Border.all(
            color: isSelected ? FinnyColors.primary : FinnyColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected ? FinnyShadows.sm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14)),
              const Gap(4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? FinnyColors.textInverse
                    : FinnyColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyProgressBar — Прогресс-бар с градиентом
// ─────────────────────────────────────────────

class FinnyProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double height;
  final Color? startColor;
  final Color? endColor;
  final Color? trackColor;

  const FinnyProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.startColor,
    this.endColor,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor ?? FinnyColors.surfaceMuted,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                startColor ?? FinnyColors.primary,
                endColor ?? FinnyColors.accent,
              ],
            ),
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyBottomSheet — Единый шаблон модальных окон
// ─────────────────────────────────────────────

class FinnyBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final double heightFactor;
  final List<Widget>? actions;

  const FinnyBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.heightFactor = 0.88,
    this.actions,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget child,
    double heightFactor = 0.88,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FinnyBottomSheet(
        title: title,
        subtitle: subtitle,
        heightFactor: heightFactor,
        actions: actions,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        color: FinnyColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FinnyRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const Gap(12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: FinnyColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FinnySpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: FinnyColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const Gap(2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: FinnyColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ...?actions,
              ],
            ),
          ),
          const Gap(16),
          const Divider(height: 1),

          // Body
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyAnimatedCounter — Анимация смены числа
// ─────────────────────────────────────────────

class FinnyAnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;

  const FinnyAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: FinnyDurations.normal,
      curve: FinnyCurves.defaultCurve,
      builder: (context, val, _) {
        return Text(
          '${prefix ?? ''}$val${suffix ?? ''}',
          style:
              style ??
              TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: FinnyColors.textPrimary,
              ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyMetricRow — Строка метрики (лейбл + значение)
// ─────────────────────────────────────────────

class FinnyMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const FinnyMetricRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: FinnyColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? FinnyColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  FinnyDivider — Тонкий разделитель
// ─────────────────────────────────────────────

class FinnyDivider extends StatelessWidget {
  final double indent;
  const FinnyDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: FinnyColors.divider,
      height: 1,
      indent: indent,
      endIndent: indent,
    );
  }
}

// ─────────────────────────────────────────────
//  Animate extension — удобные пресеты анимаций
// ─────────────────────────────────────────────

extension FinnyAnimateX on Widget {
  /// Стандартное появление элемента
  Widget finnyEntrance({int delayMs = 0}) {
    return animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: FinnyDurations.entrance, curve: FinnyCurves.entrance)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: FinnyDurations.entrance,
          curve: FinnyCurves.entrance,
        );
  }

  /// Staggered появление для списков
  Widget finnyStagger(int index) {
    return finnyEntrance(delayMs: index * 80);
  }
}
