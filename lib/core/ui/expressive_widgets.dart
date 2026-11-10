// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math' as math;

import 'package:flutter/material.dart';

class MorphingButton extends StatefulWidget {
  const MorphingButton({
    required this.onPressed,
    required this.child,
    super.key,
  });
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
  const AvatarBadge({
    required this.name,
    required this.seed,
    this.size = 64,
    super.key,
  });
  final String name;
  final int seed;
  final double size;
  @override
  Widget build(BuildContext context) {
    final words = name.split(' ');
    final initials = words
        .map((word) => word.isEmpty ? '' : word[0])
        .take(2)
        .join();
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
        child: Text(
          initials,
          style: TextStyle(fontSize: size * .32, fontWeight: FontWeight.w800),
        ),
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
    child: CustomPaint(
      painter: _WavePainter(Theme.of(context).colorScheme.primary, value),
    ),
  );
}

class LevelBlob extends StatelessWidget {
  const LevelBlob({required this.level, this.label, super.key});
  final double level;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final value = level.clamp(0.0, 1.0);
    return Semantics(
      label: label ?? 'Audio level',
      value: '${(value * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => SizedBox(
          height: 190,
          width: 190,
          child: CustomPaint(
            painter: _BlobPainter(
              color: Theme.of(context).colorScheme.primary,
              level: animated,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({required this.color, required this.level});
  final Color color;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * (.29 + level * .15);
    final path = Path();
    for (var i = 0; i <= 36; i++) {
      final angle = i / 36 * math.pi * 2;
      final wobble = 1 + math.sin(angle * 3 + level * 5) * (.04 + level * .04);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * wobble;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawShadow(path, color.withValues(alpha: .28), 16, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.level != level;
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.icon, super.key});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class ExpressiveEmptyState extends StatelessWidget {
  const ExpressiveEmptyState({
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    super.key,
  });
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ColorBlockedCard(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Column(
      children: [
        Icon(icon, size: 48),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
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
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

class ConnectedChoice<T> extends StatelessWidget {
  const ConnectedChoice({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
    super.key,
  });
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
          backgroundColor: value == groupValue
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(label),
      ),
    ),
  );
}
