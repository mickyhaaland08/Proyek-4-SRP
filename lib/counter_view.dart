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
      backgroundColor: const Color.fromARGB(255, 6, 19, 18),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 128, 115),
        title: const Text("LogBook: The History Logger | Task 2"),
      ),
      body: Column( // Ubah Center menjadi Column agar bisa menampung banyak bagian
        children: [
          const SizedBox(height: 30),
          const Text("Total Hitungan:", style: TextStyle(
            fontSize: 16,
            color: const Color.fromARGB(255, 0, 128, 115),
          ),
          ),
            const SizedBox(height: 10),
          
          Text
            ('${_controller.value}', 
            style: const TextStyle(
              fontSize: 65,
              fontWeight: FontWeight.bold,
              fontFamily: 'poppins', 
              color: const Color.fromARGB(255, 0, 128, 115),
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
                labelStyle: TextStyle(color: Color.fromARGB(255, 0, 128, 115)),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(), // Garis pembatas
          const Text("Histori Aktivitas:", style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 128, 115))),

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
                  leading: const Icon(Icons.history, color: const Color.fromARGB(255, 0, 128, 115),),
                  title: Text(_controller.history[reversedIndex]),
                  textColor: const Color.fromARGB(255, 0, 128, 115),
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
      onPressed: () {
        int inputStep = int.tryParse(_stepController.text) ?? 1;
        setState(() {
          _controller.decrement(inputStep);
        });
      },
      heroTag: "btn_minus",
      child: const Icon(Icons.remove, color: Color.fromARGB(255, 0, 0, 0)),
      backgroundColor: const Color.fromARGB(255, 255, 85, 18),
    ),
    const SizedBox(width: 55),

    SizedBox(
          height: 70,
          width: 140,
          child: FloatingActionButton(
            onPressed: () {
              _showResetDialog(); // Panggil fungsi konfirmasi
            },
            heroTag: "btn_reset",
            child: const Text(
              "Reset",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 128, 115),
        ),
    ),
        const SizedBox(width: 55),

    // Tombol Tambah
    FloatingActionButton(
      onPressed: () {
        int inputStep = int.tryParse(_stepController.text) ?? 1;
        setState(() {
          _controller.increment(inputStep);
        });
      },
      heroTag: "btn_plus",
      child: const Icon(Icons.add, color: Color.fromARGB(255, 0, 0, 0)),
      backgroundColor: const Color.fromARGB(255, 26, 235, 43),
    ),
  ],
),
    );
  }
}



