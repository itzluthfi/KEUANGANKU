import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import '../widgets/custom_snackbar.dart';

class CategoryBudgetPage extends StatefulWidget {
  const CategoryBudgetPage({super.key});

  @override
  State<CategoryBudgetPage> createState() => _CategoryBudgetPageState();
}

class _CategoryBudgetPageState extends State<CategoryBudgetPage> {
  List<TransactionCategory> _categories = [];
  List<Map<String, dynamic>> _budgets = [];
  List<Transaksi> _allTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await DatabaseHelper.instance.fetchCategories('keluar');
    final bdg = await DatabaseHelper.instance.fetchCategoryBudgets();
    final trs = await DatabaseHelper.instance.fetchTransaksi();
    
    setState(() {
      _categories = cats;
      _budgets = bdg;
      _allTransactions = trs;
      _isLoading = false;
    });
  }

  int _getLimit(String categoryName) {
    final match = _budgets.firstWhere(
      (b) => b['kategori'].toString().toLowerCase() == categoryName.toLowerCase(),
      orElse: () => {},
    );
    return match.isNotEmpty ? (match['limit_jumlah'] as int) : 0;
  }

  int _getSpent(String categoryName) {
    final now = DateTime.now();
    return _allTransactions
        .where((t) =>
            t.kategori.toLowerCase() == categoryName.toLowerCase() &&
            t.tanggal.month == now.month &&
            t.tanggal.year == now.year &&
            (t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran'))
        .fold(0, (sum, t) => sum + t.jumlah);
  }

  void _showSetBudgetDialog(TransactionCategory cat, int currentLimit) {
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toString() : "",
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Set Anggaran: ${cat.nama}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Masukkan batas anggaran bulanan untuk kategori ini:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Contoh: 500000",
                prefixText: "Rp ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          if (currentLimit > 0)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await DatabaseHelper.instance.deleteCategoryBudget(cat.nama);
                _loadData();
                if (mounted) {
                  CustomSnackBar.show(context, message: "Anggaran ${cat.nama} berhasil dihapus");
                }
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF528F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final val = int.tryParse(controller.text) ?? 0;
              if (val > 0) {
                Navigator.pop(context);
                await DatabaseHelper.instance.saveCategoryBudget(cat.nama, val);
                _loadData();
                if (mounted) {
                  CustomSnackBar.show(context, message: "Anggaran ${cat.nama} berhasil diatur!", isSuccess: true);
                }
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Anggaran Per Kategori", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF528F)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final limit = _getLimit(cat.nama);
                final spent = _getSpent(cat.nama);
                
                final double ratio = limit > 0 ? (spent / limit) : 0.0;
                final double progressVal = ratio > 1.0 ? 1.0 : ratio;
                final bool isOver = limit > 0 && spent > limit;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showSetBudgetDialog(cat, limit),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cat.icon ?? Icons.category,
                                  color: const Color(0xFFFF528F),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.nama,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      limit > 0
                                          ? "Batas: Rp ${NumberFormat.decimalPattern('id').format(limit)}"
                                          : "Anggaran belum diatur",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: limit > 0 ? Colors.grey.shade600 : Colors.grey.shade400,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (limit > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Terpakai: Rp ${NumberFormat.decimalPattern('id').format(spent)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isOver ? Colors.red : Colors.teal.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${(ratio * 100).toInt()}%",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isOver ? Colors.red : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (limit > 0) ...[
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressVal,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade100,
                                color: isOver ? Colors.redAccent : Colors.teal,
                              ),
                            ),
                            if (isOver) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: const [
                                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "Limit terlampaui!",
                                    style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
