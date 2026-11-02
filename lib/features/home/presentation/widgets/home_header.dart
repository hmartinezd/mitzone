import 'package:flutter/material.dart';
import '../../../../shared/widgets/mitzone_brand.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.displayName, super.key});
  final String? displayName;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const MitzoneBrand(size: 36, showText: false),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mitzone',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
                height: 1.1,
              ),
            ),
            Text(
              displayName == null ? 'Welcome back' : 'Hi, $displayName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFA6B3C4),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
