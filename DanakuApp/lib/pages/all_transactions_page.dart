import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import 'transaction_input_page.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  List<Transaksi> allTransaksi = [];
  bool isLoading = true;

  String _searchQuery = "";
  String _selectedJenis = "Semua";
  String _selectedWallet = "Semua";
  String _selectedCategory = "Semua";
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id', null).then((_) {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper.instance.fetchTransaksi();
    if (mounted) {
      setState(() {
        allTransaksi = data;
        isLoading = false;
      });
    }
  }

  bool _isMasuk(Transaksi t) {
    final jenis = t.jenis.toLowerCase();
    return jenis == 'masuk' || jenis == 'pemasukan';
  }

  List<Transaksi> get _filtered {
    return allTransaksi.where((t) {
      final matchesSearch = t.keterangan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesJenis = _selectedJenis == "Semua" ||
          (_selectedJenis == "Masuk" ? _isMasuk(t) : !_isMasuk(t));
      final matchesWallet = _selectedWallet == "Semua" || t.walletNama == _selectedWallet;
      final matchesCategory = _selectedCategory == "Semua" || t.kategori == _selectedCategory;
      
      bool matchesDate = true;
      if (_selectedDateRange != null) {
        try {
          final tDate = t.tanggal;
          final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
          matchesDate = tDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
                        tDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (_) {}
      }
      
      return matchesSearch && matchesJenis && matchesWallet && matchesCategory && matchesDate;
    }).toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalIncome = filtered.where(_isMasuk).fold(0, (sum, t) => sum + t.jumlah);
    final totalExpense = filtered.where((t) => !_isMasuk(t)).fold(0, (sum, t) => sum + t.jumlah);

    return Scaffold(
      backgroundColor: const Color(0xFFFF528F),
      body: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFF4F7F6),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  _buildHeader(totalIncome, totalExpense),
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFFFF528F),
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildSearchAndFilters(),
                            const SizedBox(height: 6),
                            if (isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(child: CircularProgressIndicator(color: Color(0xFFFF528F))),
                              )
                            else
                              _buildGroupedList(filtered),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int totalIncome, int totalExpense) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 10, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Semua Transaksi",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                _buildStatBox("Masuk", totalIncome, Icons.arrow_circle_down_rounded),
                const SizedBox(width: 10),
                _buildStatBox("Keluar", totalExpense, Icons.arrow_circle_up_rounded),
                const SizedBox(width: 10),
                _buildStatBox("Total", totalIncome - totalExpense, Icons.account_balance_wallet_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int amount, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 13),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Rp${NumberFormat.decimalPattern('id').format(amount)}",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final wallets = {"Semua", ...allTransaksi.map((t) => t.walletNama).where((w) => w.isNotEmpty)};
    final cats = {"Semua", ...allTransaksi.map((t) => t.kategori).where((c) => c.isNotEmpty)};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari transaksi...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () => setState(() => _searchQuery = ""),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                ...["Semua", "Masuk", "Keluar"].map((j) {
                  final isSelected = _selectedJenis == j;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(j, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      selectedColor: Colors.green.shade100,
                      checkmarkColor: Colors.green,
                      onSelected: (val) => setState(() => _selectedJenis = j),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                const Text("|", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 4),
                ...wallets.map((w) {
                  final isSelected = _selectedWallet == w;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(w == "Semua" ? "Semua Dompet" : w, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      selectedColor: Colors.pink.shade100,
                      checkmarkColor: Colors.pink,
                      onSelected: (val) => setState(() => _selectedWallet = w),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                const Text("|", style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 4),
                ...cats.map((c) {
                  final isSelected = _selectedCategory == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(c == "Semua" ? "Semua Kategori" : c, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                      onSelected: (val) => setState(() => _selectedCategory = c),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: _selectedDateRange != null ? Colors.pink : Colors.grey.shade300),
                ),
                icon: Icon(Icons.date_range, size: 16, color: _selectedDateRange != null ? Colors.pink : Colors.grey),
                label: Text(
                  _selectedDateRange == null
                      ? "Pilih Rentang Tanggal"
                      : "${DateFormat('d MMM yyyy', 'id').format(_selectedDateRange!.start)} - ${DateFormat('d MMM yyyy', 'id').format(_selectedDateRange!.end)}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _selectedDateRange != null ? Colors.pink : Colors.black87,
                  ),
                ),
                onPressed: () async {
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
                    setState(() => _selectedDateRange = picked);
                  }
                },
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                  onPressed: () => setState(() => _selectedDateRange = null),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(List<Transaksi> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/icons/Piggy Bank.json',
                width: 160,
                height: 160,
                repeat: true,
              ),
              const SizedBox(height: 15),
              const Text(
                "Tidak ada transaksi",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              const Text(
                "Coba ubah kata kunci atau filter pencarianmu",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Kelompokkan per hari, lalu selipkan label bulan saat bulannya berganti
    final Map<String, List<Transaksi>> byDay = {};
    for (final t in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(t.tanggal);
      byDay.putIfAbsent(key, () => []).add(t);
    }
    final dayKeys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    final List<Widget> children = [];
    String? currentMonth;
    for (final dayKey in dayKeys) {
      final date = DateTime.parse(dayKey);
      final monthLabel = DateFormat('MMMM yyyy', 'id').format(date);
      if (monthLabel != currentMonth) {
        currentMonth = monthLabel;
        children.add(_buildMonthLabel(monthLabel, date));
      }
      children.add(_buildDayCard(date, byDay[dayKey]!));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildMonthLabel(String label, DateTime date) {
    final monthTransaksi = _filtered.where((t) =>
        t.tanggal.month == date.month && t.tanggal.year == date.year);
    final income = monthTransaksi.where(_isMasuk).fold(0, (sum, t) => sum + t.jumlah);
    final expense = monthTransaksi.where((t) => !_isMasuk(t)).fold(0, (sum, t) => sum + t.jumlah);
    final net = income - expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFFFF528F)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          Text(
            "${net >= 0 ? '+' : '-'}Rp${NumberFormat.decimalPattern('id').format(net.abs())}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: net >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime date, List<Transaksi> list) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd/MM', 'id').format(date),
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.pink, size: 20),
              ],
            ),
          ),
          const Divider(height: 1),
          ...list.map((t) {
            final catData = [...AppData.pengeluaranCategories, ...AppData.pemasukanCategories]
                .firstWhere((c) => c.nama == t.kategori, orElse: () => TransactionCategory(nama: t.kategori, icon: Icons.category));
            return ListTile(
              onTap: () => _showTransactionOptions(t),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: catData.imagePath != null ? Colors.pink.withAlpha(25) : _getCategoryColor(t.kategori).withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: catData.imagePath != null
                    ? Image.asset(catData.imagePath!, width: 24, height: 24)
                    : Icon(_getCategoryIcon(t.kategori), color: _getCategoryColor(t.kategori)),
              ),
              title: Text(t.keterangan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(t.walletNama, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: Text(
                "${_isMasuk(t) ? '+' : '-'}Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                style: TextStyle(
                  color: _isMasuk(t) ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            );
          }),
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
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Colors.grey.shade50,
                  leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                  title: const Text("Edit Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionInputPage(
                          initialJenis: _isMasuk(t) ? 'masuk' : 'keluar',
                          initialTransaksi: t,
                        ),
                      ),
                    );
                    if (result == true) _loadData();
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Colors.grey.shade50,
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text("Hapus Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteTransaksi(t);
              _loadData();
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
                        _loadData();
                      },
                    ),
                    duration: const Duration(seconds: 5),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            },
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
