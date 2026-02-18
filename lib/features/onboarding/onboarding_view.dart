import 'package:flutter/material.dart';
import 'package:logbook_app_001/core/app_colors.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

// Data konten setiap halaman onboarding
const List<Map<String, String>> _onboardingData = [
  {
    'image': 'assets/images/onboarding_1.png',
    'title': 'Selamat Datang',
  },
  {
    'image': 'assets/images/onboarding_2.png',
    'title': 'Semoga Harimu Baik-Baik Saja',
  },
  {
    'image': 'assets/images/onboarding_3.png',
    'title': 'Silahkan Masuk',
  },
];

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int step = 0; // 0-based untuk PageController

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (step < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tombol Skip kanan atas ─────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: AnimatedOpacity(
                  opacity: step < 2 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: TextButton(
                    onPressed: step < 2 ? _skip : null,
                    child: Text(
                      "Lewati",
                      style: TextStyle(color: AppColors.disabled),
                    ),
                  ),
                ),
              ),
            ),

            // ── PageView konten ────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) => setState(() => step = index),
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gambar ilustrasi
                        Image.asset(
                          data['image'] ?? '',
                          height: 260,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 32),

                        // Judul
                        Text(
                          data['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Page Indicator (bulat) ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_onboardingData.length, (i) {
                final isActive = i == step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: isActive ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryDark
                        : AppColors.disabled,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // ── Tombol Lanjut / Mulai Login ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _nextStep,
                  icon: Icon(step == 2 ? Icons.login : Icons.arrow_forward),
                  label: Text(
                    step == 2 ? "Mulai Login" : "Lanjut",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.textOnDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
