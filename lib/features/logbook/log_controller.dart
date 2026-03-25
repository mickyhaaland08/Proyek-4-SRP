import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/core/access_policy.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<List<LogModel>> filteredLogs =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

  String currentTeamId = "";
  String currentUserId = "";
  String userRole = "";

  void setUserInfo({
    required String userId,
    required String role,
    String teamId = "",
  }) {
    currentUserId = userId;
    userRole = role;
    currentTeamId = teamId;
  }

  LogController() {
    logsNotifier.addListener(() {
      filteredLogs.value = logsNotifier.value;
    });

    Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value =
          !results.contains(ConnectivityResult.none) && results.isNotEmpty;
      if (isOnline.value) _syncOfflineData();
    });
  }

  Future<void> loadFromDisk() async {
    logsNotifier.value = _myBox.values.toList();

    await LogHelper.writeLog(
      "INFO: Load ${_myBox.length} log lokal dari Hive",
      source: "log_controller.dart",
      level: 3,
    );

    try {
      final cloudData = await MongoService().getLogs(currentTeamId);

      await _myBox.clear();
      await _myBox.addAll(cloudData);
      logsNotifier.value = cloudData;

      await LogHelper.writeLog(
        "SYNC: ${cloudData.length} data berhasil diperbarui dari Atlas",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal - $e",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
      authorId: currentUserId,
      teamId: currentTeamId,
    );

    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SUCCESS: Data '${newLog.title}' tersinkron ke Cloud",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal, akan sinkron saat online - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String newCategory,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final isOwner = oldLog.authorId == currentUserId;
    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: '$currentUserId' coba edit log milik '${oldLog.authorId}'",
        level: 1,
        source: "log_controller.dart",
      );
      throw Exception("Security Breach: Anda tidak memiliki akses!");
    }

    final updatedLog = LogModel(
      id: oldLog.id,
      title: newTitle,
      description: newDesc,
      date: oldLog.date,
      category: newCategory,
      teamId: oldLog.teamId,
      authorId: oldLog.authorId,
    );

    final hiveIndex = _myBox.values.toList().indexWhere(
      (log) => log.id == oldLog.id,
    );
    if (hiveIndex != -1) await _myBox.putAt(hiveIndex, updatedLog);

    currentLogs[index] = updatedLog;
    logsNotifier.value = currentLogs;

    try {
      await MongoService().updateLog(oldLog.id!, updatedLog);
      await LogHelper.writeLog(
        "SUCCESS: Update log '$newTitle'",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal update cloud - $e",
        level: 1,
        source: "log_controller.dart",
      );
    }
  }

  Future<void> removeLog(int index) async {
    final target = logsNotifier.value[index];

    if (!AccessControlService.canPerform(
      userRole,
      AccessControlService.actionDelete,
      isOwner: target.authorId == currentUserId,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: '$currentUserId' unauthorized delete '${target.title}'",
        level: 1,
        source: "log_controller.dart",
      );
      throw Exception("Security Breach: Anda tidak memiliki akses!");
    }

    final hiveIndex = _myBox.values.toList().indexWhere(
      (log) => log.id == target.id,
    );
    if (hiveIndex != -1) await _myBox.deleteAt(hiveIndex);

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;

    try {
      await MongoService().deleteLog(target.id!);
      await LogHelper.writeLog(
        "SUCCESS: Hapus log '${target.title}'",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal hapus cloud - $e",
        level: 1,
        source: "log_controller.dart",
      );
      rethrow;
    }
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  Future<void> _syncOfflineData() async {
    if (_myBox.isEmpty) return;

    await LogHelper.writeLog(
      "SYNC: Koneksi kembali, sync ${_myBox.length} data offline...",
      source: "log_controller.dart",
    );

    for (final log in _myBox.values) {
      try {
        await MongoService().insertLog(log);
        await LogHelper.writeLog(
          "SYNC: Log '${log.title}' berhasil disinkron",
          source: "log_controller.dart",
        );
      } catch (e) {
        await LogHelper.writeLog(
          "SYNC ERROR: Gagal sync '${log.title}' - $e",
          level: 1,
          source: "log_controller.dart",
        );
      }
    }

    await _myBox.clear();
    await loadFromDisk();
  }
}
