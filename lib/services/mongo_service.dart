import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static const String _source = "mongo_service.dart";

  // ── Koneksi aman ke Collection ───────────────────────────────────────────
  Future<DbCollection> _getSafeCollection() async {
    final uri = dotenv.env['MONGO_URI'] ?? '';
    final dbName = dotenv.env['DB_NAME'] ?? '';
    final colName = dotenv.env['COLLECTION_NAME'] ?? '';

    final db = await Db.create(uri);
    await db.open();
    return db.collection(colName.isNotEmpty ? colName : dbName);
  }

  // ── READ: Mengambil data dari Cloud ─────────────────────────────────────
  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList();

      await LogHelper.writeLog(
        "INFO: Berhasil fetch ${data.length} log untuk Team: $teamId",
        source: _source,
        level: 3,
      );

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      await collection.insert(log.toMap());
      await LogHelper.writeLog(
        "INFO: Insert log '${log.title}' berhasil",
        source: _source,
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> updateLog(ObjectId id, LogModel updatedLog) async {
    try {
      final collection = await _getSafeCollection();
      await collection.update(where.id(id), {'\$set': updatedLog.toMap()});
      await LogHelper.writeLog(
        "INFO: Update log '${updatedLog.title}' berhasil",
        source: _source,
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));
      await LogHelper.writeLog(
        "INFO: Delete log '$id' berhasil",
        source: _source,
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Delete Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }
}
