import 'package:flutter/material.dart';

class MitzoneThemeColors extends ThemeExtension<MitzoneThemeColors> {
  const MitzoneThemeColors({
    required this.brandCyan,
    required this.brandBlue,
    required this.brandPurple,
    required this.surfaceSubtle,
    required this.surfaceStrong,
  });

  final Color brandCyan;
  final Color brandBlue;
  final Color brandPurple;
  final Color surfaceSubtle;
  final Color surfaceStrong;

  @override
  MitzoneThemeColors copyWith({
    Color? brandCyan,
    Color? brandBlue,
    Color? brandPurple,
    Color? surfaceSubtle,
    Color? surfaceStrong,
  }) {
    return MitzoneThemeColors(
      brandCyan: brandCyan ?? this.brandCyan,
      brandBlue: brandBlue ?? this.brandBlue,
      brandPurple: brandPurple ?? this.brandPurple,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
    );
  }

  @override
  MitzoneThemeColors lerp(ThemeExtension<MitzoneThemeColors>? other, double t) {
    if (other is! MitzoneThemeColors) {
      return this;
    }
    return MitzoneThemeColors(
      brandCyan: Color.lerp(brandCyan, other.brandCyan, t)!,
      brandBlue: Color.lerp(brandBlue, other.brandBlue, t)!,
      brandPurple: Color.lerp(brandPurple, other.brandPurple, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
    );
  }
}
