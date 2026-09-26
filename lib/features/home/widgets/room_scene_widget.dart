import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/finny_tokens.dart';
import '../../../data/models/event_models.dart';
import '../../../data/models/game_state.dart';
import '../../../shared/widgets/pet_avatar_widget.dart';

class RoomSceneWidget extends StatelessWidget {
  final GameState state;
  final VoidCallback onPetTap;
  final VoidCallback? onWardrobeTap;

  const RoomSceneWidget({
    super.key,
    required this.state,
    required this.onPetTap,
    this.onWardrobeTap,
  });

  @override
  Widget build(BuildContext context) {
    final inv = state.inventory;
    final hasRaincoat =
        inv.hasItem('raincoat') &&
        (state.forecast.title.toLowerCase().contains('ливень') ||
            state.forecast.title.toLowerCase().contains('дождь'));
    final hasBed = inv.hasItem('cozy_bed');
    final hasBall = inv.hasItem('toy_ball');
    final hasRobot = inv.hasItem('toy_robot');
    final hasLamp = inv.hasItem('warm_lamp');
    final hasKite = inv.hasItem('kite');
    final hasTools = inv.hasItem('repair_kit');
    final foodDays = inv.foodReserveDays;

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FinnyRadius.xl),
        border: Border.all(color: FinnyColors.border, width: 1),
        boxShadow: FinnyShadows.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FinnyRadius.xl - 1),
        child: LayoutBuilder(builder: (context, constraints) => Stack(
          alignment: Alignment.center,
          children: [
            // 1. Чистый градиентный фон — стена
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: hasLamp
                        ? [const Color(0xFFFFF9F0), const Color(0xFFFFF3E0)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                  ),
                ),
              ),
            ),

            // 2. Мягкий «пол» — горизонтальная полоска внизу
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: FinnyColors.surfaceMuted,
                  border: Border(
                    top: BorderSide(color: FinnyColors.border, width: 1),
                  ),
                ),
              ),
            ),

            // 3. Мягкий коврик
            Positioned(
              bottom: 12,
              child: Container(
                width: 200,
                height: 44,
                decoration: BoxDecoration(
                  color: FinnyColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: FinnyColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
            ),

            // 4. Окно — простой контейнер с погодой
            Positioned(
              top: 16,
              left: 20,
              child: _MinimalWindow(forecast: state.forecast),
            ),

            // 5. Мечта — маленький бейдж
            Positioned(
              top: 16,
              right: 20,
              child: _DreamIcon(goalId: state.goal.goalId),
            ),

            // 6. Предметы интерьера — чистые маленькие элементы
            if (hasBed)
              const Positioned(
                left: 18,
                bottom: 34,
                child: _RoomItem(emoji: '🛏️', label: 'Уют'),
              ),
            if (hasLamp)
              Positioned(
                right: 20,
                bottom: 60,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 20)),
                ),
              ),
            if (hasBall)
              const Positioned(
                left: 60,
                bottom: 16,
                child: Text('⚽', style: TextStyle(fontSize: 20)),
              ),
            if (hasRobot)
              const Positioned(
                right: 60,
                bottom: 16,
                child: Text('🤖', style: TextStyle(fontSize: 20)),
              ),
            if (hasKite)
              const Positioned(
                left: 20,
                bottom: 86,
                child: Text('🪁', style: TextStyle(fontSize: 20)),
              ),
            if (hasTools)
              const Positioned(
                right: 20,
                bottom: 86,
                child: Text('🧰', style: TextStyle(fontSize: 18)),
              ),

            // 7. Миска — компактный бейдж
            Positioned(
              right: 18,
              bottom: 14,
              child: _FoodIndicator(daysRemaining: foodDays),
            ),

            // 8. Финни — центр
            Positioned(
              bottom: 24,
              child: PetAvatarWidget(
                mood: state.finny.mood,
                size: ((constraints.maxHeight - 105).clamp(120.0, 310.0) / 1.125).clamp(100.0, constraints.maxWidth - 48),
                hasRaincoat: hasRaincoat,
                onTap: onPetTap,
              ),
            ),

            if (onWardrobeTap != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Гардероб',
                  onPressed: onWardrobeTap,
                  icon: const Icon(Icons.checkroom_rounded),
                ),
              ),
            // 9. Облачко мыслей
            Positioned(
              top: 8,
              child: _SpeechBubble(
                message: state.finny.moodReason,
                mood: state.finny.mood,
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.15),
            ),
          ],
        )),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.97, 0.97));
  }
}

// ── Минималистичное окно ──

class _MinimalWindow extends StatelessWidget {
  final ForecastInfo forecast;

  const _MinimalWindow({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final isRain =
        forecast.title.toLowerCase().contains('ливень') ||
        forecast.title.toLowerCase().contains('дождь');

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isRain ? const Color(0xFFE2E8F0) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(FinnyRadius.sm),
        border: Border.all(color: FinnyColors.border, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Оконный крест — тонкие линии
          Positioned(
            top: 0,
            bottom: 0,
            left: 23,
            child: Container(width: 1, color: FinnyColors.border),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 23,
            child: Container(height: 1, color: FinnyColors.border),
          ),
          Text(forecast.icon, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// ── Иконка мечты ──

class _DreamIcon extends StatelessWidget {
  final String goalId;

  const _DreamIcon({required this.goalId});

  @override
  Widget build(BuildContext context) {
    String goalIcon = '🚀';
    if (goalId == 'treehouse') goalIcon = '🏠';
    if (goalId == 'skateboard') goalIcon = '🛹';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: FinnyColors.surface,
        borderRadius: BorderRadius.circular(FinnyRadius.sm),
        border: Border.all(
          color: FinnyColors.accent.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: FinnyShadows.sm,
      ),
      child: Center(
        child: Text(goalIcon, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

// ── Предмет комнаты ──

class _RoomItem extends StatelessWidget {
  final String emoji;
  final String label;

  const _RoomItem({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FinnyColors.surface,
        borderRadius: BorderRadius.circular(FinnyRadius.xs),
        border: Border.all(color: FinnyColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const Gap(3),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: FinnyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Индикатор еды ──

class _FoodIndicator extends StatelessWidget {
  final int daysRemaining;

  const _FoodIndicator({required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final hasFood = daysRemaining > 0;
    final color = hasFood ? FinnyColors.success : FinnyColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasFood ? FinnyColors.successLight : FinnyColors.dangerLight,
        borderRadius: FinnyRadius.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hasFood ? '🍎' : '💔', style: const TextStyle(fontSize: 13)),
          const Gap(4),
          Text(
            hasFood ? '$daysRemaining дн.' : 'Голоден',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Облачко мыслей ──

class _SpeechBubble extends StatelessWidget {
  final String message;
  final FinnyMood mood;

  const _SpeechBubble({required this.message, required this.mood});

  @override
  Widget build(BuildContext context) {
    Color bg = FinnyColors.surface;
    Color border = FinnyColors.border;

    if (mood == FinnyMood.worried) {
      bg = FinnyColors.warningLight;
      border = FinnyColors.warning;
    } else if (mood == FinnyMood.happy) {
      bg = FinnyColors.successLight;
      border = FinnyColors.success;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FinnyRadius.sm),
        border: Border.all(color: border, width: 1),
        boxShadow: FinnyShadows.sm,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FinnyColors.textPrimary,
        ),
      ),
    );
  }
}
