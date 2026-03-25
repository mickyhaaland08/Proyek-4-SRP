import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/core/app_colors.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log; // Null = mode tambah, ada isi = mode edit
  final int? index; // Index untuk update
  final LogController controller;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  // Toggle antara mode Edit dan Preview
  bool _isPreviewMode = false;
  String _selectedCategory = 'Mechanical';

  static const List<String> _categories = [
    'Mechanical',
    'Electronic',
    'Software',
  ];

  bool get _isEditMode => widget.log != null && widget.index != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );

    // Set kategori dari log yang sedang diedit
    if (widget.log != null && _categories.contains(widget.log!.category)) {
      _selectedCategory = widget.log!.category;
    }

    _descController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Simpan log (tambah atau update)
  Future<void> _saveLog() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Judul tidak boleh kosong!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (_isEditMode) {
        await widget.controller.updateLog(
          widget.index!,
          title,
          desc,
          _selectedCategory,
        );
      } else {
        await widget.controller.addLog(title, desc, _selectedCategory);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? "Catatan berhasil diperbarui!"
                  : "Catatan berhasil ditambahkan!",
            ),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: Text(_isEditMode ? "Edit Catatan" : "Catatan Baru"),
        actions: [
          IconButton(
            tooltip: _isPreviewMode ? "Mode Edit" : "Pratinjau Markdown",
            icon: Icon(
              _isPreviewMode ? Icons.edit : Icons.preview,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
          ),
          IconButton(
            tooltip: "Simpan",
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveLog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input Judul ────────────────────────────────────────────────
            TextField(
              controller: _titleController,
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Judul Catatan...",
                hintStyle: const TextStyle(color: AppColors.hint),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: AppColors.hint),
            const SizedBox(height: 8),

            // ── Dropdown Kategori ──────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.label_outline, size: 16, color: AppColors.hint),
                const SizedBox(width: 6),
                const Text(
                  "Kategori:",
                  style: TextStyle(color: AppColors.hint, fontSize: 12),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.background,
                  style: TextStyle(color: AppColors.primaryLight, fontSize: 13),
                  underline: const SizedBox.shrink(),
                  items: _categories.map((cat) {
                    final color = _categoryColor(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isPreviewMode ? Icons.visibility : Icons.edit_note,
                  size: 16,
                  color: AppColors.hint,
                ),
                const SizedBox(width: 6),
                Text(
                  _isPreviewMode ? "Pratinjau Markdown" : "Mode Menulis",
                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Area Edit / Preview ────────────────────────────────────────
            Expanded(child: _isPreviewMode ? _buildPreview() : _buildEditor()),
          ],
        ),
      ),
    );
  }

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

  Widget _buildEditor() {
    return TextField(
      controller: _descController,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(color: AppColors.primaryLight, height: 1.6),
      decoration: InputDecoration(
        hintText:
            "Tulis catatan di sini...\n\n"
            "Contoh Markdown:\n"
            "# Judul Besar\n"
            "**Tebal** | *Miring*\n"
            "- Item list",
        hintStyle: const TextStyle(color: AppColors.hint),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildPreview() {
    final text = _descController.text;
    if (text.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada konten untuk ditampilkan.",
          style: TextStyle(color: AppColors.hint),
        ),
      );
    }
    return Markdown(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: AppColors.primaryLight, height: 1.6),
        h1: TextStyle(
          color: AppColors.primaryLight,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: AppColors.primaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        code: TextStyle(
          backgroundColor: AppColors.primaryDark,
          color: Colors.greenAccent,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
