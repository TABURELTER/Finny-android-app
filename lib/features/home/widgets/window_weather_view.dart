import 'package:flutter/material.dart';

import '../../../data/models/game_state.dart';

/// Layer 1: Weather scene viewed through Finny's room window.
/// Rendered behind the room interior's transparent window cutout.
class WindowWeatherView extends StatelessWidget {
  final ForecastInfo forecast;
  final bool motion;

  const WindowWeatherView({
    super.key,
    required this.forecast,
    this.motion = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = forecast.title.toLowerCase();
    final isRain = title.contains('дожд') || title.contains('ливень');
    final isCloud = title.contains('туч') || title.contains('пасмур');
    final isWind = title.contains('ветер');
    final isFestival = title.contains('празд') || title.contains('ярмарк');

    final skyGradient = isRain
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF567285), Color(0xFF869FA9), Color(0xFFC2D2D7)],
          )
        : isCloud
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF759CB0), Color(0xFFB5CAD4), Color(0xFFDEE5E5)],
          )
        : isWind
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF64CBE5), Color(0xFFADE3EE), Color(0xFFFFF1D6)],
          )
        : isFestival
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B4E7A), Color(0xFFD6777C), Color(0xFFFBD082)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5ABBE6), Color(0xFFA5E6F7), Color(0xFFFFF2D6)],
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: skyGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Celestial body: Sun or Festival Moon
            if (!isRain && !isCloud) ...[
              Positioned(
                top: isFestival ? 14 : 16,
                right: 4,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isFestival
                          ? [const Color(0xFFFFF1B8), const Color(0xFFF3BF65)]
                          : [
                              const Color(0xFFFFF6D0).withValues(alpha: 0.9),
                              const Color(0xFFFFD54F),
                              const Color(0xFFFFB300),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isFestival
                                ? const Color(0xFFF4A261)
                                : const Color(0xFFFFD54F))
                            .withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Birds in the distance
            if (!isRain && !isCloud) ...[
              const Positioned(
                top: 8,
                left: 12,
                child: CustomPaint(
                  size: Size(16, 8),
                  painter: _BirdsPainter(),
                ),
              ),
            ],

            // Clouds
            if (isCloud || isRain) ...[
              Positioned(
                top: 18,
                left: -6,
                right: -6,
                child: CustomPaint(
                  size: const Size(60, 26),
                  painter: _CloudPainter(
                    color: isRain
                        ? const Color(0xFF647B8C)
                        : const Color(0xFFC7D7DC),
                  ),
                ),
              ),
            ] else if (!isFestival) ...[
              const Positioned(
                top: 26,
                left: 2,
                child: CustomPaint(
                  size: Size(36, 14),
                  painter: _CloudPainter(
                    color: Color(0xCCFFFFFF),
                  ),
                ),
              ),
            ],

            // Rain streaks
            if (isRain) ...[
              const Positioned.fill(
                child: CustomPaint(
                  painter: _RainPainter(),
                ),
              ),
            ],

            // Wind swirls
            if (isWind) ...[
              const Positioned.fill(
                child: CustomPaint(
                  painter: _WindPainter(),
                ),
              ),
            ],

            // Festival garland flags
            if (isFestival) ...[
              const Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(50, 16),
                  painter: _FestivalBuntingPainter(),
                ),
              ),
            ],

            // Rolling Hills at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 28,
              child: CustomPaint(
                painter: _HillsPainter(isRain: isRain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  final bool isRain;
  const _HillsPainter({required this.isRain});

  @override
  void paint(Canvas canvas, Size size) {
    final backHill = Paint()
      ..color = isRain ? const Color(0xFF568477) : const Color(0xFF6FBDA6)
      ..style = PaintingStyle.fill;
    final foreHill = Paint()
      ..color = isRain ? const Color(0xFF3E6F62) : const Color(0xFF4B9A84)
      ..style = PaintingStyle.fill;

    // Back Hill
    final pathBack = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.1,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathBack, backHill);

    // Front Hill
    final pathFore = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.35,
        size.width,
        size.height * 0.75,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(pathFore, foreHill);
  }

  @override
  bool shouldRepaint(covariant _HillsPainter oldDelegate) =>
      oldDelegate.isRain != isRain;
}

class _BirdsPainter extends CustomPainter {
  const _BirdsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4B6E80)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Bird 1
    final b1 = Path()
      ..moveTo(0, 3)
      ..quadraticBezierTo(2, 0, 4, 3)
      ..quadraticBezierTo(6, 0, 8, 3);
    canvas.drawPath(b1, paint);

    // Bird 2
    final b2 = Path()
      ..moveTo(8, 6)
      ..quadraticBezierTo(10, 4, 12, 6)
      ..quadraticBezierTo(14, 4, 16, 6);
    canvas.drawPath(b2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CloudPainter extends CustomPainter {
  final Color color;
  const _CloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.15, h * 0.8)
      ..quadraticBezierTo(0, h * 0.8, 0, h * 0.55)
      ..quadraticBezierTo(0, h * 0.25, w * 0.25, h * 0.25)
      ..quadraticBezierTo(w * 0.4, 0, w * 0.65, h * 0.15)
      ..quadraticBezierTo(w * 0.9, h * 0.15, w * 0.95, h * 0.45)
      ..quadraticBezierTo(w, h * 0.8, w * 0.8, h * 0.8)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RainPainter extends CustomPainter {
  const _RainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xDDE2F3F6)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final drops = [
      const Offset(8, 22),
      const Offset(22, 16),
      const Offset(36, 26),
      const Offset(14, 40),
      const Offset(28, 48),
      const Offset(42, 42),
      const Offset(18, 64),
      const Offset(34, 68),
    ];

    for (final d in drops) {
      canvas.drawLine(d, Offset(d.dx - 2.5, d.dy + 7), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WindPainter extends CustomPainter {
  const _WindPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(4, 28)
      ..quadraticBezierTo(20, 22, 44, 27);
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(10, 42)
      ..quadraticBezierTo(26, 36, 46, 40);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FestivalBuntingPainter extends CustomPainter {
  const _FestivalBuntingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF664466)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rope = Path()
      ..moveTo(0, 4)
      ..quadraticBezierTo(size.width * 0.5, 14, size.width, 4);
    canvas.drawPath(rope, linePaint);

    final colors = [
      const Color(0xFFE76F51),
      const Color(0xFFF4A261),
      const Color(0xFFE9C46A),
      const Color(0xFF2A9D8F),
      const Color(0xFF457B9D),
    ];

    final step = size.width / 5;
    for (var i = 0; i < 5; i++) {
      final cx = step * (i + 0.5);
      final cy = 4.0 + (cx - size.width * 0.5).abs() * -0.15 + 4.5;
      final flagPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      final flag = Path()
        ..moveTo(cx - 3, cy)
        ..lineTo(cx + 3, cy)
        ..lineTo(cx, cy + 6)
        ..close();
      canvas.drawPath(flag, flagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
