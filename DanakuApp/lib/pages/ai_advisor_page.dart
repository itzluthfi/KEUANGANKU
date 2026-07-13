import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/app_data.dart';
import '../services/sync_service.dart';
import '../widgets/custom_snackbar.dart';

class AiAdvisorPage extends StatefulWidget {
  const AiAdvisorPage({super.key});

  @override
  State<AiAdvisorPage> createState() => _AiAdvisorPageState();
}

class _AiAdvisorPageState extends State<AiAdvisorPage> {
  bool _isLoading = false;
  String? _errorMessage;

  int _totalIncome = 0;
  int _totalExpense = 0;
  Map<String, int> _categoryBreakdown = {};

  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateFinancials();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final hist = await DatabaseHelper.instance.fetchAiAdviceHistory();
    setState(() {
      _history = hist;
      _historyLoading = false;
    });
  }

  Future<void> _deleteHistoryItem(int id) async {
    await DatabaseHelper.instance.database.then((db) async {
      await db.delete('ai_chat_history', where: 'id = ?', whereArgs: [id]);
    });
    await _loadHistory();
    if (mounted) {
      CustomSnackBar.show(context, message: "Riwayat analisis berhasil dihapus", isSuccess: true);
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Semua Riwayat?", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        content: const Text("Tindakan ini akan menghapus seluruh catatan nasihat finansial AI Anda secara permanen.", style: TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus Semua", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.clearAiAdviceHistory();
      await _loadHistory();
    }
  }

  Future<void> _calculateFinancials() async {
    final now = DateTime.now();
    final allTx = await DatabaseHelper.instance.fetchTransaksi();
    
    int income = 0;
    int expense = 0;
    Map<String, int> breakdown = {};

    for (var tx in allTx) {
      if (tx.tanggal.month == now.month && tx.tanggal.year == now.year) {
        if (tx.jenis.toLowerCase() == 'masuk' || tx.jenis.toLowerCase() == 'pemasukan') {
          income += tx.jumlah;
        } else {
          expense += tx.jumlah;
          breakdown[tx.kategori] = (breakdown[tx.kategori] ?? 0) + tx.jumlah;
        }
      }
    }

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
      _categoryBreakdown = breakdown;
    });
  }

  Future<void> _requestAdvice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await DatabaseHelper.instance.getSetting('auth_token');
      if (token == null || token.isEmpty) {
        throw Exception("Silakan login atau cadangkan data terlebih dahulu untuk menggunakan AI Advisor.");
      }

      final payload = {
        'total_pemasukan': _totalIncome,
        'total_pengeluaran': _totalExpense,
        'kategori_breakdown': _categoryBreakdown,
      };

      final response = await http.post(
        Uri.parse('${SyncService.instance.laravelBaseUrl}/ai/advise'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final advice = data['advice'];
        final provider = data['provider'] ?? 'AI';

        // Simpan ke SQLite
        await DatabaseHelper.instance.insertAiAdvice(
          advice,
          provider,
          _totalIncome,
          _totalExpense,
        );

        // Muat ulang riwayat
        await _loadHistory();

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          CustomSnackBar.show(context, message: "Analisis keuangan AI berhasil dibuat!", isSuccess: true);
        }
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? "Gagal menghubungi AI Advisor. Kode Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(context, message: _errorMessage!, isError: true);
      }
    }
  }

  List<Widget> _parseMarkdownToWidgets(String text) {
    List<Widget> widgets = [];
    final lines = text.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      if (line.startsWith('###')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            line.replaceFirst('###', '').trim(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.pink, fontFamily: 'Outfit'),
          ),
        ));
      } else if (line.startsWith('##')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            line.replaceFirst('##', '').trim(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.pinkAccent, fontFamily: 'Outfit'),
          ),
        ));
      } else if (line.startsWith('#')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
          child: Text(
            line.replaceFirst('#', '').trim(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87, fontFamily: 'Outfit'),
          ),
        ));
      } else if (line.startsWith('-') || line.startsWith('*')) {
        final cleanText = line.substring(1).trim();
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6.0, right: 8.0),
                child: Icon(Icons.circle, size: 6, color: Colors.pink),
              ),
              Expanded(
                child: Text(
                  cleanText.replaceAll('**', ''),
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87, fontFamily: 'Outfit'),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            line.replaceAll('**', ''),
            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87, fontFamily: 'Outfit'),
          ),
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final netSavings = _totalIncome - _totalExpense;
    final formattedIncome = NumberFormat.decimalPattern('id').format(_totalIncome);
    final formattedExpense = NumberFormat.decimalPattern('id').format(_totalExpense);
    final formattedSavings = NumberFormat.decimalPattern('id').format(netSavings);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("AI Financial Advisor", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          if (_history.isNotEmpty && !_historyLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: "Hapus Semua Riwayat",
              onPressed: _clearAllHistory,
            )
        ],
      ),
      body: _historyLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ringkasan Finansial Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade400, Colors.pink.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Ringkasan Keuangan Bulan Ini",
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Pemasukan", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Outfit')),
                                  Text("Rp$formattedIncome", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Pengeluaran", style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Outfit')),
                                  Text("Rp$formattedExpense", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                                ],
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tabungan Bersih",
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                              ),
                              Text(
                                "${netSavings >= 0 ? '+' : ''} Rp$formattedSavings",
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Trigger/Analisis State Card
                    if (_isLoading)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: Colors.pink),
                            const SizedBox(height: 20),
                            const Text(
                              "Danaku AI Advisor sedang menganalisis...",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87, fontFamily: 'Outfit'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Kami sedang meninjau pengeluaran bulanan Anda untuk merumuskan saran penghematan terbaik.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4, fontFamily: 'Outfit'),
                            ),
                          ],
                        ),
                      )
                    else if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: _requestAdvice,
                              child: const Text("Coba Lagi"),
                            )
                          ],
                        ),
                      )
                    else
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 3,
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("Buat Analisis Keuangan Baru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit')),
                          onPressed: _requestAdvice,
                        ),
                      ),

                    const SizedBox(height: 30),
                    const Text(
                      "Riwayat Nasihat Keuangan AI",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87, fontFamily: 'Outfit'),
                    ),
                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.assistant_rounded, size: 50, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                "Belum ada riwayat analisis.\nSilakan ketuk tombol di atas untuk membuat analisis baru.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4, fontFamily: 'Outfit'),
                              )
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final id = item['id'] as int;
                          final adviceText = item['advice_text'] as String;
                          final providerName = item['provider'] as String? ?? 'AI';
                          final inc = item['total_income'] as int? ?? 0;
                          final exp = item['total_expense'] as int? ?? 0;
                          final savings = inc - exp;
                          final dateRaw = item['created_at'] as String;
                          
                          DateTime? dateParsed;
                          try {
                            dateParsed = DateTime.parse(dateRaw);
                          } catch (_) {}
                          
                          final dateFormatted = dateParsed != null 
                              ? DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id').format(dateParsed)
                              : dateRaw;

                          final incFormatted = NumberFormat.decimalPattern('id').format(inc);
                          final expFormatted = NumberFormat.decimalPattern('id').format(exp);
                          final savFormatted = NumberFormat.decimalPattern('id').format(savings);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.pinkAccent,
                                  radius: 18,
                                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                ),
                                title: Text(
                                  dateFormatted,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, fontFamily: 'Outfit'),
                                ),
                                subtitle: Text(
                                  "In: Rp$incFormatted | Out: Rp$expFormatted | Sav: Rp$savFormatted",
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'Outfit'),
                                ),
                                childrenPadding: const EdgeInsets.all(20),
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.pink.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Powered by $providerName",
                                          style: TextStyle(fontSize: 9, color: Colors.pink.shade800, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        onPressed: () => _deleteHistoryItem(id),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  ..._parseMarkdownToWidgets(adviceText),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
