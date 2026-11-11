import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';
import 'mitzone_page_body.dart';

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
    return Scaffold(
      appBar: showAppBar
          ? (appBar ?? (title != null ? AppBar(title: Text(title!)) : null))
          : null,
      body: MitzonePageBody(
        useSafeArea: useSafeArea,
        scrollable: scrollable,
        horizontalPadding: horizontalPadding,
        centered: centered,
        child: child,
      ),
    );
  }
}
