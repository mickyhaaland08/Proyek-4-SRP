import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/core/app_colors.dart';
import 'package:logbook_app_001/core/access_policy.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterView extends StatefulWidget {
  final String username;
  final String userId;
  final String role;
  final String teamId;

  const CounterView({
    super.key,
    required this.username,
    required this.userId,
    required this.role,
    required this.teamId,
  });

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final LogController _controller;
  final TextEditingController _searchController = TextEditingController();

  // ── Category Color Helper ────────────────────────────────────────────────
  Color _categoryColor(String category) {
    switch (category) {
      case 'Mechanical':
        return Colors.green;
      case 'Electronic':
        return Colors.blue;
      case 'Software':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ── SnackBar Helper ──────────────────────────────────────────────────────
  void _showSnackBar(
    String message, {
    Color color = Colors.teal,
    IconData icon = Icons.check_circle,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Navigasi ke LogEditorPage ────────────────────────────────────────────
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LogEditorPage(log: log, index: index, controller: _controller),
      ),
    );
  }

  // ── Logout Dialog ────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // --- Hapus State Login dari SharedPreferences saat Logout ---
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    _controller.setUserInfo(userId: widget.userId, role: widget.role);
    _controller.loadFromDisk();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text("LogBook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadFromDisk(),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _controller.isOnline,
            builder: (context, online, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  online ? Icons.cloud_done : Icons.cloud_off,
                  color: online ? Colors.greenAccent : Colors.redAccent,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.primaryLight),
              onChanged: (query) => _controller.searchLog(query),
              decoration: InputDecoration(
                hintText: "Cari catatan...",
                hintStyle: const TextStyle(color: AppColors.hint),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryDark),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    return value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: Icon(Icons.clear, color: AppColors.disabled),
                            onPressed: () {
                              _searchController.clear();
                              _controller.searchLog('');
                            },
                          );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryLight,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // ── List Log ───────────────────────────────────────────────────
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, currentLogs, child) {
                if (currentLogs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchController.text.isEmpty
                                ? Icons.rocket_launch_outlined
                                : Icons.search_off_rounded,
                            size: 90,
                            color: AppColors.primaryDark.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchController.text.isEmpty
                                ? "Belum ada aktivitas hari ini?"
                                : "Catatan tidak ditemukan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isEmpty
                                ? "Mulai catat kemajuan proyek Anda!\nSetiap langkah kecil adalah progres."
                                : "Coba kata kunci yang berbeda.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.hint,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_searchController.text.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _goToEditor(),
                              icon: const Icon(Icons.add),
                              label: const Text("Buat Catatan Pertama"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    final realIndex = _controller.logsNotifier.value.indexOf(
                      log,
                    );

                    final isOwner = log.authorId == widget.userId;

                    final canEdit = AccessControlService.canPerform(
                      widget.role,
                      AccessControlService.actionUpdate,
                      isOwner: isOwner,
                    );

                    final canDelete = AccessControlService.canPerform(
                      widget.role,
                      AccessControlService.actionDelete,
                      isOwner: isOwner,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _categoryColor(log.category),
                          width: 3,
                        ),
                      ),
                      child: ListTile(
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              log.id != null
                                  ? Icons.cloud_done
                                  : Icons.cloud_upload_outlined,
                              color: log.id != null
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(log.title)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _categoryColor(
                                  log.category,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _categoryColor(log.category),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                log.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _categoryColor(log.category),
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBody(data: log.description),
                            const SizedBox(height: 4),
                            Text(
                              log.timeAgo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _goToEditor(log: log, index: realIndex),
                              ),

                            if (canDelete)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  try {
                                    await _controller.removeLog(realIndex);
                                    _showSnackBar(
                                      "Catatan berhasil dihapus!",
                                      color: Colors.red,
                                      icon: Icons.delete,
                                    );
                                  } catch (e) {
                                    _showSnackBar(
                                      e.toString().replaceAll(
                                        "Exception: ",
                                        "",
                                      ),
                                      color: Colors.red,
                                      icon: Icons.gpp_bad,
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
