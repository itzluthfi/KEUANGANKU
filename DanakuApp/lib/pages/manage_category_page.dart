import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class ManageCategoryPage extends StatefulWidget {
  final String jenis;
  const ManageCategoryPage({super.key, required this.jenis});

  @override
  State<ManageCategoryPage> createState() => _ManageCategoryPageState();
}

class _ManageCategoryPageState extends State<ManageCategoryPage> {
  List<TransactionCategory> categories = [];
  final TextEditingController _nameController = TextEditingController();
  IconData _selectedIcon = Icons.category_rounded;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await DatabaseHelper.instance.fetchCategories(widget.jenis);
    setState(() {
      categories = list;
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Kategori"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Kategori"),
            ),
            const SizedBox(height: 20),
            const Text("Pilih Ikon:"),
            Wrap(
              spacing: 10,
              children: [
                Icons.fastfood_rounded,
                Icons.shopping_bag_rounded,
                Icons.directions_car_rounded,
                Icons.movie_rounded,
                Icons.work_rounded,
                Icons.home_rounded,
              ].map((icon) => IconButton(
                icon: Icon(icon, color: _selectedIcon == icon ? Colors.pink : Colors.grey),
                onPressed: () => setState(() => _selectedIcon = icon),
              )).toList(),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                final newCat = TransactionCategory(nama: _nameController.text, icon: _selectedIcon);
                await DatabaseHelper.instance.insertCategory(newCat, widget.jenis);
                _nameController.clear();
                if (mounted) Navigator.pop(context);
                _loadCategories();
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kelola Kategori (${widget.jenis == 'keluar' ? 'Pengeluaran' : 'Pemasukan'})"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(cat.icon, color: Colors.pink),
            ),
            title: Text(cat.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                if (cat.id != null) {
                  await DatabaseHelper.instance.deleteCategory(cat.id!);
                  _loadCategories();
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
