import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  // Field _id dari MongoDB — nullable karena bisa belum ada sebelum disimpan
  final ObjectId? id;
  final String title;
  final String date;
  final String description;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.description,
    this.category = 'Pribadi',
  });

  // Konversi Map (dari MongoDB) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pribadi',
    );
  }

  // Konversi Object ke Map untuk dikirim ke MongoDB
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'date': date,
      'description': description,
      'category': category,
    };
    if (id != null) {
      map['_id'] = id;
    }
    return map;
  }

  // ── Timestamp Helpers (intl) ───────────────────────────────────────────────

  /// Parse tanggal dari field date (ISO / DateTime.now().toString())
  DateTime? get parsedDate {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  /// Format lokal Indonesia: "25 Jan 2026"
  String get formattedDate {
    final dt = parsedDate;
    if (dt == null) return date;
    return DateFormat('d MMM yyyy', 'id').format(dt);
  }

  /// Waktu relatif: "2 menit yang lalu", "kemarin", dsb.
  String get timeAgo {
    final dt = parsedDate;
    if (dt == null) return date;

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m menit yang lalu';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h jam yang lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin pukul ${DateFormat('HH:mm', 'id').format(dt)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari yang lalu';
    } else {
      return formattedDate;
    }
  }
}
