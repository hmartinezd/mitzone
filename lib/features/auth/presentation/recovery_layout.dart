import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/mitzone_brand.dart';

/// A scrollable form, including on small screens with large accessibility text.
class RecoveryLayout extends StatelessWidget {
  const RecoveryLayout({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidthForm,
            ),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MitzoneBrand(size: 60, showTagline: false),
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
