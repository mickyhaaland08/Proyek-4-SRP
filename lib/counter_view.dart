import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepController = TextEditingController(text: "1");

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Reset"),
          content: const Text("Apakah Anda yakin ingin menghapus semua hitungan?"),
          actions: [
            // Tombol Batal
            TextButton(
              onPressed: () => Navigator.pop(context), // Menutup dialog
              child: const Text("Batal"),
            ),
            // Tombol Yakin
            TextButton(
              onPressed: () {
                setState(() {
                  _controller.reset();
                });
                Navigator.pop(context); // Menutup dialog setelah reset
              },
              child: const Text("Ya, Reset", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("LogBook: The History Logger | Task 2"),
      ),
      body: Column( // Ubah Center menjadi Column agar bisa menampung banyak bagian
        children: [
          const SizedBox(height: 30),
          const Text("Total Hitungan:"),
          Text
            ('${_controller.value}', 
            style: const TextStyle(
              fontSize: 65,
              fontWeight: FontWeight.bold,
              fontFamily: 'RobotoMono'
              ),
            ),

          const SizedBox(height: 20),

          // Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _stepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Masukkan nilai (Step)",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(), // Garis pembatas
          const Text("Histori Aktivitas:", style: TextStyle(fontWeight: FontWeight.bold)),

          // --- BAGIAN HISTORI REAL-TIME ---
          Expanded(
            child: ListView.builder(
              // MODIFIKASI 1: Batasi jumlah item maksimal 5
              // Jika history kurang dari 5, tampilkan jumlah yang ada. 
              // Jika lebih dari 5, kunci di angka 5.
              itemCount: _controller.history.length > 5 ? 5 : _controller.history.length,
              
              itemBuilder: (context, index) {
                // MODIFIKASI 2: Ambil data mulai dari yang paling baru
                // Rumus: (Total Data - 1) - index
                final reversedIndex = _controller.history.length - 1 - index;
                
                return ListTile(
                  leading: const Icon(Icons.history, color: Color.fromARGB(255, 0, 0, 0)),
                  title: Text(_controller.history[reversedIndex]),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Tombol Reset
    SizedBox(
      height: 50,
      width: 50,
      child: FloatingActionButton(
        onPressed: () {
          _showResetDialog(); // Panggil fungsi konfirmasi
        },
        heroTag: "btn_reset",
        child: const Icon(Icons.refresh),
    ),
    ),
    const SizedBox(width: 20),

    // Tombol Kurang
    FloatingActionButton(
      onPressed: () {
        int inputStep = int.tryParse(_stepController.text) ?? 1;
        setState(() {
          _controller.decrement(inputStep);
        });
      },
      heroTag: "btn_minus",
      child: const Icon(Icons.remove),
    ),

    const SizedBox(width: 20),

    // Tombol Tambah
    FloatingActionButton(
      onPressed: () {
        int inputStep = int.tryParse(_stepController.text) ?? 1;
        setState(() {
          _controller.increment(inputStep);
        });
      },
      heroTag: "btn_plus",
      child: const Icon(Icons.add),
    ),
  ],
),
    );
  }
}



