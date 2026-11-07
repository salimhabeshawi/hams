// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';

enum WindowSizeClass { compact, medium, expanded }

WindowSizeClass windowSizeClass(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return WindowSizeClass.compact;
  if (width < 840) return WindowSizeClass.medium;
  return WindowSizeClass.expanded;
}

class AdaptiveTwoPane extends StatelessWidget {
  const AdaptiveTwoPane({
    required this.primary,
    required this.secondary,
    super.key,
  });
  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    if (windowSizeClass(context) == WindowSizeClass.compact) return primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: primary),
        const SizedBox(width: 16),
        Expanded(child: secondary),
      ],
    );
  }
}
