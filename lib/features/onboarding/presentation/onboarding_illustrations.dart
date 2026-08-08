import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

class OnboardingIllustration1 extends StatelessWidget {
  const OnboardingIllustration1({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Icon(
            Icons.location_on_outlined,
            size: 80,
            color: colorScheme.primary,
          ),
          ..._buildConnectionNodes(colorScheme),
        ],
      ),
    );
  }

  List<Widget> _buildConnectionNodes(ColorScheme colorScheme) {
    return [
      Positioned(
        top: 40,
        left: 40,
        child: _Node(color: colorScheme.secondary, size: 16),
      ),
      Positioned(
        bottom: 40,
        right: 40,
        child: _Node(color: colorScheme.tertiary, size: 20),
      ),
      Positioned(
        top: 60,
        right: 30,
        child: _Node(color: colorScheme.primary, size: 12),
      ),
    ];
  }
}

class OnboardingIllustration2 extends StatelessWidget {
  const OnboardingIllustration2({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          Icon(Icons.people_outline, size: 120, color: colorScheme.primary),
          Positioned(
            bottom: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Node(color: colorScheme.secondary, size: 12),
                const SizedBox(width: AppSpacing.sm),
                _Node(color: colorScheme.primary, size: 12),
                const SizedBox(width: AppSpacing.sm),
                _Node(color: colorScheme.tertiary, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingIllustration3 extends StatelessWidget {
  const OnboardingIllustration3({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _ConnectionPainter(
              colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          const Icon(Icons.handshake_outlined, size: 100, color: Colors.white),
          Positioned(
            top: 20,
            child: _Node(color: colorScheme.primary, size: 24),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: _Node(color: colorScheme.secondary, size: 24),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: _Node(color: colorScheme.tertiary, size: 24),
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  _ConnectionPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 3, paint);
    canvas.drawLine(center, const Offset(100, 20), paint);
    canvas.drawLine(center, const Offset(20, 180), paint);
    canvas.drawLine(center, const Offset(180, 180), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
