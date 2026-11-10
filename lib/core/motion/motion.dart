// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/animation.dart';

abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 500);
  static const emphasized = Cubic(0.2, 0.8, 0.2, 1);
  static SpringDescription get spring =>
      const SpringDescription(mass: 1, stiffness: 500, damping: 22);
}
