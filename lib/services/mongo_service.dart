import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;

  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  // ── Internal: pastikan koleksi siap sebelum operasi apapun ────────────────
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3, // VERBOSE — hanya muncul jika LOG_LEVEL=3
      );
      await connect();
    }
    return _collection!;
  }

  // ── CONNECT ───────────────────────────────────────────────────────────────
  Future<void> connect() async {
    await LogHelper.writeLog(
      "CONNECT: Memulai koneksi ke MongoDB Atlas...",
      source: _source,
      level: 3,
    );
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) throw Exception("MONGODB_URI tidak ditemukan di .env");

      _db = await Db.create(dbUri);
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Timeout. Cek IP Whitelist (0.0.0.0/0) atau Sinyal HP.",
        ),
      );
      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "CONNECT: Berhasil terhubung ke Atlas — Koleksi 'logs' siap.",
        source: _source,
        level: 2, // INFO
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1, // ERROR
      );
      rethrow;
    }
  }

  // ── READ ──────────────────────────────────────────────────────────────────
  Future<List<LogModel>> getLogs() async {
    await LogHelper.writeLog(
      "READ: Mengambil semua data dari Cloud...",
      source: _source,
      level: 3,
    );
    try {
      final collection = await _getSafeCollection();
      final stopwatch = Stopwatch()..start();

      final List<Map<String, dynamic>> data = await collection.find().toList();
      stopwatch.stop();

      await LogHelper.writeLog(
        "READ: Berhasil — ${data.length} dokumen dimuat (${stopwatch.elapsedMilliseconds}ms).",
        source: _source,
        level: 2,
      );
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "READ: Gagal fetch data - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<void> insertLog(LogModel log) async {
    await LogHelper.writeLog(
      "CREATE: Menyimpan dokumen baru — title: '${log.title}', id: ${log.id}",
      source: _source,
      level: 3,
    );
    try {
      final collection = await _getSafeCollection();
      final stopwatch = Stopwatch()..start();

      await collection.insertOne(log.toMap());
      stopwatch.stop();

      await LogHelper.writeLog(
        "CREATE: Berhasil — '${log.title}' tersimpan di Cloud (${stopwatch.elapsedMilliseconds}ms).",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "CREATE: Gagal menyimpan '${log.title}' - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> updateLog(LogModel log) async {
    await LogHelper.writeLog(
      "UPDATE: Memperbarui dokumen id: ${log.id}, title: '${log.title}'",
      source: _source,
      level: 3,
    );
    try {
      final collection = await _getSafeCollection();
      if (log.id == null) {
        throw Exception("ID Log tidak ditemukan untuk update.");
      }
      final stopwatch = Stopwatch()..start();

      await collection.replaceOne(where.id(log.id!), log.toMap());
      stopwatch.stop();

      await LogHelper.writeLog(
        "UPDATE: Berhasil — '${log.title}' diperbarui di Cloud (${stopwatch.elapsedMilliseconds}ms).",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UPDATE: Gagal memperbarui '${log.title}' - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteLog(ObjectId id) async {
    await LogHelper.writeLog(
      "DELETE: Menghapus dokumen id: $id",
      source: _source,
      level: 3,
    );
    try {
      final collection = await _getSafeCollection();
      final stopwatch = Stopwatch()..start();

      await collection.remove(where.id(id));
      stopwatch.stop();

      await LogHelper.writeLog(
        "DELETE: Berhasil — id $id dihapus dari Cloud (${stopwatch.elapsedMilliseconds}ms).",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DELETE: Gagal menghapus id $id - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // ── CLOSE ─────────────────────────────────────────────────────────────────
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      await LogHelper.writeLog(
        "CONNECT: Koneksi ke Atlas ditutup.",
        source: _source,
        level: 2,
      );
    }
  }
}
