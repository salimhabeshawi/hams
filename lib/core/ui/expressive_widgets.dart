// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;
import 'package:flutter/material.dart';

class MorphingButton extends StatefulWidget {
  const MorphingButton({required this.onPressed, required this.child, super.key});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  State<MorphingButton> createState() => _MorphingButtonState();
}

class _MorphingButtonState extends State<MorphingButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(pressed ? 18 : 32),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            child: widget.child,
          ),
        ),
      );
}

class ColorBlockedCard extends StatelessWidget {
  const ColorBlockedCard({required this.child, required this.color, super.key});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
        color: color,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      );
}

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({required this.name, required this.seed, this.size = 64, super.key});
  final String name;
  final int seed;
  final double size;
  @override
  Widget build(BuildContext context) {
    final words = name.split(' ');
    final initials = words.map((word) => word.isEmpty ? '' : word[0]).take(2).join();
    final colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
    ];
    final shapeIndex = seed.abs() % 3;
    return Semantics(
      label: 'Avatar for $name',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: colors[seed.abs() % colors.length],
          shape: [
            const CircleBorder(),
            const StadiumBorder(),
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ][shapeIndex],
        ),
        child: Text(initials, style: TextStyle(fontSize: size * .32, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class WavyProgressIndicator extends StatelessWidget {
  const WavyProgressIndicator({this.value, super.key});
  final double? value;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 18,
        child: CustomPaint(painter: _WavePainter(Theme.of(context).colorScheme.primary, value)),
      );
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.color, this.value);
  final Color color;
  final double? value;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final width = size.width * (value ?? 1);
    for (var x = 0.0; x <= width; x += 2) {
      final y = size.height / 2 + math.sin(x / 12) * 4;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.value != value || oldDelegate.color != color;
}

class ConnectedChoice<T> extends StatelessWidget {
  const ConnectedChoice({required this.value, required this.groupValue, required this.label, required this.onChanged, super.key});
  final T value;
  final T groupValue;
  final String label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Semantics(
          button: true,
          selected: value == groupValue,
          label: label,
          child: FilledButton.tonal(
            onPressed: () => onChanged(value),
            style: FilledButton.styleFrom(
              backgroundColor: value == groupValue ? Theme.of(context).colorScheme.primaryContainer : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(label),
          ),
        ),
      );
}
