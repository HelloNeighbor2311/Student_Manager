import 'package:flutter/material.dart';
import 'package:student_manager/models/student.dart';

/// Constants cho StudentCard
class StudentCardConstants {
  // Dimensions
  static const double cardBorderRadius = 16.0;
  static const double cardPadding = 14.0;
  static const double swipeActionThreshold = 60.0;
  static const double swipeActivationThreshold = 30.0;
  static const double swipeMaxOffset = 120.0;
  static const double actionButtonWidth = 60.0;
  static const Duration swipeAnimationDuration = Duration(milliseconds: 200);
  static const Duration quickPeekDelay = Duration(milliseconds: 300);
  static const Duration quickPeekDisplayDuration = Duration(seconds: 3);

  // Spacing
  static const double spacingSmall = 4.0;
  static const double spacingMedium = 8.0;
  static const double spacingLarge = 10.0;
  static const double spacingXLarge = 12.0;

  // Font sizes
  static const double fontSizeSmall = 11.0;
  static const double fontSizeMedium = 13.0;

  // Icon sizes
  static const double iconSizeSmall = 14.0;
  static const double iconSizeActionButton = 20.0;
  static const double iconSizeMenu = 18.0;

  // Colors - Swipe actions
  static const Color rightSwipeColor = Color(0xFF00A86B); // Green
  static const Color leftSwipeColor = Color(0xFF0066CC); // Blue
  static const Color swipeActionIconColor = Colors.white;

  // Colors - Academic Ranks (using Map for O(1) lookup instead of switch)
  static final Map<AcademicRank, Color> rankColorMap = {
    AcademicRank.excellent: const Color(0xFFD4AF37), // Gold
    AcademicRank.good: const Color(0xFF00A86B), // Green
    AcademicRank.fair: const Color(0xFFFF9500), // Orange
    AcademicRank.average: const Color(0xFFE53935), // Red
  };

  static final Map<AcademicRank, Color> rankTextColorMap = {
    AcademicRank.excellent: const Color(0xFF8B6F47),
    AcademicRank.good: const Color(0xFF00563B),
    AcademicRank.fair: const Color(0xFFC65911),
    AcademicRank.average: const Color(0xFF8B0000),
  };

  // Colors - Warning Status (GPA < 2.0)
  static const Color warningBorderColor = Color(0xFFDC2626); // Red-600
  static const Color warningBackgroundColor = Color(0xFFFEE2E2); // Red-50
  static const Color warningTextColor = Color(0xFF7F1D1D); // Red-900
  static const Color warningIconColor = Color(0xFFDC2626); // Red-600

  // Generic colors
  static const Color greyText = Colors.grey;
  static const Color errorRed = Colors.red;
  static const Color whiteBackground = Colors.white;
  static const Color transparentColor = Colors.transparent;
}

/// Utility class cho color management
extension AcademicRankColorExt on AcademicRank {
  /// Lấy màu cho badge dựa trên học lực
  Color get badgeColor => StudentCardConstants.rankColorMap[this] ?? 
      StudentCardConstants.rankColorMap[AcademicRank.average]!;

  /// Lấy màu chữ dựa trên học lực
  Color get textColor => StudentCardConstants.rankTextColorMap[this] ?? 
      StudentCardConstants.rankTextColorMap[AcademicRank.average]!;

  /// Lấy màu trong suốt (10% opacity)
  Color get lightenBadgeColor => badgeColor.withValues(alpha: 0.1);

  /// Lấy màu 20% opacity
  Color get lightBadgeColor => badgeColor.withValues(alpha: 0.2);
}
