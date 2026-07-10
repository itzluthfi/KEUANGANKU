import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as Math;
import 'dart:ui' as ui;
import '../data/app_data.dart';
import '../data/database_helper.dart';
import '../services/pdf_service.dart';

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
  DateTimeRange? _selectedDateRange;
  List<Transaksi> _transactions = [];
  List<Wallet> _wallets = [];
  String _selectedCategory = "Semua";
  String _selectedWallet = "Semua";
 
   @override
   void initState() {
     super.initState();
     _loadData();
   }
 
   Future<void> _loadData() async {
     final all = await DatabaseHelper.instance.fetchTransaksi();
     final allWallets = await DatabaseHelper.instance.fetchWallets();
     setState(() {
       if (_selectedDateRange != null) {
         final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
         final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
         _transactions = all.where((t) => t.tanggal.isAfter(start.subtract(const Duration(seconds: 1))) && 
                                         t.tanggal.isBefore(end.add(const Duration(seconds: 1)))).toList();
       } else {
         _transactions = all.where((t) => t.tanggal.month == _selectedMonth.month && t.tanggal.year == _selectedMonth.year).toList();
       }
       _wallets = allWallets;
     });
   }
 
   void _prevMonth() {
     setState(() {
       _selectedDateRange = null;
       _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
       _loadData();
     });
   }
 
   void _nextMonth() {
     setState(() {
       _selectedDateRange = null;
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

    // Pre-calculate transaction filtering and grouping for sub-toggle and main content
    final isExpense = _viewMode == 0 || _viewMode == 2 || _viewMode == 3;
    final filtered = _transactions.where((t) {
      final matchesType = isExpense
          ? (t.jenis == "keluar" || t.jenis == "pengeluaran")
          : (t.jenis == "masuk" || t.jenis == "pemasukan");
      
      final matchesCategory = _selectedCategory == "Semua" || t.kategori == _selectedCategory;
      final matchesWallet = _selectedWallet == "Semua" || t.walletNama == _selectedWallet;
      
      return matchesType && matchesCategory && matchesWallet;
    }).toList();
    
    Map<String, int> grouped = {};
    int total = 0;
    if (_viewMode < 4) {
      for (var t in filtered) {
        String key = _viewMode == 3 ? t.walletNama : t.kategori;
        grouped[key] = (grouped[key] ?? 0) + t.jumlah;
        total += t.jumlah;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        leading: const Icon(Icons.menu_book, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: "Ekspor PDF",
            onPressed: () async {
              if (_transactions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tidak ada transaksi untuk diekspor"), behavior: SnackBarBehavior.floating),
                );
                return;
              }
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF528F))),
              );
              try {
                await PdfService.instance.generateMonthlyReport(_transactions, _selectedMonth);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal ekspor PDF: $e"), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
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
              onTap: () async {
                final choice = await showModalBottomSheet<String>(
                  context: context,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                      ListTile(
                        leading: const Icon(Icons.calendar_month, color: Color(0xFFFF528F)),
                        title: const Text("Pilih Bulan", style: TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.pop(context, "month"),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.date_range, color: Color(0xFFFF528F)),
                        title: const Text("Pilih Rentang Tanggal", style: TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () => Navigator.pop(context, "range"),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );

                if (choice == "month") {
                  _showMonthPicker();
                } else if (choice == "range") {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _selectedDateRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFF528F),
                            onPrimary: Colors.white,
                            onSurface: Colors.black87,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDateRange = picked;
                      _loadData();
                    });
                  }
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    _selectedDateRange == null
                        ? DateFormat('M/yyyy').format(_selectedMonth)
                        : "${DateFormat('d MMM', 'id').format(_selectedDateRange!.start)} - ${DateFormat('d MMM', 'id').format(_selectedDateRange!.end)}",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
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
                      _buildSubToggle(grouped, total, isExpense),
                      const SizedBox(height: 20),
                      _buildMainContent(screenSize, grouped, total, isExpense),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.pink : Colors.white, size: 18),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.pink : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showCategoryFilterSheet() {
    var categories = ["Semua", ..._transactions.map((t) => t.kategori).toSet().toList()];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              const SizedBox(height: 10),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final catName = categories[index];
                    final isSelected = _selectedCategory == catName;
                    return ListTile(
                      title: Text(catName == "Semua" ? "Semua Kategori" : catName),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.pink) : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = catName;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWalletFilterSheet() {
    var wallets = ["Semua", ..._wallets.map((w) => w.nama).toList()];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Dompet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              const SizedBox(height: 10),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    final wName = wallets[index];
                    final isSelected = _selectedWallet == wName;
                    return ListTile(
                      title: Text(wName == "Semua" ? "Semua Dompet" : wName),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.pink) : null,
                      onTap: () {
                        setState(() {
                          _selectedWallet = wName;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubToggle(Map<String, int> grouped, int total, bool isExpense) {
    if (_viewMode >= 4) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          // Category Filter Chip
          GestureDetector(
            onTap: _showCategoryFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedCategory == "Semua" ? Colors.pink.shade50 : Colors.pink,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCategory == "Semua" ? "Kategori: Semua" : _selectedCategory,
                    style: TextStyle(
                      color: _selectedCategory == "Semua" ? Colors.pink : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: _selectedCategory == "Semua" ? Colors.pink : Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Wallet Filter Chip
          GestureDetector(
            onTap: _showWalletFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedWallet == "Semua" ? Colors.blue.shade50 : Colors.blue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedWallet == "Semua" ? "Dompet: Semua" : _selectedWallet,
                    style: TextStyle(
                      color: _selectedWallet == "Semua" ? Colors.blue.shade700 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: _selectedWallet == "Semua" ? Colors.blue.shade700 : Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Space saving Lightbulb / Info Icon for AI Insight modal
          if (total > 0)
            IconButton(
              icon: const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 24),
              onPressed: () => _showInsightModal(grouped, total, isExpense),
              tooltip: "Tampilkan Insight AI",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Size screenSize, Map<String, int> grouped, int total, bool isExpense) {

    if (_viewMode == 4) return _buildTrendView(screenSize);
    
    if (total == 0) return const Center(child: Padding(padding: EdgeInsets.all(50), child: Text("Tidak ada data", style: TextStyle(color: Colors.grey))));

    double chartSize = screenSize.width * 0.6;
    if (chartSize > 300) chartSize = 300;

    return Column(
      children: [
        // Donut Chart
        SizedBox(
          height: chartSize + 120,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(chartSize, chartSize),
                painter: DonutChartPainter(
                  grouped: grouped,
                  total: total,
                  getColor: _getReportColor,
                  isExpense: isExpense,
                ),
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
              ..._buildDonutLabels(grouped, total, chartSize / 2 - 40, Offset(screenSize.width / 2, (chartSize + 120) / 2), isExpense),
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
                    decoration: BoxDecoration(color: _getReportColor(index, key, isExpense).withAlpha(30), shape: BoxShape.circle),
                    child: Icon(cat.icon ?? Icons.category, color: _getReportColor(index, key, isExpense), size: 24),
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


  void _showInsightModal(Map<String, int> grouped, int total, bool isExpense) {
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text("Insight Keuangan AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 15),
              Text(
                message,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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

  List<Widget> _buildDonutLabels(Map<String, int> grouped, int total, double radius, Offset center, bool isExpense) {
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
              border: Border.all(color: _getReportColor(i, key, isExpense).withAlpha(100), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cat.imagePath != null)
                  Image.asset(cat.imagePath!, width: 22, height: 22)
                else
                  Icon(cat.icon ?? Icons.category, size: 18, color: _getReportColor(i, key, isExpense)),
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

  Color _getReportColor(int index, String key, bool isExpense) {
    if (key.toLowerCase() == 'transfer') {
      final greyShades = [
        Colors.grey.shade500,
        Colors.grey.shade400,
        Colors.blueGrey.shade400,
        Colors.grey.shade600,
        Colors.grey.shade300,
      ];
      return greyShades[index % greyShades.length];
    }
    
    if (!isExpense) {
      // Pemasukan -> Green shades
      final greenShades = [
        Colors.green.shade500,
        Colors.green.shade400,
        Colors.teal.shade400,
        Colors.lightGreen.shade500,
        Colors.green.shade600,
        Colors.teal.shade300,
        Colors.green.shade300,
      ];
      return greenShades[index % greenShades.length];
    } else {
      // Pengeluaran -> Red shades
      final redShades = [
        const Color(0xFFFF528F), // Theme pink/red
        Colors.red.shade400,
        Colors.orange.shade500,
        Colors.pink.shade400,
        Colors.red.shade600,
        Colors.orange.shade400,
        Colors.red.shade300,
        Colors.pink.shade300,
      ];
      return redShades[index % redShades.length];
    }
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, int> grouped;
  final int total;
  final Color Function(int, String, bool) getColor;
  final bool isExpense;

  DonutChartPainter({required this.grouped, required this.total, required this.getColor, required this.isExpense});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 40;
    const strokeWidth = 50.0;
    
    double startAngle = -1.5708;
    
    int index = 0;
    grouped.forEach((key, value) {
      double sweepAngle = (value / total) * 6.28319;
      if (sweepAngle < 0.05) sweepAngle = 0.05; // Min visibility

      final paint = Paint()
        ..color = getColor(index, key, isExpense)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
      index++;
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
