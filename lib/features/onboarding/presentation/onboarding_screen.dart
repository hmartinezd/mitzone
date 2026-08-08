import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_entry_resolver.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/identity/identity_providers.dart';
import '../../../shared/widgets/mitzone_button.dart';
import '../../../shared/widgets/mitzone_feedback_banner.dart';
import '../../../shared/widgets/mitzone_page_scaffold.dart';
import '../../profile/data/profile_providers.dart';
import '../data/onboarding_providers.dart';
import 'onboarding_illustrations.dart';
import 'onboarding_page.dart';
import 'onboarding_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;
  String? _errorMessage;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      title: 'The best connections begin in the real world.',
      description:
          'Mitzone helps you reconnect with people you shared a place and a moment with.',
      illustration: OnboardingIllustration1(),
    ),
    _OnboardingData(
      title: 'Share experiences.',
      description:
          'Join events, scan QR codes, and discover people who were there with you.',
      illustration: OnboardingIllustration2(),
    ),
    _OnboardingData(
      title: 'Turn encounters into opportunities.',
      description:
          'Build friendships, professional connections, and meaningful relationships safely and voluntarily.',
      illustration: OnboardingIllustration3(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    try {
      final store = ref.read(onboardingStatusStoreProvider);
      await store.markCompleted();

      if (mounted) {
        final resolver = AppEntryResolver(
          onboardingStatusStore: store,
          identityGateway: ref.read(identityGatewayProvider),
          profileRepository: ref.read(profileRepositoryProvider),
        );

        final target = await resolver.resolve();

        if (!mounted) return;

        switch (target) {
          case AppEntryTarget.onboarding:
            // Should not happen if markCompleted succeeded.
            setState(() {
              _isCompleting = false;
              _errorMessage =
                  "We couldn't save your progress. Please try again.";
            });
          case AppEntryTarget.createProfile:
            context.go(AppRoutes.createProfile);
          case AppEntryTarget.ready:
            context.go(AppRoutes.showcase);
          case AppEntryTarget.entryFailure:
            context.go(AppRoutes.showcase);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompleting = false;
          _errorMessage = "We couldn't save your progress. Please try again.";
        });
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      final bool reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reducedMotion) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      final bool reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reducedMotion) {
        _pageController.jumpToPage(_currentPage - 1);
      } else {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _previousPage();
      },
      child: MitzonePageScaffold(
        showAppBar: false,
        scrollable: false,
        horizontalPadding: 0,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: SizedBox(
                    height: 48,
                    child: isLastPage
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: _isCompleting
                                ? null
                                : _completeOnboarding,
                            child: const Text('Skip'),
                          ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingPage(
                    title: page.title,
                    description: page.description,
                    illustration: page.illustration,
                  );
                },
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: MitzoneFeedbackBanner(
                  title: 'Error',
                  message: _errorMessage,
                  type: MitzoneFeedbackType.error,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.md,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OnboardingPageIndicator(
                    itemCount: _pages.length,
                    currentIndex: _currentPage,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  MitzoneButton(
                    text: isLastPage ? 'Get Started' : 'Next',
                    isLoading: _isCompleting,
                    onPressed: _isCompleting ? null : _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.illustration,
  });

  final String title;
  final String description;
  final Widget illustration;
}
