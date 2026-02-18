import 'package:flutter/material.dart';
import 'package:logbook_app_001/core/app_colors.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  // Tambahkan variabel final untuk menampung nama
  final String username;

  // Update Constructor agar mewajibkan (required) kiriman nama
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepController = TextEditingController(
    text: "1",
  );
  bool _isLoading = true;

  // ── Greeting berdasarkan jam login ─────────────────────────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) {
      return "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      return "Selamat Siang";
    } else if (hour >= 15 && hour < 19) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load data tersimpan dari SharedPreferences saat pertama kali dibuka
  Future<void> _loadSavedData() async {
    await _controller.loadData(widget.username); // load per username
    setState(() {
      _isLoading = false;
    });
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Reset"),
          content: const Text(
            "Apakah Anda yakin ingin menghapus semua hitungan?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                await _controller.reset(widget.username);
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text(
                "Ya, Reset",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading indicator sementara data diambil dari storage
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
      );
    }

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
          // ── Welcome Banner ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: AppColors.primaryDark.withOpacity(0.3),
            child: Text(
              "${_getGreeting()}, ${widget.username}!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            "Total Hitungan:",
            style: TextStyle(fontSize: 16, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 10),
          Text(
            '${_controller.value}',
            style: TextStyle(
              fontSize: 65,
              fontWeight: FontWeight.bold,
              fontFamily: 'poppins',
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 20),

          // Input Step
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _stepController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.primaryLight, fontSize: 16),
              decoration: InputDecoration(
                labelText: "Masukkan nilai (Step)",
                labelStyle: TextStyle(color: AppColors.primaryLight),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.primaryLight,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          Text(
            "Histori Aktivitas:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),

          // Histori — tampilkan 5 terbaru, terbalik
          Expanded(
            child: _controller.history.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada aktivitas.",
                      style: TextStyle(color: AppColors.primaryLight),
                    ),
                  )
                : ListView.builder(
                    itemCount: _controller.history.length > 5
                        ? 5
                        : _controller.history.length,
                    itemBuilder: (context, index) {
                      final reversedIndex =
                          _controller.history.length - 1 - index;
                      return ListTile(
                        leading: Icon(
                          Icons.history,
                          color: AppColors.primaryLight,
                        ),
                        title: Text(_controller.history[reversedIndex]),
                        textColor: AppColors.primaryLight,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tombol Kurang
          FloatingActionButton(
            onPressed: () async {
              int inputStep = int.tryParse(_stepController.text) ?? 1;
              await _controller.decrement(inputStep, widget.username);
              setState(() {});
            },
            heroTag: "btn_minus",
            backgroundColor: AppColors.danger,
            child: const Icon(Icons.remove, color: Colors.black),
          ),
          const SizedBox(width: 55),

          // Tombol Reset
          SizedBox(
            height: 70,
            width: 140,
            child: FloatingActionButton(
              onPressed: _showResetDialog,
              heroTag: "btn_reset",
              backgroundColor: AppColors.primaryDark,
              child: const Text(
                "Reset",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 55),

          // Tombol Tambah
          FloatingActionButton(
            onPressed: () async {
              int inputStep = int.tryParse(_stepController.text) ?? 1;
              await _controller.increment(inputStep, widget.username);
              setState(() {});
            },
            heroTag: "btn_plus",
            backgroundColor: AppColors.success,
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
