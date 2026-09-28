import 'package:flutter/material.dart';

Future<Color?> pickFinnyColor(
  BuildContext context, {
  required String title,
  required Color initial,
  Color? defaultColor,
}) => showDialog<Color>(
  context: context,
  builder: (_) => _ColorPickerDialog(
    title: title,
    initial: initial,
    defaultColor: defaultColor,
  ),
);

class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color initial;
  final Color? defaultColor;
  const _ColorPickerDialog({
    required this.title,
    required this.initial,
    this.defaultColor,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor selected = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, selected.hue, 1, 1).toColor();
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.4,
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  onPanDown: (details) =>
                      _selectPoint(details.localPosition, box.biggest),
                  onPanUpdate: (details) =>
                      _selectPoint(details.localPosition, box.biggest),
                  child: CustomPaint(
                    painter: _ColorSquare(
                      hueColor,
                      selected.saturation,
                      selected.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Оттенок',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ],
                ),
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: hueColor,
                ),
                child: Slider(
                  value: selected.hue,
                  min: 0,
                  max: 360,
                  label: 'Оттенок ${selected.hue.round()}',
                  onChanged: (hue) =>
                      setState(() => selected = selected.withHue(hue)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Выбранный цвет',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected.toColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                if (widget.defaultColor != null)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, widget.defaultColor),
                    child: const Text('Сбросить'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, selected.toColor()),
                child: const Text('Выбрать'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPoint(Offset point, Size size) {
    setState(() {
      selected = selected
          .withSaturation((point.dx / size.width).clamp(0, 1))
          .withValue((1 - point.dy / size.height).clamp(0, 1));
    });
  }
}

class _ColorSquare extends CustomPainter {
  final Color hue;
  final double saturation, value;
  const _ColorSquare(this.hue, this.saturation, this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final area = Offset.zero & size;
    canvas.drawRect(area, Paint()..color = hue);
    canvas.drawRect(
      area,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(area),
    );
    canvas.drawRect(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(area),
    );
    final marker = Offset(saturation * size.width, (1 - value) * size.height);
    canvas.drawCircle(marker, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      marker,
      9,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ColorSquare old) =>
      old.hue != hue || old.saturation != saturation || old.value != value;
}
