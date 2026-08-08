import 'package:flutter/material.dart';
import '../../app/theme/app_gradients.dart';
import '../../app/theme/app_spacing.dart';

class MitzonePageScaffold extends StatelessWidget {
  const MitzonePageScaffold({
    required this.child,
    super.key,
    this.title,
    this.appBar,
    this.useSafeArea = true,
    this.scrollable = true,
    this.horizontalPadding = AppSpacing.mobilePagePadding,
    this.centered = false,
    this.showAppBar = true,
  });

  final Widget child;
  final String? title;
  final PreferredSizeWidget? appBar;
  final bool useSafeArea;
  final bool scrollable;
  final double horizontalPadding;
  final bool centered;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (centered) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidthCompact,
          ),
          child: content,
        ),
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: content,
      );
    } else {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: content,
      );
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      appBar: showAppBar
          ? (appBar ?? (title != null ? AppBar(title: Text(title!)) : null))
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.backgroundAtmospheric,
        ),
        child: content,
      ),
    );
  }
}
