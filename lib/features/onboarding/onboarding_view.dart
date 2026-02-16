import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';


class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

// Di dalam State class Anda
int step = 1;

class _OnboardingViewState extends State<OnboardingView> {
  // 1. Variabel penampung state (data yang bisa berubah)
  int step = 1;

  // 2. Fungsi Logika
  void nextStep() {
    setState(() {
      if (step < 3) {
        step++;
      } else {
        // Navigasi ke halaman login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Halaman Onboarding", style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          // Ilustrasi konten yang berubah berdasarkan step
          _buildImage(step),
        ],
      ),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    floatingActionButton: FloatingActionButton.extended(
      onPressed: nextStep, // Memanggil fungsi logika di atas
      label: Text(step == 3 ? "Mulai Login" : "Lanjut"),
      icon: Icon(step == 3 ? Icons.login : Icons.arrow_forward),
    ),
  );
}

// Widget tambahan untuk membedakan isi tiap step
Widget _buildImage(int step) {
  // Logika: Tampilkan gambar berbeda tergantung step
  String imageName;
  if (step == 1) {
    imageName = 'onboarding_1.png';
  } else if (step == 2) {
    imageName = 'onboarding_2.png';
  } else {
    imageName = 'onboarding_3.png';
  }

  return Image.asset(
    'assets/images/$imageName',
    width: 300,
    height: 300,
    fit: BoxFit.contain, // Agar gambar proporsional
  );
 }
}