// login_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  int _wrongattempt = 0;
  bool _isLocked = false;
  int _remainingSecond = 0;

  bool get isLocked => _isLocked;
  int get remainingSecond => _remainingSecond;
  // Database sederhana (Hardcoded)
  Map<String, String> _userDatabase = {
    "admin": "123",
    "user": "123",
    "guest": "123",
  };

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    if (_userDatabase.containsKey(username) &&
        _userDatabase[username] == password) {
      return true;
    }
    return false;
  }

  void startLockTimer() {
    _isLocked = true;
    _remainingSecond = 10;

    notifyListeners();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSecond--;
      notifyListeners();

      if (_remainingSecond <= 0) {
        timer.cancel();
        _isLocked = false;
        _wrongattempt = 0; // Reset percobaan salah setelah lock selesai
        notifyListeners();
      }
    });
  }

  String? validateInput(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      return "Username dan Password tidak boleh kosong!";
    }
    bool isValid =
        _userDatabase.containsKey(username) &&
        _userDatabase[username] == password;
    if (isValid) {
      _wrongattempt = 0; // Reset percobaan salah jika login berhasil
    }
    if (!isValid) {
      _wrongattempt++;
      if (_wrongattempt >= 3) {
        _isLocked = true;
        startLockTimer(); // Mulai timer untuk lock
        return "Terlalu banyak percobaan salah! Akun terkunci selama 10 detik.";
      }
      return "Login Gagal! Percobaan ke-$_wrongattempt";
    }
    return null;
  }
}
