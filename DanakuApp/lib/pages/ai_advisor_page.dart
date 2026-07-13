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
  String? _advice;
  String? _provider;
  String? _errorMessage;

  int _totalIncome = 0;
  int _totalExpense = 0;
  Map<String, int> _categoryBreakdown = {};

  @override
  void initState() {
    super.initState();
    _calculateFinancials();
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
      _advice = null;
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
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _advice = data['advice'];
          _provider = data['provider'];
          _isLoading = false;
        });
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
      ),
      body: SingleChildScrollView(
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
                      color: Colors.pink.withOpacity(0.2),
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

              // Tombol Trigger AI
              if (_advice == null && !_isLoading)
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.psychology_outlined),
                    label: const Text("Minta Analisis Keuangan AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Outfit')),
                    onPressed: _requestAdvice,
                  ),
                ),

              // Loading State (Thinking Animation)
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
                ),

              // Error State
              if (_errorMessage != null && !_isLoading)
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
                ),

              // Advice Hasil Analisis
              if (_advice != null && !_isLoading) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assistant_outlined, color: Colors.pink),
                              const SizedBox(width: 8),
                              const Text(
                                "Rekomendasi AI Advisor",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87, fontFamily: 'Outfit'),
                              ),
                            ],
                          ),
                          if (_provider != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Powered by $_provider",
                                style: TextStyle(fontSize: 9, color: Colors.pink.shade800, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      ..._parseMarkdownToWidgets(_advice!),
                      const SizedBox(height: 20),
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.pink),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.refresh, color: Colors.pink),
                          label: const Text("Analisis Ulang", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
                          onPressed: _requestAdvice,
                        ),
                      )
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
