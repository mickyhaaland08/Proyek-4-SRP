// login_view.dart
import 'package:flutter/material.dart';
import 'package:logbook_app_001/core/app_colors.dart';
// Import Controller milik sendiri (masih satu folder)
import 'package:logbook_app_001/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isObscure = true;

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CounterView(username: user)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Gagal!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text(
          "Login Gatekeeper",
          style: TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon / Logo
              Icon(Icons.lock_outline, size: 80, color: AppColors.primaryDark),
              const SizedBox(height: 16),
              Text(
                "Selamat Datang",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Silakan login untuk melanjutkan",
                style: TextStyle(fontSize: 14, color: AppColors.hint),
              ),
              const SizedBox(height: 40),

              // Field Username
              TextField(
                controller: _userController,
                style: TextStyle(color: AppColors.primaryLight),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: AppColors.primaryDark),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.primaryDark,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Field Password
              TextField(
                controller: _passController,
                obscureText: _isObscure,
                style: TextStyle(color: AppColors.primaryLight),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: AppColors.primaryDark),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.primaryDark,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primaryDark,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Masuk — reactive terhadap lock state
              ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  final locked = _controller.isLocked;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: locked
                          ? null
                          : () {
                              String? validationMessage = _controller
                                  .validateInput(
                                    _userController.text,
                                    _passController.text,
                                  );
                              if (validationMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(validationMessage),
                                    backgroundColor: AppColors.textDanger,
                                  ),
                                );
                              } else {
                                _handleLogin();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: locked
                            ? AppColors.disabled
                            : AppColors.primaryDark,
                        foregroundColor: locked
                            ? AppColors.disabledText
                            : AppColors.textOnDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        locked
                            ? "Tunggu (${_controller.remainingSecond}s)"
                            : "Masuk",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
