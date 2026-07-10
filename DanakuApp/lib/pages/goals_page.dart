import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.fetchGoals();
    setState(() {
      _goals = data;
      _isLoading = false;
    });
  }

  void _showAddGoalDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime jatuhTempo = DateTime.now().add(const Duration(days: 90));

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
                  "Buat Target Tabungan Baru",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // Name input
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nama Target (misal: Beli Laptop)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Target Amount input
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Jumlah Target Dana (Rp)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Datepicker
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text("Target Selesai: ${DateFormat('dd MMM yyyy').format(jatuhTempo)}"),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: jatuhTempo,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => jatuhTempo = picked);
                      }
                    },
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
                      final targetVal = int.tryParse(targetController.text) ?? 0;
                      if (name.isNotEmpty && targetVal > 0) {
                        Navigator.pop(context);
                        await DatabaseHelper.instance.insertGoal({
                          'nama': name,
                          'target_jumlah': targetVal,
                          'terkumpul': 0,
                          'jatuh_tempo': jatuhTempo.toIso8601String(),
                          'status': 'aktif',
                        });
                        _loadData();
                      }
                    },
                    child: const Text("Buat Target", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showActionBottomSheet(Map<String, dynamic> goal) {
    final int id = goal['id'] as int;
    final int targetVal = goal['target_jumlah'] as int;
    final int terkumpul = goal['terkumpul'] as int;
    final String nama = goal['nama'] as String;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            "Terkumpul: Rp ${NumberFormat.decimalPattern('id').format(terkumpul)} / Rp ${NumberFormat.decimalPattern('id').format(targetVal)}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.teal),
            title: const Text("Setor Tabungan"),
            onTap: () {
              Navigator.pop(context);
              _showModifySavingsDialog(id, targetVal, terkumpul, true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.orange),
            title: const Text("Tarik Tabungan"),
            onTap: () {
              Navigator.pop(context);
              _showModifySavingsDialog(id, targetVal, terkumpul, false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
            title: const Text("Tandai Selesai / Tercapai"),
            onTap: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.updateGoalTerkumpul(id, targetVal, 'selesai');
              _loadData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Hapus Target", style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteGoal(id);
              _loadData();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showModifySavingsDialog(int id, int total, int currentCollected, bool isDeposit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isDeposit ? "Setor Tabungan" : "Tarik Tabungan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDeposit
                  ? "Sisa target: Rp ${NumberFormat.decimalPattern('id').format(total - currentCollected)}"
                  : "Tabungan saat ini: Rp ${NumberFormat.decimalPattern('id').format(currentCollected)}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal Dana (Rp)",
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
              final val = int.tryParse(controller.text) ?? 0;
              if (val > 0) {
                Navigator.pop(context);
                int newCollected = isDeposit ? (currentCollected + val) : (currentCollected - val);
                if (newCollected < 0) newCollected = 0;
                
                String status = 'aktif';
                if (newCollected >= total) {
                  newCollected = total;
                  status = 'selesai';
                }
                await DatabaseHelper.instance.updateGoalTerkumpul(id, newCollected, status);
                _loadData();
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
        title: const Text("Target Tabungan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF528F)))
          : _goals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.track_changes_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 14),
                        const Text(
                          "Belum ada target tabungan",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Buat target untuk membeli barang impian Anda!",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final g = _goals[index];
                    final id = g['id'] as int;
                    final nama = g['nama'] as String;
                    final targetVal = g['target_jumlah'] as int;
                    final terkumpul = g['terkumpul'] as int;
                    final status = g['status'] as String;
                    DateTime jatuhTempo = DateTime.parse(g['jatuh_tempo']);
                    
                    final double ratio = targetVal > 0 ? (terkumpul / targetVal) : 0.0;
                    final double progress = ratio > 1.0 ? 1.0 : ratio;
                    final isSelesai = status == 'selesai';
                    final isOverdue = !isSelesai && DateTime.now().isAfter(jatuhTempo);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showActionBottomSheet(g),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelesai ? Colors.green.shade50 : (isOverdue ? Colors.red.shade50 : Colors.blue.shade50),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isSelesai ? "TERCAPAI" : (isOverdue ? "TERLEWAT" : "AKTIF"),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelesai ? Colors.green : (isOverdue ? Colors.red : Colors.blue.shade800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Terkumpul: Rp ${NumberFormat.decimalPattern('id').format(terkumpul)}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelesai ? Colors.green : Colors.black87),
                                  ),
                                  Text(
                                    "Target: Rp ${NumberFormat.decimalPattern('id').format(targetVal)}",
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade100,
                                  color: isSelesai ? Colors.green : const Color(0xFFFF528F),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Tenggat: ${DateFormat('dd MMM yyyy').format(jatuhTempo)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    "${(ratio * 100).toInt()}%",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF528F),
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
