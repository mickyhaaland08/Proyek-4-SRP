// login_controller.dart
class LoginController {
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
}
