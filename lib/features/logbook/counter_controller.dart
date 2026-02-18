import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int get value => _counter;

  List<String> _history = [];
  List<String> get history => List.unmodifiable(_history);

  // ── Helper: key per username agar data tiap user terpisah ─────────────────
  String _keyCounter(String username) => 'counter_$username';
  String _keyHistory(String username) => 'history_$username';

  // ── Helper: format waktu ──────────────────────────────────────────────────
  String _getWaktu() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  // ── LOAD: Ambil data milik username tertentu ──────────────────────────────
  Future<void> loadData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt(_keyCounter(username)) ?? 0;
    _history = prefs.getStringList(_keyHistory(username)) ?? [];
  }

  // ── SAVE: Simpan counter milik username ───────────────────────────────────
  Future<void> _saveCounter(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCounter(username), _counter);
  }

  // ── SAVE: Simpan history milik username ───────────────────────────────────
  Future<void> _saveHistory(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyHistory(username), _history);
  }

  // ── Operasi Counter ───────────────────────────────────────────────────────
  Future<void> increment(int step, String username) async {
    _counter += step;
    _history.add(
      "User $username menambah +$step pada pukul ${_getWaktu()} (Total: $_counter)",
    );
    await _saveCounter(username);
    await _saveHistory(username);
  }

  Future<void> decrement(int step, String username) async {
    if (_counter >= step) {
      _counter -= step;
    } else {
      _counter = 0;
    }
    _history.add(
      "User $username mengurangi -$step pada pukul ${_getWaktu()} (Total: $_counter)",
    );
    await _saveCounter(username);
    await _saveHistory(username);
  }

  Future<void> reset(String username) async {
    _counter = 0;
    _history.add(
      "User $username mereset hitungan pada pukul ${_getWaktu()} (Total: 0)",
    );
    await _saveCounter(username);
    await _saveHistory(username);
  }
}
