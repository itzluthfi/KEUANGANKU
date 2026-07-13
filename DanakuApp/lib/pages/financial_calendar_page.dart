import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import '../widgets/transaksi_item.dart';

class FinancialCalendarPage extends StatefulWidget {
  const FinancialCalendarPage({super.key});

  @override
  State<FinancialCalendarPage> createState() => _FinancialCalendarPageState();
}

class _FinancialCalendarPageState extends State<FinancialCalendarPage> {
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Transaksi> _allTransaksi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null).then((_) {
      _loadTransactions();
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final txs = await DatabaseHelper.instance.fetchTransaksi();
    setState(() {
      _allTransaksi = txs;
      _isLoading = false;
    });
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
      _selectedDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      _selectedDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter transaksi untuk bulan yang dipilih
    final monthlyTxs = _allTransaksi.where((t) {
      return t.tanggal.month == _selectedMonth.month && t.tanggal.year == _selectedMonth.year;
    }).toList();

    // Filter transaksi untuk hari yang dipilih
    final dailyTxs = monthlyTxs.where((t) {
      return t.tanggal.day == _selectedDay.day &&
          t.tanggal.month == _selectedDay.month &&
          t.tanggal.year == _selectedDay.year;
    }).toList();

    int dailyIncome = dailyTxs
        .where((t) => t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan')
        .fold(0, (sum, t) => sum + t.jumlah);

    int dailyExpense = dailyTxs
        .where((t) => t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran')
        .fold(0, (sum, t) => sum + t.jumlah);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Kalender Keuangan", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Column(
              children: [
                // Kalender Box
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      // Header Navigasi Bulan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.pink),
                            onPressed: _prevMonth,
                          ),
                          Text(
                            DateFormat('MMMM yyyy', 'id').format(_selectedMonth),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit', color: Colors.black87),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.pink),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Row Nama Hari
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"].map((day) {
                          final isWeekend = day == "Min" || day == "Sab";
                          return Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: isWeekend ? Colors.red.shade300 : Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      // Grid Tanggal
                      _buildCalendarGrid(monthlyTxs),
                    ],
                  ),
                ),

                // Tajuk Ringkasan Harian
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDay),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, fontFamily: 'Outfit'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${dailyTxs.length} Catatan",
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.pink, fontFamily: 'Outfit'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Baris Ringkasan Saldo Harian
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildDailySummaryTile("Pemasukan", dailyIncome, Colors.green),
                      const SizedBox(width: 12),
                      _buildDailySummaryTile("Pengeluaran", dailyExpense, Colors.red),
                      const SizedBox(width: 12),
                      _buildDailySummaryTile("Selisih", dailyIncome - dailyExpense, Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Daftar Transaksi Hari Ini
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: dailyTxs.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(30),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long_rounded, size: 50, color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Tidak ada catatan keuangan pada hari ini",
                                      style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Outfit'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                            itemCount: dailyTxs.length,
                            itemBuilder: (context, index) {
                              final tx = dailyTxs[index];
                              return TransaksiItem(
                                transaksi: tx,
                                onTap: () => _showTransactionDetails(tx),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDailySummaryTile(String label, int amount, Color color) {
    final format = NumberFormat.decimalPattern('id');
    final formatted = format.format(amount.abs());
    final isNegative = amount < 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'Outfit')),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${isNegative ? '-' : ''}Rp$formatted",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<Transaksi> monthlyTxs) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];

    // Grid offsets untuk hari kosong sebelum tanggal 1
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Loop tanggal
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isToday = date.day == DateTime.now().day &&
          date.month == DateTime.now().month &&
          date.year == DateTime.now().year;
      final isSelected = _selectedDay.day == day &&
          _selectedDay.month == _selectedMonth.month &&
          _selectedDay.year == _selectedMonth.year;

      // Cek tipe transaksi di tanggal ini
      final dayTxs = monthlyTxs.where((t) => t.tanggal.day == day).toList();
      final hasIncome = dayTxs.any((t) => t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan');
      final hasExpense = dayTxs.any((t) => t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran');
      final hasTransfer = dayTxs.any((t) => t.jenis.toLowerCase() == 'transfer');

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.pink
                      : (isToday ? Colors.pink.shade50 : Colors.transparent),
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: Colors.pink, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    "$day",
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? Colors.pink
                              : (date.weekday == 7 || date.weekday == 6
                                  ? Colors.red.shade400
                                  : Colors.black87)),
                      fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Dots Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasIncome)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                  if (hasExpense)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  if (hasTransfer)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    ),
                ],
              )
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: dayWidgets,
    );
  }

  void _showTransactionDetails(Transaksi tx) {
    final format = NumberFormat.decimalPattern('id');
    final formattedAmount = format.format(tx.jumlah);
    final isMasuk = tx.jenis.toLowerCase() == 'masuk' || tx.jenis.toLowerCase() == 'pemasukan';
    final dateStr = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id').format(tx.tanggal);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Detail Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit')),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text(
                tx.keterangan.isNotEmpty ? tx.keterangan : "(Tanpa Keterangan)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Outfit'),
              ),
              const SizedBox(height: 6),
              Text(
                "${isMasuk ? '+' : '-'} Rp$formattedAmount",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: isMasuk ? Colors.green : Colors.red,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 15),
              _detailRow(Icons.calendar_today_rounded, "Waktu", dateStr),
              const SizedBox(height: 10),
              _detailRow(Icons.category_rounded, "Kategori", tx.kategori),
              const SizedBox(height: 10),
              _detailRow(Icons.account_balance_wallet_rounded, "Dompet", tx.walletNama),
              if (tx.jenis.toLowerCase() == 'transfer') ...[
                const SizedBox(height: 10),
                _detailRow(Icons.swap_horiz_rounded, "Tipe", "Transfer Uang"),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.pink.shade300),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontFamily: 'Outfit')),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, fontFamily: 'Outfit')),
      ],
    );
  }
}
