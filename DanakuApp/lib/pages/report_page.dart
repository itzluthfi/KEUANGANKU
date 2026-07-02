import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;
import 'dart:ui' as ui;
import '../data/app_data.dart';
import '../data/database_helper.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _viewMode = 0; // 0: Pengeluaran, 1: Penghasilan, 2: Kategori, 3: Akun, 4: Tren/Aset
  bool _isTrendMode = true; // true: Tren, false: Aset
  final String _groupBy = "Kategori"; // "Kategori" or "Akun"
  DateTime _selectedMonth = DateTime.now();
  List<Transaksi> _transactions = [];
  List<Wallet> _wallets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final all = await DatabaseHelper.instance.fetchTransaksi();
    final allWallets = await DatabaseHelper.instance.fetchWallets();
    setState(() {
      _transactions = all.where((t) => t.tanggal.month == _selectedMonth.month && t.tanggal.year == _selectedMonth.year).toList();
      _wallets = allWallets;
    });
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _loadData();
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _loadData();
    });
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) {
        int tempYear = _selectedMonth.year;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Pilih Bulan & Tahun", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setDialogState(() {
                            tempYear--;
                          });
                        },
                      ),
                      Text("$tempYear", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setDialogState(() {
                            tempYear++;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final monthNum = index + 1;
                      final isSelected = _selectedMonth.month == monthNum && _selectedMonth.year == tempYear;
                      final monthName = [
                        "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", 
                        "Jul", "Agt", "Sep", "Okt", "Nov", "Des"
                      ][index];
                      return ChoiceChip(
                        label: Text(monthName),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF528F),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedMonth = DateTime(tempYear, monthNum);
                              _loadData();
                            });
                            Navigator.pop(context);
                          }
                        },
                      );
                    }),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        leading: const Icon(Icons.menu_book, color: Colors.white),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Analisis", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _prevMonth,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Icon(Icons.chevron_left, color: Colors.white, size: 20),
              ),
            ),
            GestureDetector(
              onTap: _showMonthPicker,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(DateFormat('M/yyyy').format(_selectedMonth), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
            GestureDetector(
              onTap: _nextMonth,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // View Mode Toggle Bar - Full Width Background
          Container(
            color: const Color(0xFFFF528F),
            width: double.infinity,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15, left: 10, right: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildModeIcon(0, Icons.shopping_cart, "Keluar"),
                        _buildModeIcon(1, Icons.savings, "Masuk"),
                        _buildModeIcon(2, Icons.fact_check, "Kategori"),
                        _buildModeIcon(3, Icons.account_balance, "Akun"),
                        _buildModeIcon(4, Icons.account_balance_wallet, "Aset"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildSubToggle(),
                      const SizedBox(height: 20),
                      _buildMainContent(screenSize),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(int index, IconData icon, String label) {
    bool isActive = _viewMode == index;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.pink : Colors.white, size: 18),
            if (isActive) ...[
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 11)),
            ]
          ],
        ),
      ),
    );
  }
  Widget _buildSubToggle() {
    if (_viewMode >= 4) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Oleh $_groupBy", style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 11)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.pink, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(Size screenSize) {

    if (_viewMode == 4) return _buildTrendView(screenSize);
    
    // Grouping logic
    final isExpense = _viewMode == 0 || _viewMode == 2 || _viewMode == 3;
    final filtered = _transactions.where((t) => isExpense ? (t.jenis == "keluar" || t.jenis == "pengeluaran") : t.jenis == "masuk").toList();
    
    Map<String, int> grouped = {};
    int total = 0;
    for (var t in filtered) {
      String key = _viewMode == 3 ? t.walletNama : t.kategori;
      grouped[key] = (grouped[key] ?? 0) + t.jumlah;
      total += t.jumlah;
    }

    if (total == 0) return const Center(child: Padding(padding: EdgeInsets.all(50), child: Text("Tidak ada data", style: TextStyle(color: Colors.grey))));

    double chartSize = screenSize.width * 0.6;
    if (chartSize > 300) chartSize = 300;

    return Column(
      children: [
        _buildAnalysisCard(grouped, total, isExpense),
        // Donut Chart
        SizedBox(
          height: chartSize + 120,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(chartSize, chartSize),
                painter: DonutChartPainter(grouped: grouped, total: total, getColor: _getCategoryColor),
              ),
              // Center Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isExpense ? "Pengeluaran" : "Penghasilan", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("Rp${NumberFormat.decimalPattern('id').format(total)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                ],
              ),
              // Floating Icons/Labels
              ..._buildDonutLabels(grouped, total, chartSize / 2 - 40, Offset(screenSize.width / 2, (chartSize + 120) / 2)),
            ],
          ),
        ),

        
        const SizedBox(height: 20),
        const Divider(height: 1),
        
        // List Breakdown
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            String key = grouped.keys.elementAt(index);
            int value = grouped[key]!;
            double percent = (value / total) * 100;
            final cat = [...AppData.pengeluaranCategories, ...AppData.pemasukanCategories]
                .firstWhere((c) => c.nama == key, orElse: () => TransactionCategory(nama: key, icon: Icons.category));

            return ListTile(
              leading: cat.imagePath != null 
                ? Image.asset(cat.imagePath!, width: 40, height: 40)
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _getCategoryColor(key).withAlpha(30), shape: BoxShape.circle),
                    child: Icon(cat.icon ?? Icons.category, color: _getCategoryColor(key), size: 24),
                  ),
              title: Text(key, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${percent.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(width: 20),
                  Text("Rp${NumberFormat.decimalPattern('id').format(value)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildTrendView(Size screenSize) {
    double chartHeight = screenSize.height * 0.4;
    if (chartHeight > 400) chartHeight = 400;
    if (chartHeight < 250) chartHeight = 250;

    return Column(
      children: [
        if (_isTrendMode) _buildTrendAnalysisCard(),
        // Line Chart (Real Trend)
        Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.all(15),
          height: chartHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _buildSmallTag("Tren", _isTrendMode, onTap: () => setState(() => _isTrendMode = true)),
                   const SizedBox(width: 10),
                   _buildSmallTag("Aset", !_isTrendMode, onTap: () => setState(() => _isTrendMode = false)),
                ],
              ),
              if (_isTrendMode) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendDot(Colors.green, "Masuk"),
                    const SizedBox(width: 20),
                    _buildLegendDot(Colors.orange, "Keluar"),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: TrendChartPainter(transactions: _transactions),
                    ),
                  ),
                ),
              ] else ...[
                const Spacer(),
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 50),
                const SizedBox(height: 10),
                const Text("Total Aset", style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  "Rp${NumberFormat.decimalPattern('id').format(_wallets.fold(0, (sum, w) => sum + w.saldo))}",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ]
            ],
          ),
        ),
        
        if (_isTrendMode)
          // Table Data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Expanded(child: Text("  Tgl", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text("Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    ],
                  ),
                ),
                ..._buildDailyTableRows(),
              ],
            ),
          )
        else
          _buildAsetList(),
      ],
    );
  }

  Widget _buildAsetList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: _wallets.map((w) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(w.icon, color: Colors.pink),
              ),
              title: Text(w.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(w.jenis, style: const TextStyle(fontSize: 12)),
              trailing: Text(
                "Rp${NumberFormat.decimalPattern('id').format(w.saldo)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildAnalysisCard(Map<String, int> grouped, int total, bool isExpense) {
    if (grouped.isEmpty) return const SizedBox.shrink();

    String highestCategory = "";
    int highestValue = 0;
    grouped.forEach((key, value) {
      if (value > highestValue) {
        highestValue = value;
        highestCategory = key;
      }
    });

    double percent = (highestValue / total) * 100;

    String message = "";
    if (isExpense) {
      message = "Pengeluaran terbesar Anda adalah pada kategori $highestCategory sebesar Rp${NumberFormat.decimalPattern('id').format(highestValue)} (${percent.toStringAsFixed(1)}% dari total pengeluaran).";
    } else {
      message = "Pemasukan terbesar Anda adalah dari kategori $highestCategory sebesar Rp${NumberFormat.decimalPattern('id').format(highestValue)} (${percent.toStringAsFixed(1)}% dari total pemasukan).";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100)
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Insight Bulan Ini", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
                const SizedBox(height: 5),
                Text(message, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendAnalysisCard() {
    int totalIn = 0;
    int totalOut = 0;
    for (var t in _transactions) {
      if (t.jenis == "masuk") {
        totalIn += t.jumlah;
      } else {
        totalOut += t.jumlah;
      }
    }

    String message = "";
    if (totalIn > totalOut) {
      message = "Bulan ini Anda berhasil menghemat sebesar Rp${NumberFormat.decimalPattern('id').format(totalIn - totalOut)}! Pertahankan keuangan sehat Anda.";
    } else if (totalOut > totalIn) {
      message = "Peringatan: Pengeluaran Anda lebih besar dari pemasukan (Defisit Rp${NumberFormat.decimalPattern('id').format(totalOut - totalIn)}). Coba evaluasi pengeluaran Anda.";
    } else if (totalIn == 0 && totalOut == 0) {
      return const SizedBox.shrink();
    } else {
      message = "Pemasukan dan pengeluaran Anda seimbang.";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: totalOut > totalIn ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: totalOut > totalIn ? Colors.red.shade100 : Colors.green.shade100)
      ),
      child: Row(
        children: [
          Icon(totalOut > totalIn ? Icons.warning_amber_rounded : Icons.insights, color: totalOut > totalIn ? Colors.red : Colors.green, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Analisis Keuangan", style: TextStyle(fontWeight: FontWeight.bold, color: totalOut > totalIn ? Colors.red : Colors.green, fontSize: 14)),
                const SizedBox(height: 5),
                Text(message, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 2, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }

  List<Widget> _buildDailyTableRows() {
    Map<String, Map<String, int>> daily = {};
    for (var t in _transactions) {
      String date = DateFormat('dd/M').format(t.tanggal);
      if (!daily.containsKey(date)) daily[date] = {"in": 0, "out": 0};
      if (t.jenis == "masuk") {
        daily[date]!["in"] = (daily[date]!["in"] ?? 0) + t.jumlah;
      } else {
        daily[date]!["out"] = (daily[date]!["out"] ?? 0) + t.jumlah;
      }
    }

    final sortedKeys = daily.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return sortedKeys.map((date) {
      int inc = daily[date]!["in"]!;
      int exp = daily[date]!["out"]!;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            Expanded(child: Text("  $date", style: const TextStyle(fontSize: 12))),
            Expanded(child: Text("Rp${NumberFormat.decimalPattern('id').format(inc)}", style: const TextStyle(color: Colors.green, fontSize: 11))),
            Expanded(child: Text("Rp${NumberFormat.decimalPattern('id').format(exp)}", style: const TextStyle(color: Colors.red, fontSize: 11))),
            Expanded(child: Text("Rp${NumberFormat.decimalPattern('id').format(inc - exp)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSmallTag(String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(color: isActive ? Colors.white : Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(15)),
        child: Text(label, style: TextStyle(color: isActive ? Colors.pink : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  List<Widget> _buildDonutLabels(Map<String, int> grouped, int total, double radius, Offset center) {
    List<Widget> labels = [];
    double startAngle = -1.5708;
    int i = 0;
    final List<Color> colors = [Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.pink, Colors.teal, Colors.indigo];

    grouped.forEach((key, value) {
      double sweepAngle = (value / total) * 6.28319;
      if (sweepAngle < 0.05) sweepAngle = 0.05;

      double midAngle = startAngle + sweepAngle / 2;
      double lx = center.dx + (radius + 20) * 1.4 * Math.cos(midAngle);
      double ly = center.dy + (radius + 20) * 1.4 * Math.sin(midAngle);

      final cat = [...AppData.pengeluaranCategories, ...AppData.pemasukanCategories]
          .firstWhere((c) => c.nama == key, orElse: () => TransactionCategory(nama: key, icon: Icons.category));

      labels.add(
        Positioned(
          left: lx - 25,
          top: ly - 25,
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, 2))],
              border: Border.all(color: _getCategoryColor(key).withAlpha(100), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cat.imagePath != null)
                  Image.asset(cat.imagePath!, width: 22, height: 22)
                else
                  Icon(cat.icon ?? Icons.category, size: 18, color: _getCategoryColor(key)),
                Text("${((value / total) * 100).toInt()}%", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ),
      );

      startAngle += sweepAngle;
      i++;
    });
    return labels;
  }

  IconData _getCategoryIcon(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'makan': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'belanja': return Icons.shopping_cart;
      case 'tagihan': return Icons.receipt;
      case 'hiburan': return Icons.movie;
      default: return Icons.category;
    }
  }

  Color _getCategoryColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'makan': return Colors.orange;
      case 'transport': return Colors.blue;
      case 'belanja': return Colors.pink;
      case 'tagihan': return Colors.red;
      case 'hiburan': return Colors.purple;
      default: return Colors.grey;
    }
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, int> grouped;
  final int total;
  final Color Function(String) getColor;

  DonutChartPainter({required this.grouped, required this.total, required this.getColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;
    const strokeWidth = 50.0;
    
    double startAngle = -1.5708;
    
    grouped.forEach((key, value) {
      double sweepAngle = (value / total) * 6.28319;
      if (sweepAngle < 0.05) sweepAngle = 0.05; // Min visibility

      final paint = Paint()
        ..color = getColor(key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class TrendChartPainter extends CustomPainter {
  final List<Transaksi> transactions;

  TrendChartPainter({required this.transactions});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.white.withAlpha(30)..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      double y = size.height / 5 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (transactions.isEmpty) return;

    // Daily aggregation
    Map<int, double> dailyIn = {};
    Map<int, double> dailyOut = {};
    for (var t in transactions) {
      int day = t.tanggal.day;
      if (t.jenis == "masuk") {
        dailyIn[day] = (dailyIn[day] ?? 0) + t.jumlah;
      } else {
        dailyOut[day] = (dailyOut[day] ?? 0) + t.jumlah;
      }
    }

    double maxVal = 0;
    for (var v in dailyIn.values) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in dailyOut.values) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 1;

    // Draw Lines
    _drawLine(canvas, size, dailyIn, Colors.green, maxVal);
    _drawLine(canvas, size, dailyOut, Colors.orange, maxVal);
  }

  void _drawLine(Canvas canvas, Size size, Map<int, double> data, Color color, double maxVal) {
    if (data.isEmpty) return;
    
    final path = Path();
    double xStep = size.width / 30; // Max days
    
    bool first = true;
    for (int i = 1; i <= 30; i++) {
      double val = data[i] ?? 0;
      double x = (i-1) * xStep;
      double y = size.height - (val / maxVal * size.height * 0.8);
      
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    // Shaded Area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = color.withAlpha(30)..style = PaintingStyle.fill);

    // Line
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
