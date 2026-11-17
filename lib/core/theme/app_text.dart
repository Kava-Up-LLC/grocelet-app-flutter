import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Type scale (DESIGN.md §3). One family: Bricolage Grotesque, bundled in assets/fonts.
abstract final class AppText {
  static const family = 'BricolageGrotesque';

  static const hero = TextStyle(fontFamily: family, fontSize: 56, height: 0.95, fontWeight: FontWeight.w800, letterSpacing: -1.7, color: AppColors.ink);
  static const title = TextStyle(fontFamily: family, fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppColors.ink);
  static const code = TextStyle(fontFamily: family, fontSize: 44, height: 1.0, fontWeight: FontWeight.w800, letterSpacing: 9.7, color: AppColors.ink);
  static const lead = TextStyle(fontFamily: family, fontSize: 20, height: 1.35, fontWeight: FontWeight.w400, color: AppColors.ink);
  static const item = TextStyle(fontFamily: family, fontSize: 18, height: 1.3, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const cardTitle = TextStyle(fontFamily: family, fontSize: 17, height: 1.25, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const body = TextStyle(fontFamily: family, fontSize: 17, height: 1.45, fontWeight: FontWeight.w400, color: AppColors.ink);
  static const button = TextStyle(fontFamily: family, fontSize: 17, height: 1.0, fontWeight: FontWeight.w700);
  static const label = TextStyle(fontFamily: family, fontSize: 14, height: 1.2, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const meta = TextStyle(fontFamily: family, fontSize: 15, height: 1.3, fontWeight: FontWeight.w400, color: AppColors.inkMuted);
  static const chip = TextStyle(fontFamily: family, fontSize: 14, height: 1.0, fontWeight: FontWeight.w600, letterSpacing: 2.5, color: AppColors.ink);
  static const magnet = TextStyle(fontFamily: family, fontSize: 13, height: 1.0, fontWeight: FontWeight.w800, color: AppColors.onColor);
}
