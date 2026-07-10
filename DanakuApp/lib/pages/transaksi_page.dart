import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../data/app_data.dart';
import '../widgets/transaksi_item.dart';
import 'add_transaksi_page.dart';
import 'transaction_input_page.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

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
                _showTransactionOptions(t);
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

  void _showTransactionOptions(Transaksi t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                
                if (t.itemsJson != null && t.itemsJson!.isNotEmpty) ...[
                  _buildModernOptionTile(
                    icon: Icons.receipt_long_rounded,
                    iconColor: Colors.pink,
                    title: "Lihat Rincian Item (Struk)",
                    subtitle: "Lihat rincian barang belanjaan detail",
                    onTap: () {
                      Navigator.pop(context);
                      _showReceiptDetailDialog(t);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _buildModernOptionTile(
                  icon: Icons.edit_rounded,
                  iconColor: Colors.blue,
                  title: "Edit Transaksi",
                  subtitle: "Ubah nominal, dompet, kategori, dll.",
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionInputPage(
                          initialJenis: t.jenis.toLowerCase() == 'masuk' ? 'masuk' : 'keluar',
                          initialTransaksi: t,
                        ),
                      ),
                    );
                    if (result == true) _loadAllData();
                  },
                ),
                const SizedBox(height: 12),
                _buildModernOptionTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  title: "Hapus Transaksi",
                  subtitle: "Hapus transaksi ini secara permanen",
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(t);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Transaksi t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Hapus Transaksi", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini akan mengembalikan dampak saldo pada dompet terkait.",
          style: TextStyle(height: 1.4, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteTransaksi(t);
              _loadAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Transaksi berhasil dihapus"),
                    action: SnackBarAction(
                      label: "URUNGKAN",
                      textColor: Colors.pink.shade100,
                      onPressed: () async {
                        await DatabaseHelper.instance.insertTransaksi(t);
                        _loadAllData();
                      },
                    ),
                    duration: const Duration(seconds: 5),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            }, 
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showReceiptDetailDialog(Transaksi t) {
    if (t.itemsJson == null || t.itemsJson!.isEmpty) return;
    
    List<dynamic> items = [];
    try {
      items = jsonDecode(t.itemsJson!);
    } catch (e) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Colors.pink, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        t.keterangan.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.8),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${t.kategori} • ${t.walletNama}",
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy, HH:mm').format(t.tanggal),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final String name = item['nama'] ?? 'Item';
                            final int qty = (item['qty'] ?? 1) as int;
                            final int harga = (item['harga'] ?? 0) as int;
                            final int singlePrice = qty > 0 ? (harga / qty).round() : harga;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                        const SizedBox(height: 2),
                                        Text("$qty x Rp${NumberFormat.decimalPattern('id').format(singlePrice)}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "Rp${NumberFormat.decimalPattern('id').format(harga)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          Text(
                            "Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}