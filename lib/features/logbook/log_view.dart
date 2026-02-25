import 'package:flutter/material.dart';
import 'package:logbook_app_001/core/app_colors.dart';
import 'package:logbook_app_001/features/logbook/widgets/log_item_widget.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import './models/log_model.dart';

class CounterView extends StatefulWidget {
  // Tambahkan variabel final untuk menampung nama
  final String username;

  // Update Constructor agar mewajibkan (required) kiriman nama
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final LogController _controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan username agar data terpisah per pengguna
    _controller = LogController(username: widget.username);
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Pribadi';

  // ── Helper: tampilkan SnackBar dengan warna & ikon berbeda ────────────────
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

  void _showAddLogDialog() {
    // Bersihkan input sebelum dialog dibuka agar tidak ada sisa teks
    _titleController.clear();
    _contentController.clear();
    _selectedCategory = 'Pribadi';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Tambah Catatan Baru"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: "Judul Catatan"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(hintText: "Isi Deskripsi"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(),
                ),
                items: Categories.categoryNames.map((category) {
                  final config = Categories.getCategory(category);
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(config.icon, color: config.color, size: 18),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setStateDialog(() {
                    _selectedCategory = newValue ?? 'Pribadi';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                // Jalankan fungsi tambah di Controller
                _controller.addLog(
                  _titleController.text,
                  _contentController.text,
                  _selectedCategory,
                );

                // Bersihkan input dan tutup dialog
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
                _showSnackBar(
                  "Catatan berhasil ditambahkan!",
                  color: AppColors.primaryDark,
                  icon: Icons.check_circle,
                );
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    _selectedCategory = log.category;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Edit Catatan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController),
              const SizedBox(height: 12),
              TextField(controller: _contentController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(),
                ),
                items: Categories.categoryNames.map((category) {
                  final config = Categories.getCategory(category);
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(config.icon, color: config.color, size: 18),
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setStateDialog(() {
                    _selectedCategory = newValue ?? log.category;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _controller.updateLog(
                  index,
                  _titleController.text,
                  _contentController.text,
                  _selectedCategory,
                );
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
                _showSnackBar(
                  "Catatan berhasil diperbarui!",
                  color: Colors.blue,
                  icon: Icons.edit,
                );
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text("LogBook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text(
                      "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingView(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Ya, Keluar",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
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

          // ── List Log ────────────────────────────────────────────────────
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, currentLogs, child) {
                if (currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/onboarding_1.png',
                          width: 220,
                          opacity: const AlwaysStoppedAnimation(0.7),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchController.text.isEmpty
                              ? "Belum ada catatan"
                              : "Tidak ada catatan yang cocok.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.hint,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    // cari index asli di logsNotifier untuk edit/delete
                    final realIndex = _controller.logsNotifier.value.indexOf(
                      log,
                    );
                    // Dapatkan konfigurasi kategori
                    final categoryConfig = Categories.getCategory(log.category);

                    return Card(
                      color: categoryConfig.cardColor,
                      child: ListTile(
                        leading: Icon(
                          categoryConfig.icon,
                          color: categoryConfig.color,
                        ),
                        title: Text(log.title),
                        subtitle: Text(log.description),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showEditLogDialog(realIndex, log),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _controller.removeLog(realIndex);
                                _controller.searchLog(_searchController.text);
                                _showSnackBar(
                                  "Catatan berhasil dihapus!",
                                  color: Colors.red,
                                  icon: Icons.delete,
                                );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        child: const Icon(Icons.add),
      ),
    );
  }
}
