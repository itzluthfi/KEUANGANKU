import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchDebts();
    setState(() {
      _debts = data;
      _isLoading = false;
    });
  }

  void _showAddDebtDialog() {
    String tipe = "utang"; // default
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime tanggal = DateTime.now();
    DateTime jatuhTempo = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tambah Catatan Utang / Piutang",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                
                // Toggle Tipe
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Utang Saya")),
                        selected: tipe == "utang",
                        selectedColor: Colors.pink.shade100,
                        checkmarkColor: Colors.pink,
                        onSelected: (val) {
                          if (val) setModalState(() => tipe = "utang");
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Piutang (Orang Berutang)")),
                        selected: tipe == "piutang",
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green,
                        onSelected: (val) {
                          if (val) setModalState(() => tipe = "piutang");
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name input
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nama Kontak / Orang",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount input
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Jumlah Nominal (Rp)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Datepickers
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tanggal,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => tanggal = picked);
                          }
                        },
                        child: Text("Tanggal: ${DateFormat('d/M/yyyy').format(tanggal)}", style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: jatuhTempo,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => jatuhTempo = picked);
                          }
                        },
                        child: Text("Jatuh Tempo: ${DateFormat('d/M/yyyy').format(jatuhTempo)}", style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: "Keterangan (Opsional)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF528F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final amount = int.tryParse(amountController.text) ?? 0;
                      if (name.isNotEmpty && amount > 0) {
                        Navigator.pop(context);
                        await DatabaseHelper.instance.insertDebt({
                          'tipe': tipe,
                          'kontak': name,
                          'keterangan': descController.text.trim(),
                          'jumlah': amount,
                          'terbayar': 0,
                          'tanggal': tanggal.toIso8601String(),
                          'jatuh_tempo': jatuhTempo.toIso8601String(),
                          'status': 'belum_lunas',
                        });
                        _loadData();
                      }
                    },
                    child: const Text("Simpan Catatan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionBottomSheet(Map<String, dynamic> debt) {
    final int id = debt['id'] as int;
    final int jumlah = debt['jumlah'] as int;
    final int terbayar = debt['terbayar'] as int;
    final String kontak = debt['kontak'] as String;
    final String tipe = debt['tipe'] as String;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(kontak, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            "Tersisa: Rp ${NumberFormat.decimalPattern('id').format(jumlah - terbayar)}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.teal),
            title: const Text("Bayar Sebagian (Cicilan)"),
            onTap: () {
              Navigator.pop(context);
              _showPayInstallmentDialog(id, jumlah, terbayar);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
            title: const Text("Tandai Lunas"),
            onTap: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.updateDebtPayback(id, jumlah, 'lunas');
              _loadData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Hapus Catatan", style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteDebt(id);
              _loadData();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showPayInstallmentDialog(int id, int total, int currentPaid) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Catat Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sisa utang: Rp ${NumberFormat.decimalPattern('id').format(total - currentPaid)}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal Pembayaran (Rp)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
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
              final paidVal = int.tryParse(controller.text) ?? 0;
              if (paidVal > 0) {
                Navigator.pop(context);
                int newPaid = currentPaid + paidVal;
                String status = 'belum_lunas';
                if (newPaid >= total) {
                  newPaid = total;
                  status = 'lunas';
                }
                await DatabaseHelper.instance.updateDebtPayback(id, newPaid, status);
                _loadData();
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String activeType) {
    final filtered = _debts.where((d) => d['tipe'] == activeType).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 14),
              Text(
                "Tidak ada catatan ${activeType == 'utang' ? 'utang' : 'piutang'}",
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final d = filtered[index];
        final id = d['id'] as int;
        final kontak = d['kontak'] as String;
        final keterangan = d['keterangan'] as String;
        final jumlah = d['jumlah'] as int;
        final terbayar = d['terbayar'] as int;
        final status = d['status'] as String;
        
        DateTime tanggal = DateTime.parse(d['tanggal']);
        DateTime jatuhTempo = DateTime.parse(d['jatuh_tempo']);
        final isLunas = status == 'lunas';
        final isOverdue = !isLunas && DateTime.now().isAfter(jatuhTempo);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLunas ? null : () => _showActionBottomSheet(d),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(kontak, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLunas ? Colors.green.shade50 : (isOverdue ? Colors.red.shade50 : Colors.orange.shade50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLunas ? "LUNAS" : (isOverdue ? "TERLEWAT" : "BELUM LUNAS"),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isLunas ? Colors.green : (isOverdue ? Colors.red : Colors.orange.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (keterangan.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(keterangan, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Tanggal Pinjam", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(DateFormat('dd MMM yyyy').format(tanggal), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Jatuh Tempo", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(
                            DateFormat('dd MMM yyyy').format(jatuhTempo),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                              color: isOverdue ? Colors.red : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Sisa Saldo", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(
                            "Rp ${NumberFormat.decimalPattern('id').format(jumlah - terbayar)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isLunas) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: jumlah > 0 ? (terbayar / jumlah) : 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade100,
                        color: activeType == 'utang' ? Colors.pinkAccent : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Terbayar: Rp ${NumberFormat.decimalPattern('id').format(terbayar)} / Rp ${NumberFormat.decimalPattern('id').format(jumlah)}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
        title: const Text("Utang / Piutang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Utang Saya"),
            Tab(text: "Piutang"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF528F)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList("utang"),
                _buildList("piutang"),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF528F),
        onPressed: _showAddDebtDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
