import 'package:flutter/material.dart';
import '../../../shared/widgets/mitzone_brand.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_feedback_banner.dart';
import '../../../shared/widgets/mitzone_page_scaffold.dart';
import '../../../app/theme/app_spacing.dart';

class StartupFailureScreen extends StatelessWidget {
  const StartupFailureScreen({
    required this.message,
    super.key,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MitzonePageScaffold(
      centered: true,
      scrollable: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MitzoneBrand(size: 80, showTagline: true),
          const SizedBox(height: AppSpacing.xhu),
          MitzoneFeedbackBanner(
            title: 'Startup Failed',
            message: onRetry == null
                ? '$message\n\nPlease check your network connection and try again later.'
                : message,
            type: MitzoneFeedbackType.error,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.xxl),
            MitzoneButton(
              text: 'Retry Startup',
              onPressed: onRetry!,
            ),
          ],
        ],
      ),
    );
  }
}
