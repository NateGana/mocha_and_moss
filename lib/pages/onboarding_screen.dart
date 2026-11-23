import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/drink_art.dart';

class _Slide {
  final String art;
  final String title;
  final String body;
  const _Slide(this.art, this.title, this.body);
}

const _slides = [
  _Slide(
    'mocha_dark',
    'Meet Your New Favorite Mocha.',
    'Handcrafted mochas are the heart of our menu, made to order just the way you like them.',
  ),
  _Slide(
    'mocha_iced',
    'Rich Chocolate. Smooth Espresso. Perfectly Balanced.',
    'Choose your size, sweetness, milk and toppings, hot or iced.',
  ),
  _Slide(
    'matcha',
    'A Little Matcha, A Lot of Comfort.',
    'A small matcha collection and sweet café treats to go with your cup.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _finish() {
    store.markOnboardingSeen();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final last = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: colors.espresso,
      body: PhoneFrame(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip', style: TextStyle(color: colors.oat)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final s = _slides[i];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          AspectRatio(
                            aspectRatio: 1.15,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: colors.line),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: DrinkArt(artKey: s.art),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: AppFonts.serif(fontSize: 26, color: colors.latte),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.oat, fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? colors.gold : colors.line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: last ? 'Get started' : 'Next',
                    onPressed: () {
                      if (last) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
