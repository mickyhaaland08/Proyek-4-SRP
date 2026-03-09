import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/core/app_colors.dart';
import 'package:logbook_app_001/features/logbook/widgets/log_item_widget.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import './models/log_model.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView>
    with SingleTickerProviderStateMixin {
  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Pribadi';

  // ── FutureBuilder state ──────────────────────────────────────────────────
  late Future<List<LogModel>> _logsFuture;

  // ── Connection Guard state ───────────────────────────────────────────────
  bool _isOffline = false;
  String _offlineMessage = '';

  // ── Shimmer animation ────────────────────────────────────────────────────
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer controller – loop terus-menerus selama loading
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Load awal: koneksi ke Atlas → fetch data
    _logsFuture = _fetchFromCloud();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Fetch data dari Cloud (dipakai FutureBuilder & refresh) ───────────────
  Future<List<LogModel>> _fetchFromCloud() async {
    // Reset offline state setiap kali fetch baru dimulai
    if (mounted) setState(() => _isOffline = false);

    await LogHelper.writeLog(
      "UI: Mulai fetch data dari Cloud...",
      source: "log_view.dart",
    );
    try {
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw const SocketException("Koneksi timeout setelah 15 detik."),
      );
      final data = await MongoService().getLogs();
      _controller.logsNotifier.value = data;
      _controller.filteredLogs.value = data;
      await LogHelper.writeLog(
        "UI: ${data.length} data berhasil dimuat.",
        source: "log_view.dart",
        level: 2,
      );
      return data;
    } on SocketException catch (e) {
      // Tidak ada koneksi internet atau host tidak terjangkau
      final msg =
          'Tidak ada koneksi internet.\nPastikan WiFi/data aktif dan coba lagi.';
      if (mounted) {
        setState(() {
          _isOffline = true;
          _offlineMessage = msg;
        });
      }
      await LogHelper.writeLog(
        "UI: Offline — SocketException: $e",
        source: "log_view.dart",
        level: 1,
      );
      throw Exception(msg);
    } catch (e) {
      // Error lain (auth, timeout, dsb.)
      final isTimeout =
          e.toString().contains('Timeout') || e.toString().contains('timeout');
      final msg = isTimeout
          ? 'Koneksi ke server timeout.\nCek sinyal HP atau IP Whitelist Atlas.'
          : 'Gagal terhubung ke server:\n$e';
      if (mounted) {
        setState(() {
          _isOffline = true;
          _offlineMessage = msg;
        });
      }
      await LogHelper.writeLog(
        "UI: Error - $e",
        source: "log_view.dart",
        level: 1,
      );
      throw Exception(msg);
    }
  }

  // ── Trigger refresh: buat Future baru → FutureBuilder rebuild ─────────────
  Future<void> _refreshLogs() async {
    setState(() {
      _searchController.clear();
      _logsFuture = _fetchFromCloud();
    });
    // Tunggu future selesai agar RefreshIndicator mati setelah data masuk
    await _logsFuture.catchError((_) => <LogModel>[]);
  }

  // ── SnackBar helper ────────────────────────────────────────────────────────
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

  // ── Dialog Tambah ──────────────────────────────────────────────────────────
  void _showAddLogDialog() {
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
                onChanged: (v) =>
                    setStateDialog(() => _selectedCategory = v ?? 'Pribadi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _controller.addLog(
                  _titleController.text,
                  _contentController.text,
                  _selectedCategory,
                );
                _titleController.clear();
                _contentController.clear();
                // Auto-refresh: fetch ulang dari Cloud
                _refreshLogs();
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

  // ── Dialog Edit ────────────────────────────────────────────────────────────
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
                onChanged: (v) =>
                    setStateDialog(() => _selectedCategory = v ?? log.category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _controller.updateLog(
                  index,
                  _titleController.text,
                  _contentController.text,
                  _selectedCategory,
                );
                _titleController.clear();
                _contentController.clear();
                // Auto-refresh
                _refreshLogs();
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

  // ── Shimmer Widget ─────────────────────────────────────────────────────────
  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value + 1, 0),
              colors: const [
                Color(0xFF2A2A2A),
                Color(0xFF3D3D3D),
                Color(0xFF2A2A2A),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Column(children: List.generate(5, (_) => _buildShimmerCard()));
  }

  // ── Build utama ────────────────────────────────────────────────────────────
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
            tooltip: "Logout",
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text(
                    "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingView(),
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
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Offline Mode Warning Banner ──────────────────────────────────
          if (_isOffline)
            Material(
              elevation: 2,
              child: Container(
                width: double.infinity,
                color: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _offlineMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshLogs,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Search Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.primaryLight),
              onChanged: (query) {
                // Filter lokal dari data yang sudah di-fetch
                _controller.searchLog(query);
                setState(() {}); // rebuild agar ValueListenable ikut update
              },
              decoration: InputDecoration(
                hintText: "Cari catatan...",
                hintStyle: const TextStyle(color: AppColors.hint),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryDark),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: Icon(Icons.clear, color: AppColors.disabled),
                          onPressed: () {
                            _searchController.clear();
                            _controller.searchLog('');
                            setState(() {});
                          },
                        ),
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

          // ── FutureBuilder: Loading / Error / Data ────────────────────────
          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                // ── LOADING → Shimmer ─────────────────────────────────────
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildShimmerList(),
                      const SizedBox(height: 24),
                      const Text(
                        "Menghubungkan ke Cloud...",
                        style: TextStyle(color: AppColors.hint, fontSize: 13),
                      ),
                    ],
                  );
                }

                // ── ERROR ─────────────────────────────────────────────────
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            color: Colors.redAccent,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Gagal memuat data:\n${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.hint,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _refreshLogs,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Coba Lagi"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ── DATA BERHASIL → pakai filteredLogs untuk search ───────
                return ValueListenableBuilder<List<LogModel>>(
                  valueListenable: _controller.filteredLogs,
                  builder: (context, currentLogs, _) {
                    // ── EMPTY STATE ───────────────────────────────────────
                    if (currentLogs.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refreshLogs,
                        color: AppColors.primary,
                        backgroundColor: AppColors.background,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
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
                                        ? "Belum ada catatan.\nTambahkan catatan pertamamu!"
                                        : "Tidak ada catatan yang cocok.",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.hint,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    // ── LIST CATATAN ──────────────────────────────────────
                    return RefreshIndicator(
                      onRefresh: _refreshLogs,
                      color: AppColors.primary,
                      backgroundColor: AppColors.background,
                      child: ListView.builder(
                        // physics wajib agar RefreshIndicator bisa dipicu
                        // meski list pendek
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: currentLogs.length,
                        itemBuilder: (context, index) {
                          final log = currentLogs[index];
                          final realIndex = _controller.logsNotifier.value
                              .indexOf(log);
                          final categoryConfig = Categories.getCategory(
                            log.category,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            color: categoryConfig.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: categoryConfig.color.withAlpha(
                                  30,
                                ),
                                child: Icon(
                                  categoryConfig.icon,
                                  color: categoryConfig.color,
                                ),
                              ),
                              title: Text(
                                log.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              // ✅ Timestamp: "2 menit yang lalu" / "25 Jan 2026"
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (log.description.isNotEmpty)
                                    Text(
                                      log.description,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 11,
                                        color: Colors.black38,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        log.timeAgo,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: log.description.isNotEmpty,
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _showEditLogDialog(realIndex, log),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await _controller.removeLog(realIndex);
                                      _refreshLogs();
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
