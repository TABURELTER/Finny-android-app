import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/finny_tokens.dart';
import '../../../data/models/game_state.dart';

class ForecastBannerWidget extends StatelessWidget {
  final ForecastInfo forecast;

  const ForecastBannerWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text(forecast.icon, style: const TextStyle(fontSize: 16)),
          const Gap(8),
          Expanded(
            child: Text(
              forecast.hint,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FinnyColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}
