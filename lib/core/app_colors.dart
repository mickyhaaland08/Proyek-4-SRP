import 'package:flutter/material.dart';

/// Kumpulan warna tema aplikasi — ubah di sini, berlaku ke semua halaman.
class AppColors {
  AppColors._(); // Prevent instantiation

  /// Latar belakang gelap (hampir hitam kehijauan)
  static const Color background = Colors.black87;

  /// Warna aksen utama — teal
  static const Color primary = Colors.teal;

  /// Tombol / teks / ikon aktif — satu tingkat lebih cerah
  static final Color primaryLight = Colors.teal.shade300;

  /// AppBar & tombol utama
  static final Color primaryDark = Colors.teal.shade700;

  /// Tombol tambah (hijau cerah)
  static final Color success = Colors.green.shade400;

  /// Tombol kurang (oranye)
  static const Color danger = Colors.deepOrange;

  /// Tombol terkunci / disabled
  static final Color disabled = Colors.grey.shade700;

  /// Teks pada tombol terkunci
  static const Color disabledText = Colors.white54;

  /// Teks subjudul / hint
  static const Color hint = Colors.white54;

  /// Teks utama di atas background gelap
  static const Color textOnDark = Colors.white;

  /// Teks error / aksi destruktif
  static const Color textDanger = Colors.red;
}
