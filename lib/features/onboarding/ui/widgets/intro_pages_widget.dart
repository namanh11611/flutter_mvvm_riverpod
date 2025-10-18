import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../view_model/onboarding_view_model.dart';
import 'intro_page.dart';

class IntroPagesWidget extends ConsumerStatefulWidget {
  const IntroPagesWidget({super.key});

  @override
  ConsumerState<IntroPagesWidget> createState() => _IntroPagesWidgetState();
}

class _IntroPagesWidgetState extends ConsumerState<IntroPagesWidget> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);
    
    const totalPages = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                height: 40,
                child: Stack(
                  children: [
                    // Centered Logo
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'authentick',
                            style: AppTheme.title18.copyWith(
                              color: AppColors.mono100,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.blueberry100,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                    // Skip Button aligned to the right
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: viewModel.skipIntro,
                        child: Text(
                          'Skip',
                          style: AppTheme.label14.copyWith(
                            color: AppColors.mono80,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  viewModel.setIntroPage(index);
                },
                children: const [
                  IntroPage(
                    title: 'See Unfiltered Moments',
                    subtitle: 'Capture it. Don\'t curate it. Only share moments captured live through the app. No uploads. No edits.',
                    imagePath: 'assets/images/onboarding_moments.png',
                  ),
                  IntroPage(
                    title: 'Only Real Places',
                    subtitle: 'Be where you say you are. Tag a location only if you\'re really there. All check-ins are verified in real time.',
                    imagePath: 'assets/images/onboarding_places.png',
                  ),
                  IntroPage(
                    title: 'Discovery Redefined',
                    subtitle: 'See unfiltered moments on a real-time map, from your city to cities you\'ve never seen.',
                    imagePath: 'assets/images/onboarding_discovery_map.png',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalPages,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.introPageIndex == index
                        ? AppColors.blueberry100
                        : AppColors.mono40,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: state.introPageIndex == totalPages - 1
                    ? ElevatedButton(
                        onPressed: viewModel.nextIntroPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6D28D9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        child: const Text(
                          'Try it out',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6D28D9),
                          side: const BorderSide(
                            color: Color(0xFF6D28D9),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}