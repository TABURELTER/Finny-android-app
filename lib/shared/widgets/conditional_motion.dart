import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension ConditionalMotion on Widget {
  Widget fadeInWhen(
    bool enabled, {
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) => enabled ? animate().fadeIn(duration: duration, delay: delay) : this;
}
