import 'package:flutter/painting.dart';

/// Fridge Door palette (DESIGN.md §2). Nothing is black; denim means "store trip".
abstract final class AppColors {
  static const fridge = Color(0xFFE8EFEC);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F3A32);
  static const inkMuted = Color(0xFF5A6B64);
  static const rule = Color(0xFFDCE6E2);
  static const edge = Color(0xFFC9D6D1);
  static const pine = Color(0xFF22614A);
  static const denim = Color(0xFF3E5C86);
  static const denimDeep = Color(0xFF2C4466);
  static const denimSoft = Color(0xFFDFE7F1);
  static const denimEdge = Color(0xFFC3D0DF);
  static const inkOnSoft = Color(0xFF4E5F6E);
  static const glue = Color(0xFFDCE4EE);
  static const butter = Color(0xFFF6E6BC);
  static const onColor = Color(0xFFFFFFFF);

  /// Member magnets: who added an item.
  static const magnets = [
    Color(0xFF9466B5), // plum
    Color(0xFF15938A), // teal
    Color(0xFFE0A100), // mustard
    Color(0xFF7A8B99), // slate
  ];

  /// Same member, same color on every phone (a stable hash, not String.hashCode).
  static Color magnetFor(String memberId) {
    var sum = 0;
    for (final unit in memberId.codeUnits) {
      sum = (sum * 31 + unit) & 0x7fffffff;
    }
    return magnets[sum % magnets.length];
  }

  // Hard drops, no blur: things are stuck on the fridge, not floating.
  static const fieldDrop = [BoxShadow(color: edge, offset: Offset(0, 2))];
  static const paperDrop = [BoxShadow(color: edge, offset: Offset(0, 3))];
  static const denimDrop = [BoxShadow(color: denimDeep, offset: Offset(0, 4))];
  static const softDrop = [BoxShadow(color: denimEdge, offset: Offset(0, 2))];
}
