import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../shared/widgets/mitzone_brand.dart';
import '../../../shared/widgets/mitzone_loading_indicator.dart';

/// The initial screen of the application.
///
/// Displays the Mitzone brand and logo with a subtle reveal animation.
/// Once the sequence is complete, [onCompleted] is called to handle navigation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.onCompleted, super.key});

  /// Callback invoked when the splash animation sequence is finished.
  final VoidCallback onCompleted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isVisible = false;
  bool _showLoading = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    // Start the animation sequence after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSequence();
    });
  }

  Future<void> _startSequence() async {
    final bool reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reducedMotion) {
      // In reduced motion mode, skip the reveal animations.
      if (mounted) {
        setState(() {
          _isVisible = true;
          _showLoading = true;
        });
      }
      // Allow a brief moment for the splash to be visible.
      await Future.delayed(const Duration(milliseconds: 800));
    } else {
      // Sequential reveal: Brand mark first, then loading indicator.
      if (mounted) {
        setState(() => _isVisible = true);
      }

      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() => _showLoading = true);
      }

      // Hold the final state for a moment.
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    if (mounted && !_completed) {
      _completed = true;
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.backgroundAtmospheric,
        ),
        child: Stack(
          children: [
            Center(
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                child: AnimatedScale(
                  scale: _isVisible ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  child: const MitzoneBrand(size: 100),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: const MitzoneLoadingIndicator(compact: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
