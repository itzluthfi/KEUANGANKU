import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import '../widgets/custom_snackbar.dart';

class ManageRecurringPage extends StatefulWidget {
  const ManageRecurringPage({super.key});

  @override
  State<ManageRecurringPage> createState() => _ManageRecurringPageState();
}

class _ManageRecurringPageState extends State<ManageRecurringPage> {
  List<RecurringTransaction> _recurringList = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _expenseCategories = [];
  List<TransactionCategory> _incomeCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await DatabaseHelper.instance.fetchRecurringTransactions();
    final wallets = await DatabaseHelper.instance.fetchWallets();
    final expenseCats = await DatabaseHelper.instance.fetchCategories('keluar');
    final incomeCats = await DatabaseHelper.instance.fetchCategories('masuk');

    setState(() {
      _recurringList = list;
      _wallets = wallets;
      _expenseCategories = expenseCats;
      _incomeCategories = incomeCats;
      _isLoading = false;
    });
  }

  void _deleteRecurring(int id) async {
    await DatabaseHelper.instance.deleteRecurringTransaction(id);
    _loadData();
    if (mounted) {
      CustomSnackBar.show(context, message: "Transaksi rutin berhasil dihapus.");
    }
  }

  void _showAddRecurringSheet() {
    final keteranganController = TextEditingController();
    final jumlahController = TextEditingController();
    
    String selectedJenis = "keluar"; // keluar (Pengeluaran), masuk (Pemasukan)
    String? selectedWallet = _wallets.isNotEmpty ? _wallets.first.nama : null;
    String? selectedKategori;
    
    // Set default category
    if (selectedJenis == "keluar" && _expenseCategories.isNotEmpty) {
      selectedKategori = _expenseCategories.first.nama;
    } else if (selectedJenis == "masuk" && _incomeCategories.isNotEmpty) {
      selectedKategori = _incomeCategories.first.nama;
    }

    String selectedInterval = "bulanan"; // harian, mingguan, bulanan
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final activeCategories = selectedJenis == "keluar" ? _expenseCategories : _incomeCategories;
            
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 15),
                    const Text("Tambah Transaksi Rutin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    // Jenis Transaksi Toggle
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Pengeluaran")),
                            selected: selectedJenis == "keluar",
                            selectedColor: Colors.red.shade100,
                            checkmarkColor: Colors.red,
                            labelStyle: TextStyle(color: selectedJenis == "keluar" ? Colors.red.shade900 : Colors.black87, fontWeight: FontWeight.bold),
                            onSelected: (val) {
                              if (val) {
                                setSheetState(() {
                                  selectedJenis = "keluar";
                                  selectedKategori = _expenseCategories.isNotEmpty ? _expenseCategories.first.nama : null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Pemasukan")),
                            selected: selectedJenis == "masuk",
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green,
                            labelStyle: TextStyle(color: selectedJenis == "masuk" ? Colors.green.shade900 : Colors.black87, fontWeight: FontWeight.bold),
                            onSelected: (val) {
                              if (val) {
                                setSheetState(() {
                                  selectedJenis = "masuk";
                                  selectedKategori = _incomeCategories.isNotEmpty ? _incomeCategories.first.nama : null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Keterangan
                    TextField(
                      controller: keteranganController,
                      decoration: InputDecoration(
                        labelText: "Keterangan (misal: Tagihan Kos, Gajian)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Nominal
                    TextField(
                      controller: jumlahController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Nominal Jumlah (Rp)",
                        prefixText: "Rp ",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Dompet Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedWallet,
                      decoration: InputDecoration(
                        labelText: "Metode / Dompet",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _wallets.map((w) => DropdownMenuItem(value: w.nama, child: Text(w.nama))).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedWallet = val;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Kategori Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedKategori,
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: activeCategories.map((c) => DropdownMenuItem(value: c.nama, child: Text(c.nama))).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedKategori = val;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Interval & Start Date Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedInterval,
                            decoration: InputDecoration(
                              labelText: "Interval Rutin",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: "harian", child: Text("Harian")),
                              DropdownMenuItem(value: "mingguan", child: Text("Mingguan")),
                              DropdownMenuItem(value: "bulanan", child: Text("Bulanan")),
                            ],
                            onChanged: (val) {
                              setSheetState(() {
                                selectedInterval = val ?? "bulanan";
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Column(
                              children: [
                                const Text("Mulai Tanggal", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final nominal = int.tryParse(jumlahController.text.trim()) ?? 0;
                          final ket = keteranganController.text.trim();
                          
                          if (ket.isEmpty || nominal <= 0 || selectedWallet == null || selectedKategori == null) {
                            CustomSnackBar.show(context, message: "Lengkapi semua isian dengan benar.", isError: true);
                            return;
                          }

                          final newRecurring = RecurringTransaction(
                            bookId: AppData.activeBookId,
                            keterangan: ket,
                            jumlah: nominal,
                            jenis: selectedJenis,
                            kategori: selectedKategori!,
                            walletNama: selectedWallet!,
                            interval: selectedInterval,
                            nextDueDate: selectedDate,
                            isActive: true,
                          );

                          await DatabaseHelper.instance.insertRecurringTransaction(newRecurring);
                          if (context.mounted) Navigator.pop(context);
                          _loadData();
                        },
                        child: const Text("Jadwalkan Rutin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text("Transaksi Rutin (Berulang)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : _recurringList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.replay_circle_filled_rounded, size: 70, color: Colors.grey.shade400),
                      const SizedBox(height: 15),
                      const Text(
                        "Belum Ada Transaksi Rutin",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Jadwalkan tagihan bulanan atau pemasukan berkala Anda di sini, sistem akan mencatatnya otomatis saat jatuh tempo.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recurringList.length,
                  itemBuilder: (context, index) {
                    final item = _recurringList[index];
                    final isExpense = item.jenis == "keluar";
                    
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isExpense ? Colors.red.shade50 : Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isExpense ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded,
                            color: isExpense ? Colors.red : Colors.green,
                            size: 26,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(item.keterangan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                            Text(
                              "Rp${NumberFormat.decimalPattern('id').format(item.jumlah)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                                    child: Text(item.interval.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("Kategori: ${item.kategori} (${item.walletNama})", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Jatuh Tempo Berikutnya: ${DateFormat('dd MMMM yyyy', 'id').format(item.nextDueDate)}",
                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteRecurring(item.id!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink,
        onPressed: _showAddRecurringSheet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Rutin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
