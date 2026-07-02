import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_data.dart';
import '../widgets/transaksi_item.dart';
import 'add_transaksi_page.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  List<Transaksi> allTransaksi = [];
  List<Transaksi> filteredTransaksi = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Fungsi utama untuk sinkronisasi dengan Database
  Future<void> _loadAllData() async {
    setState(() => isLoading = true);

    // Mengambil data langsung dari SQLite agar akurat
    final data = await DatabaseHelper.instance.fetchTransaksi();

    if (mounted) {
      setState(() {
        // Data diurutkan dari yang terbaru (descending)
        allTransaksi = data.reversed.toList();
        filteredTransaksi = allTransaksi;

        // Sinkronisasi ke AppData (Variabel Global)
        AppData.transaksi = data;
        isLoading = false;
      });
    }
  }

  // Fungsi pencarian tetap sinkron dengan list utama
  void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTransaksi = allTransaksi;
      } else {
        filteredTransaksi = allTransaksi
            .where((t) => t.keterangan.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _handleExport() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String filePath = await ExportService.exportTransaksiToCSV();

      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([XFile(filePath)], text: "Laporan Keuangan Danaku (CSV)");
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal melakukan ekspor"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "Semua Transaksi",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.blueAccent),
            onPressed: _handleExport,
            tooltip: "Export CSV",
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: TextField(
              controller: searchController,
              onChanged: _filterSearch,
              decoration: InputDecoration(
                hintText: "Cari keterangan transaksi...",
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    _filterSearch("");
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F7F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredTransaksi.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTransaksi.length,
          itemBuilder: (context, index) {
            final t = filteredTransaksi[index];
            return TransaksiItem(
              transaksi: t,
              onTap: () {

              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          // Menunggu hasil push (true jika ada data baru disimpan)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransaksiPage()),
          );

          // Jika kembali dari AddTransaksiPage dan berhasil simpan, refresh data
          if (result == true) {
            _loadAllData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "Tidak ada riwayat transaksi",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 5),
          ElevatedButton(
              onPressed: _loadAllData,
              child: const Text("Refresh Data")
          )
        ],
      ),
    );
  }
}