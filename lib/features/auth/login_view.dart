import 'package:flutter/material.dart';
import 'package:logbook_app_001/core/app_colors.dart';
import 'package:logbook_app_001/core/access_policy.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    String? validationMessage = _controller.validateInput(user, pass);

    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          backgroundColor: AppColors.textDanger,
        ),
      );
    } else {
      // Ambil Info user dari controller
      final userInfo = _controller.getUserInfo(user)!;

      _onLoginSuccess(
        username: user,
        userId: userInfo['userId']!,
        role: userInfo['role']!,
        teamId: userInfo['teamId']!,
      );
    }
  }

  void _onLoginSuccess({
    required String username,
    required String userId,
    required String role,
    required String teamId,
  }) async {
    final controller = LogController();
    controller.setUserInfo(userId: userId, role: role, teamId: teamId);

    if (!AccessControlService.canPerform(
      role,
      AccessControlService.actionRead,
    )) {
      _showSnackBar(
        "Akses ditolak! Role '$role' tidak dikenali.",
        color: Colors.red,
      );
      return;
    }

    // --- Simpan state login ke SharedPreferences ---
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('username', username);
    await prefs.setString('user_id', userId);
    await prefs.setString('role', role);
    await prefs.setString('team_id', teamId); // Tambahan

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CounterView(
          username: username,
          userId: userId,
          role: role,
          teamId: teamId,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppColors.primary,
      ),
    );
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
                      onPressed: locked ? null : _handleLogin,
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
