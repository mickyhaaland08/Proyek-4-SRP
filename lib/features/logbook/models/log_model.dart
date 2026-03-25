import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel extends HiveObject {
  @HiveField(0)
  final ObjectId? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId;

  @HiveField(6)
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'date': date,
      'authorId': authorId,
      'teamId': teamId,
      'category': category,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? '',
      teamId: map['teamId'] ?? '',
      category: map['category'] ?? '',
    );
  }

  // ── Timestamp Helpers (intl) ─────────────────────────────────────────────

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
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin pukul ${DateFormat('HH:mm', 'id').format(dt)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari yang lalu';
    } else {
      return formattedDate;
    }
  }
}
