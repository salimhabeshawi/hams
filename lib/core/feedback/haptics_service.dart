// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/services.dart';

class HapticsService {
  const HapticsService({this.enabled = true});
  final bool enabled;
  Future<void> tap() async { if (enabled) await HapticFeedback.selectionClick(); }
  Future<void> success() async { if (enabled) await HapticFeedback.mediumImpact(); }
}
