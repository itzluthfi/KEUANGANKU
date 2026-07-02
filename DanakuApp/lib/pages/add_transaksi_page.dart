import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class AddTransaksiPage extends StatefulWidget {
  const AddTransaksiPage({super.key});

  @override
  State<AddTransaksiPage> createState() => _AddTransaksiPageState();
}

class _AddTransaksiPageState extends State<AddTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();

  String _selectedJenis = "Pengeluaran"; // Default
  final String _selectedWallet = "Utama"; // Default sesuai AppData
  String _selectedKategori = "Makanan"; // Default kategori
  DateTime _selectedDate = DateTime.now();

  final List<String> _kategoriList = [
    "Makanan", "Transportasi", "Hiburan", "Belanja", "Kesehatan", "Pendidikan", "Lainnya"
  ];

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveTransaksi() async {
    if (_formKey.currentState!.validate()) {
      final baru = Transaksi(
        keterangan: _keteranganController.text,
        jumlah: int.parse(_jumlahController.text),
        jenis: _selectedJenis,
        tanggal: _selectedDate,
        walletNama: _selectedWallet,
        kategori: _selectedKategori,
      );

      await DatabaseHelper.instance.insertTransaksi(baru);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaksi berhasil disimpan!")),
        );
        Navigator.pop(context, true); // Kembali dengan nilai true untuk refresh data
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Transaksi", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOGGLE JENIS TRANSAKSI ---
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Pengeluaran")),
                      selected: _selectedJenis == "Pengeluaran",
                      selectedColor: Colors.red[100],
                      onSelected: (val) => setState(() => _selectedJenis = "Pengeluaran"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Pemasukan")),
                      selected: _selectedJenis == "Pemasukan",
                      selectedColor: Colors.green[100],
                      onSelected: (val) => setState(() => _selectedJenis = "Pemasukan"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- INPUT JUMLAH ---
              TextFormField(
                controller: _jumlahController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Jumlah (Rp)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.money),
                ),
                validator: (val) => val == null || val.isEmpty ? "Masukkan jumlah" : null,
              ),
              const SizedBox(height: 15),

              // --- INPUT KETERANGAN ---
              TextFormField(
                controller: _keteranganController,
                decoration: InputDecoration(
                  labelText: "Keterangan",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
                validator: (val) => val == null || val.isEmpty ? "Masukkan keterangan" : null,
              ),
              const SizedBox(height: 15),

              // --- PILIH KATEGORI ---
              DropdownButtonFormField(
                value: _selectedKategori,
                decoration: InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _kategoriList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _selectedKategori = val as String),
              ),
              const SizedBox(height: 15),

              // --- PILIH TANGGAL ---
              ListTile(
                title: Text("Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}"),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: _presentDatePicker,
              ),
              const SizedBox(height: 30),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveTransaksi,
                  child: const Text("Simpan Transaksi", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}