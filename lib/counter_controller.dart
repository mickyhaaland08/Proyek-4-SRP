import 'package:flutter/material.dart';

class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int get value => _counter; // Getter untuk akses data

  List<String> _history = [];
  List<String> get history => _history; // Getter untuk akses histori

  String _getWaktu() {
    DateTime now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  void increment(int step) {
    _counter += step;
    _history.add("User menambahkan nilai sebesar $step pada pukul ${_getWaktu()} (Total: $_counter)");
  }

  void decrement(int step) {
    if (_counter >= step) {
      _counter -= step;
      _history.add("User mengurangi nilai sebesar $step pada pukul ${_getWaktu()} (Total: $_counter)");
    } else {
      _counter = 0;
    }
  }
  void reset() {
    _counter = 0;
    _history.add("User mereset nilai pada pukul ${_getWaktu()} (Total: $_counter)");
 }
}