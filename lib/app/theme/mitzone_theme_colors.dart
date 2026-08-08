import 'package:flutter/material.dart';

/// A [ThemeExtension] that provides Mitzone-specific semantic colors.
///
/// This extension allows us to define and use semantic roles that are not
/// covered by the standard [ColorScheme], such as success, warning, and info
/// roles, as well as brand-specific accent colors.
class MitzoneThemeColors extends ThemeExtension<MitzoneThemeColors> {
  const MitzoneThemeColors({
    required this.brandCyan,
    required this.brandBlue,
    required this.brandPurple,
    required this.surfaceSubtle,
    required this.surfaceStrong,
    required this.success,
    required this.successContainer,
    required this.onSuccess,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarning,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfo,
    required this.onInfoContainer,
    required this.focusIndicator,
  });

  final Color brandCyan;
  final Color brandBlue;
  final Color brandPurple;
  final Color surfaceSubtle;
  final Color surfaceStrong;
  final Color success;
  final Color successContainer;
  final Color onSuccess;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarning;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfo;
  final Color onInfoContainer;
  final Color focusIndicator;

  @override
  MitzoneThemeColors copyWith({
    Color? brandCyan,
    Color? brandBlue,
    Color? brandPurple,
    Color? surfaceSubtle,
    Color? surfaceStrong,
    Color? success,
    Color? successContainer,
    Color? onSuccess,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarning,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfo,
    Color? onInfoContainer,
    Color? focusIndicator,
  }) {
    return MitzoneThemeColors(
      brandCyan: brandCyan ?? this.brandCyan,
      brandBlue: brandBlue ?? this.brandBlue,
      brandPurple: brandPurple ?? this.brandPurple,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccess: onSuccess ?? this.onSuccess,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarning: onWarning ?? this.onWarning,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfo: onInfo ?? this.onInfo,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      focusIndicator: focusIndicator ?? this.focusIndicator,
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
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      focusIndicator: Color.lerp(focusIndicator, other.focusIndicator, t)!,
    );
  }
}
