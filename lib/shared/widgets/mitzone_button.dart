import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

enum MitzoneButtonVariant { primary, secondary, tertiary, destructive }

class MitzoneButton extends StatelessWidget {
  const MitzoneButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.variant = MitzoneButtonVariant.primary,
    this.isLoading = false,
    this.enabled = true,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = true,
    this.semanticLabel,
  });

  final String text;
  final VoidCallback? onPressed;
  final MitzoneButtonVariant variant;
  final bool isLoading;
  final bool enabled;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = (enabled && !isLoading) ? onPressed : null;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getForegroundColor(theme),
            ),
          )
        else ...[
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(text, textAlign: TextAlign.center)),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(trailingIcon, size: 20),
          ],
        ],
      ],
    );

    if (fullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    final buttonStyle = _getButtonStyle(theme);

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: enabled && !isLoading,
      child: _buildButton(content, buttonStyle, effectiveOnPressed),
    );
  }

  Widget _buildButton(
    Widget child,
    ButtonStyle? style,
    VoidCallback? onPressed,
  ) {
    switch (variant) {
      case MitzoneButtonVariant.primary:
      case MitzoneButtonVariant.destructive:
        return FilledButton(onPressed: onPressed, style: style, child: child);
      case MitzoneButtonVariant.secondary:
        return OutlinedButton(onPressed: onPressed, style: style, child: child);
      case MitzoneButtonVariant.tertiary:
        return TextButton(onPressed: onPressed, style: style, child: child);
    }
  }

  ButtonStyle? _getButtonStyle(ThemeData theme) {
    switch (variant) {
      case MitzoneButtonVariant.primary:
        return theme.filledButtonTheme.style;
      case MitzoneButtonVariant.destructive:
        final destructiveStyle = FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
        );
        final baseStyle = theme.filledButtonTheme.style;
        return baseStyle != null
            ? destructiveStyle.merge(baseStyle)
            : destructiveStyle;
      case MitzoneButtonVariant.secondary:
        return theme.outlinedButtonTheme.style;
      case MitzoneButtonVariant.tertiary:
        return theme.textButtonTheme.style;
    }
  }

  Color _getForegroundColor(ThemeData theme) {
    switch (variant) {
      case MitzoneButtonVariant.primary:
        return theme.colorScheme.onPrimary;
      case MitzoneButtonVariant.destructive:
        return theme.colorScheme.onError;
      case MitzoneButtonVariant.secondary:
      case MitzoneButtonVariant.tertiary:
        return theme.colorScheme.primary;
    }
  }
}
