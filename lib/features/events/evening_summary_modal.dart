import 'package:flutter/material.dart';

import 'compact_evening_summary.dart';

/// Single entry point for the evening review shown after the day's decisions.
abstract final class EveningSummaryModal {
  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const CompactEveningSummary(),
  );
}
