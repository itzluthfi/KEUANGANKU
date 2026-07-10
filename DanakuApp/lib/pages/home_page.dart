import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import 'transaction_input_page.dart';
import 'all_transactions_page.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../services/sync_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  DateTime selectedDay = DateTime.now();
  List<Transaksi> transaksiBulanIni = [];
  String viewMode = "Total"; // Pengeluaran, Penghasilan, Total
  bool isCalendarView = false;
  bool _isObscured = false;
  String _searchQuery = "";
  String _selectedCategory = "Semua";
  String _selectedWallet = "Semua";
  
  bool _isOnline = true;
  bool _wasOffline = false;
  bool _showOnlineSuccessBanner = false;
  Timer? _successBannerTimer;
  bool isLoading = false;
  int _monthlyBudget = 0;

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 8;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });
    initializeDateFormatting('id', null).then((_) {
      if (mounted) setState(() {});
    });
    loadData().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkRecurringTransactions();
        });
      }
    });

    _isOnline = SyncService.instance.connectionStatus.value;
    SyncService.instance.connectionStatus.addListener(_onConnectionChange);
  }

  @override
  void dispose() {
    SyncService.instance.connectionStatus.removeListener(_onConnectionChange);
    _successBannerTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onConnectionChange() {
    if (mounted) {
      setState(() {
        _isOnline = SyncService.instance.connectionStatus.value;
        if (!_isOnline) {
          _wasOffline = true;
        } else if (_isOnline && _wasOffline) {
          _showOnlineSuccessBanner = true;
        }
      });
      _successBannerTimer?.cancel();
      _successBannerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showOnlineSuccessBanner = false;
            _wasOffline = false;
          });
        }
      });
    }
  }

  Future<void> _loadActiveBook() async {
    final db = DatabaseHelper.instance;
    final books = await db.fetchBooks();
    if (books.isEmpty) return;
    final savedId = int.tryParse(await db.getSetting('active_book_id') ?? '');
    final active = books.firstWhere(
      (b) => b.id == savedId,
      orElse: () => books.first,
    );
    AppData.activeBookId = active.id!;
    AppData.activeBookName = active.nama;
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    await _loadActiveBook();
    final allTransaksi = await DatabaseHelper.instance.fetchTransaksi();
    final allWallets = await DatabaseHelper.instance.fetchWallets();
    final budgetStr = await DatabaseHelper.instance.getSetting('monthly_budget');
    final budget = int.tryParse(budgetStr ?? "0") ?? 0;

    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      AppData.wallets = allWallets;
      _monthlyBudget = budget;
      transaksiBulanIni = allTransaksi.where((t) {
        return t.tanggal.month == selectedDate.month && t.tanggal.year == selectedDate.year;
      }).toList();
      isLoading = false;
    });
  }

  Future<void> _checkRecurringTransactions() async {
    final db = DatabaseHelper.instance;
    final recurringList = await db.fetchRecurringTransactions();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    
    int triggeredCount = 0;
    List<String> details = [];

    for (var rt in recurringList) {
      if (rt.isActive && (rt.nextDueDate.isBefore(today) || DateFormat('yyyy-MM-dd').format(rt.nextDueDate) == todayStr)) {
        final newT = Transaksi(
          bookId: rt.bookId,
          keterangan: rt.keterangan,
          jumlah: rt.jumlah,
          jenis: rt.jenis,
          tanggal: DateTime.now(),
          walletNama: rt.walletNama,
          kategori: rt.kategori,
        );

        await db.insertTransaksi(newT);
        
        DateTime nextDate = rt.nextDueDate;
        if (rt.interval == "harian") {
          nextDate = nextDate.add(const Duration(days: 1));
        } else if (rt.interval == "mingguan") {
          nextDate = nextDate.add(const Duration(days: 7));
        } else if (rt.interval == "bulanan") {
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        }

        final updatedRt = RecurringTransaction(
          id: rt.id,
          bookId: rt.bookId,
          keterangan: rt.keterangan,
          jumlah: rt.jumlah,
          jenis: rt.jenis,
          kategori: rt.kategori,
          walletNama: rt.walletNama,
          interval: rt.interval,
          nextDueDate: nextDate,
          isActive: rt.isActive,
        );

        await db.updateRecurringTransaction(updatedRt);

        triggeredCount++;
        details.add("- ${rt.keterangan} (Rp${NumberFormat.decimalPattern('id').format(rt.jumlah)})");
      }
    }

    if (triggeredCount > 0) {
      await loadData();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.autorenew_rounded, color: Colors.pink),
                SizedBox(width: 10),
                Text("Pencatatan Rutin", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sistem telah mencatat $triggeredCount transaksi rutin Anda secara otomatis hari ini:",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ...details.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(d, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 13)),
                )),
                const SizedBox(height: 12),
                const Text("Saldo dompet Anda telah diperbarui sesuai detail transaksi di atas.", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Mantap", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _nextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      selectedDay = DateTime(selectedDate.year, selectedDate.month, 1);
      loadData();
    });
  }

  void _prevMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      selectedDay = DateTime(selectedDate.year, selectedDate.month, 1);
      loadData();
    });
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

  void _showSwitchBookDialog() async {
    final books = await DatabaseHelper.instance.fetchBooks();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Pilih Buku", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...books.map((b) => ListTile(
                leading: const Icon(Icons.book, color: Colors.pink),
                title: Text(b.nama, style: TextStyle(fontWeight: AppData.activeBookId == b.id ? FontWeight.bold : FontWeight.normal)),
                trailing: AppData.activeBookId == b.id ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    AppData.activeBookId = b.id!;
                    AppData.activeBookName = b.nama;
                  });
                  Navigator.pop(context);
                  DatabaseHelper.instance
                      .saveSetting('active_book_id', b.id!.toString())
                      .then((_) => loadData());
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  void _createNewBook() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Buku Baru"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Nama Buku (misal: Tabungan Elga)"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final newId = await DatabaseHelper.instance.insertBook(nameController.text.trim());
                await DatabaseHelper.instance.saveSetting('active_book_id', newId.toString());
                setState(() {
                  AppData.activeBookId = newId;
                  AppData.activeBookName = nameController.text.trim();
                });
                // Initialize default empty wallet for new book
                await DatabaseHelper.instance.saveWallets([
                  Wallet(nama: "Utama", saldo: 0, jenis: "Akun Virtual", icon: Icons.account_balance_wallet)
                ]);
                if (!mounted) return;
                loadData();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Buat", style: TextStyle(color: Colors.pink)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFF528F),
      body: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFF4F7F6),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Stack(
                children: [
                // 1. Fixed top bar (search & toggles) + scrollable content below it
                Column(
                  children: [
                    _buildFixedTopBar(),
                     Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFFF528F),
                        onRefresh: () async {
                          await loadData();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Book header (nama buku aktif) ikut ter-scroll bersama konten
                              _buildBookHeader(isTablet),
                              const SizedBox(height: 20),
  
                              // Conditional View (Detail/Calendar)
                              if (isCalendarView) ...[
                                _buildCalendarCard(),
                                const SizedBox(height: 20),
                                _buildBottomTotals(),
                              ] else ...[
                                _buildSummaryCard(),
                                const SizedBox(height: 20),
                                _buildSearchAndFilters(),
                                const SizedBox(height: 4),
                                _buildTransactionSectionHeader(),
                                _buildTransactionList(),
                              ],
  
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  right: 20,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: !_isOnline
                        ? _buildConnectionBanner(
                            key: "offline",
                            icon: Icons.wifi_off_rounded,
                            message: "Mode Offline: Catatan disimpan lokal",
                            color: Colors.orange.shade800,
                          )
                        : (_showOnlineSuccessBanner
                            ? _buildConnectionBanner(
                                key: "online",
                                icon: Icons.wifi_rounded,
                                message: "Kembali Online: Data disinkronkan!",
                                color: Colors.green.shade700,
                              )
                            : const SizedBox.shrink()),
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

  // Judul section transaksi + tombol menuju halaman Semua Transaksi
  Widget _buildTransactionSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Transaksi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllTransactionsPage()),
              );
              loadData();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF528F),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Lihat Semua", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bar atas yang selalu menempel (sticky): search + toggle Detail/Kalender
  Widget _buildFixedTopBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 15, 20, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: _isScrolled
            ? const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.search, color: Colors.white, size: 28),
          Row(
            children: [
              _buildViewToggleButton(
                icon: Icons.shopping_basket,
                label: "Detail",
                isActive: !isCalendarView,
                activeColor: Colors.pink,
                onTap: () => setState(() => isCalendarView = false),
              ),
              const SizedBox(width: 10),
              _buildViewToggleButton(
                icon: Icons.calendar_month,
                label: "Kalender",
                isActive: isCalendarView,
                activeColor: Colors.pink,
                onTap: () => setState(() => isCalendarView = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Header buku aktif: ikut ter-scroll bersama konten di bawah bar atas
  Widget _buildBookHeader(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: InkWell(
              onTap: _showSwitchBookDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      AppData.activeBookName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 28 : 22,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 26),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              _topActionItem(Icons.person_pin_outlined, AppData.activeBookName.split(' ').first, true),
              const SizedBox(width: 15),
              _topActionItem(Icons.add, "Baru Buku", false, onTap: _createNewBook),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withAlpha(50),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white, size: 18),
            const SizedBox(width: 5),
            Text(
              label, 
              style: TextStyle(
                color: isActive ? activeColor : Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 12,
              )
            ),
          ],
        ),
      ),
    );
  }


  Widget _topActionItem(IconData icon, String label, bool isSelected, {VoidCallback? onTap}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = MediaQuery.of(context).size.width > 600 ? 80 : 65;
        return GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withAlpha(80) : Colors.transparent,
                  border: isSelected ? null : Border.all(color: Colors.white.withAlpha(150), width: 1.5),
                  borderRadius: BorderRadius.circular(size * 0.3),
                ),
                child: Icon(icon, color: isSelected ? Colors.white : Colors.tealAccent, size: size * 0.45),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSummaryCard() {
    int totalIncome = transaksiBulanIni.where((t) => t.jenis == "masuk" || t.jenis == "pemasukan").fold(0, (sum, t) => sum + t.jumlah);
    int totalExpense = transaksiBulanIni.where((t) => t.jenis == "keluar" || t.jenis == "pengeluaran").fold(0, (sum, t) => sum + t.jumlah);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFFFF528F).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('MMMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  IconButton(
                    icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: ShimmerWidget(width: 140, height: 22),
                      )
                    : Text(
                        _isObscured ? "Rp •••••••" : "Rp${NumberFormat.decimalPattern('id').format(totalIncome - totalExpense)}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: isLoading
                              ? const ShimmerWidget(width: 80, height: 14)
                              : Text(
                                  _isObscured ? "Rp •••••" : "Rp${NumberFormat.decimalPattern('id').format(totalIncome)}",
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_circle_down, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            const Text("Masuk", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(height: 30, width: 1, color: Colors.black12),
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: isLoading
                              ? const ShimmerWidget(width: 80, height: 14)
                              : Text(
                                  _isObscured ? "Rp •••••" : "Rp${NumberFormat.decimalPattern('id').format(totalExpense)}",
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_circle_up, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            const Text("Keluar", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_monthlyBudget > 0) ...[
                const SizedBox(height: 15),
                const Divider(height: 1, color: Colors.black12),
                const SizedBox(height: 12),
                _buildBudgetProgress(),
              ],
            ],
          );
        }
      ),
    );
  }

  Widget _buildBudgetProgress() {
    int totalExpense = transaksiBulanIni
        .where((t) => t.jenis.toLowerCase() == "keluar" || t.jenis.toLowerCase() == "pengeluaran")
        .fold(0, (sum, t) => sum + t.jumlah);
        
    double percent = totalExpense / _monthlyBudget;
    if (percent > 1.0) percent = 1.0;
    bool isOver = totalExpense > _monthlyBudget;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isOver ? Icons.warning_amber_rounded : Icons.track_changes_rounded,
                  size: 14,
                  color: isOver ? Colors.red : Colors.pink,
                ),
                const SizedBox(width: 4),
                Text(
                  isOver ? "Melebihi Anggaran!" : "Anggaran Bulanan",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOver ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            Text(
              "Rp${NumberFormat.decimalPattern('id').format(totalExpense)} / Rp${NumberFormat.decimalPattern('id').format(_monthlyBudget)}",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isOver ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.red : const Color(0xFFFF528F)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    final cats = {"Semua", ...transaksiBulanIni.map((t) => t.kategori).where((c) => c.isNotEmpty)};
    final wallets = {"Semua", ...transaksiBulanIni.map((t) => t.walletNama).where((w) => w.isNotEmpty)};

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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: "Cari transaksi...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = "";
                          });
                        },
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
                ...wallets.map((w) {
                  final isSelected = _selectedWallet == w;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(w == "Semua" ? "Semua Dompet" : w, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      selectedColor: Colors.pink.shade100,
                      checkmarkColor: Colors.pink,
                      onSelected: (val) {
                        setState(() {
                          _selectedWallet = w;
                        });
                      },
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
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = c;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerTransactionList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(2, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date shimmer header
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: ShimmerWidget(width: 100, height: 16),
                ),
                // Card container for transaction list group
                Card(
                  elevation: 1,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: List.generate(2, (itemIdx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                          child: Row(
                            children: [
                              // Icon round shimmer
                              const ShimmerWidget(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
                              const SizedBox(width: 12),
                              // Title and subtitle shimmer
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const ShimmerWidget(width: 120, height: 14),
                                    const SizedBox(height: 6),
                                    const ShimmerWidget(width: 70, height: 10),
                                  ],
                                ),
                              ),
                              // Amount shimmer
                              const ShimmerWidget(width: 80, height: 16),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (isLoading) {
      return _buildShimmerTransactionList();
    }
    final filtered = transaksiBulanIni.where((t) {
      final matchesSearch = t.keterangan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "Semua" || t.kategori == _selectedCategory;
      final matchesWallet = _selectedWallet == "Semua" || t.walletNama == _selectedWallet;
      return matchesSearch && matchesCategory && matchesWallet;
    }).toList();

    Map<String, List<Transaksi>> grouped = {};
    for (var t in filtered) {
      String key = DateFormat('yyyy-MM-dd').format(t.tanggal);
      grouped[key] ??= [];
      grouped[key]!.add(t);
    }
    var keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (keys.isEmpty) {
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
                "Belum ada transaksi",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Mulai catat pengeluaran & pemasukanmu!",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: keys.map((dateKey) {
        var list = grouped[dateKey]!;
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
                    Text(DateFormat('E, dd/MM').format(DateTime.parse(dateKey)), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
                    "${(t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan') ? '+' : '-'}Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                    style: TextStyle(
                      color: (t.jenis.toLowerCase() == "masuk" || t.jenis.toLowerCase() == "pemasukan") ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 15, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: Colors.pink), onPressed: _prevMonth),
              Flexible(child: Text(DateFormat('MMMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(20)),
                    child: const Text("Month", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right, color: Colors.pink), onPressed: _nextMonth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"].map((day) {
              return Expanded(child: Center(child: Text(day, style: TextStyle(color: day == "Min" || day == "Sab" ? Colors.red.shade300 : Colors.grey, fontSize: 12))));
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildCalendarGrid(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: ["Pengeluaran", "Penghasilan", "Total"].map((mode) {
                bool isSelected = viewMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => viewMode = mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 5)] : null,
                      ),
                      child: Center(child: Text(mode, style: TextStyle(color: isSelected ? Colors.pink : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 11))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;
    List<Widget> dayWidgets = [];
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
      final isSelected = selectedDay.day == day && selectedDay.month == selectedDate.month && selectedDay.year == selectedDate.year;

      int income = transaksiBulanIni.where((t) => t.tanggal.day == day && (t.jenis == "masuk" || t.jenis == "pemasukan")).fold(0, (sum, t) => sum + t.jumlah);
      int expense = transaksiBulanIni.where((t) => t.tanggal.day == day && (t.jenis == "keluar" || t.jenis == "pengeluaran")).fold(0, (sum, t) => sum + t.jumlah);
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDay = DateTime(selectedDate.year, selectedDate.month, day);
            });
          },
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Container(
                    width: 28, height: 28,
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
                              : (isToday ? Colors.pink : (date.weekday == 7 || date.weekday == 6 ? Colors.red.shade400 : Colors.black87)), 
                          fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal, 
                          fontSize: 12
                        )
                      )
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (viewMode == "Total") ...[
                    if (income - expense != 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: (income - expense) > 0 ? Colors.green.shade400 : Colors.red.shade400, borderRadius: BorderRadius.circular(4)),
                          child: Text("${(income - expense) > 0 ? '' : '-'}${((income - expense).abs() / 1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ] else if (viewMode == "Penghasilan") ...[
                    if (income > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(4)),
                          child: Text("${(income / 1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.white, fontSize: 7)),
                        ),
                      ),
                  ] else if (viewMode == "Pengeluaran") ...[
                    if (expense > 0)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(4)),
                          child: Text("-${(expense / 1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.white, fontSize: 7)),
                        ),
                      ),
                  ],
                ],
              );
            }
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7, 
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(), 
      childAspectRatio: 0.85,
      children: dayWidgets
    );
  }


  Widget _buildBottomTotals() {
    final dayTransactions = transaksiBulanIni.where((t) => t.tanggal.day == selectedDay.day).toList();
    
    int totalIncome = dayTransactions.where((t) => t.jenis == "masuk" || t.jenis == "pemasukan").fold(0, (sum, t) => sum + t.jumlah);
    int totalExpense = dayTransactions.where((t) => t.jenis == "keluar" || t.jenis == "pengeluaran").fold(0, (sum, t) => sum + t.jumlah);
    
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id').format(selectedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr, 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)
              ),
              const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomTotalItem("Rp${NumberFormat.decimalPattern('id').format(totalIncome)}", "Masuk", Colors.green),
              _bottomTotalItem("Rp${NumberFormat.decimalPattern('id').format(totalExpense)}", "Keluar", Colors.red),
              _bottomTotalItem("Rp${NumberFormat.decimalPattern('id').format(totalIncome - totalExpense)}", "Selisih", Colors.pink),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (dayTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(Icons.money_off_rounded, color: Colors.grey.shade300, size: 40),
                    const SizedBox(height: 8),
                    const Text("Tidak ada transaksi pada tanggal ini", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayTransactions.length,
              itemBuilder: (context, index) {
                final t = dayTransactions[index];
                final catData = [...AppData.pengeluaranCategories, ...AppData.pemasukanCategories]
                    .firstWhere((c) => c.nama == t.kategori, orElse: () => TransactionCategory(nama: t.kategori, icon: Icons.category));
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    onTap: () {
                      _showTransactionOptions(t);
                    },
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
                    title: Text(t.keterangan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(t.walletNama, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    trailing: Text(
                      "${(t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan') ? '+' : '-'}Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                      style: TextStyle(
                        color: (t.jenis.toLowerCase() == "masuk" || t.jenis.toLowerCase() == "pemasukan") ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _bottomTotalItem(String amount, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
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
                // Handle bar
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                
                if ((t.itemsJson != null && t.itemsJson!.isNotEmpty) || t.receiptPath != null || t.receiptUrl != null) ...[
                  _buildModernOptionTile(
                    icon: Icons.receipt_long_rounded,
                    iconColor: Colors.pink,
                    title: "Lihat Rincian Item (Struk)",
                    subtitle: "Lihat rincian barang & foto struk",
                    onTap: () {
                      Navigator.pop(context);
                      _showReceiptDetailDialog(t);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _buildModernOptionTile(
                  icon: Icons.edit_rounded,
                  iconColor: Colors.blue,
                  title: "Edit Transaksi",
                  subtitle: "Ubah nominal, dompet, kategori, dll.",
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionInputPage(
                          initialJenis: t.jenis.toLowerCase() == 'masuk' ? 'masuk' : 'keluar',
                          initialTransaksi: t,
                        ),
                      ),
                    );
                    if (result == true) loadData();
                  },
                ),
                const SizedBox(height: 12),
                _buildModernOptionTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  title: "Hapus Transaksi",
                  subtitle: "Hapus transaksi ini secara permanen",
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

  Widget _buildModernOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
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
            child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteTransaksi(t);
              loadData();
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
                        loadData();
                      },
                    ),
                    duration: const Duration(seconds: 5),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            }, 
            child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showReceiptDetailDialog(Transaksi t) {
    List<dynamic> items = [];
    if (t.itemsJson != null && t.itemsJson!.isNotEmpty) {
      try {
        items = jsonDecode(t.itemsJson!);
      } catch (e) {
        // Abaikan; tampilkan foto struk saja bila ada
      }
    }
    final bool hasLocalPhoto = t.receiptPath != null && File(t.receiptPath!).existsSync();
    final bool hasRemotePhoto = t.receiptUrl != null && t.receiptUrl!.isNotEmpty;
    if (items.isEmpty && !hasLocalPhoto && !hasRemotePhoto) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Colors.pink, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        t.keterangan.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.8),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${t.kategori} • ${t.walletNama}",
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy, HH:mm').format(t.tanggal),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      if (hasLocalPhoto || hasRemotePhoto) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showFullReceiptPhoto(t, hasLocalPhoto),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: hasLocalPhoto
                                ? Image.file(
                                    File(t.receiptPath!),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    t.receiptUrl!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Container(
                                      height: 60,
                                      alignment: Alignment.center,
                                      color: Colors.grey.shade100,
                                      child: const Text("Foto struk tidak dapat dimuat", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Ketuk foto untuk memperbesar",
                          style: TextStyle(color: Colors.grey, fontSize: 9),
                        ),
                      ],
                      const SizedBox(height: 15),
                      const Text(
                        "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 10),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text("Tidak ada rincian item", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        )
                      else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final String name = item['nama'] ?? 'Item';
                            final int qty = (item['qty'] ?? 1) as int;
                            final int harga = (item['harga'] ?? 0) as int;
                            final int singlePrice = qty > 0 ? (harga / qty).round() : harga;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                        const SizedBox(height: 2),
                                        Text("$qty x Rp${NumberFormat.decimalPattern('id').format(singlePrice)}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "Rp${NumberFormat.decimalPattern('id').format(harga)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "- - - - - - - - - - - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          Text(
                            "Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullReceiptPhoto(Transaksi t, bool useLocalFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(
                maxScale: 5,
                child: useLocalFile
                    ? Image.file(File(t.receiptPath!), fit: BoxFit.contain)
                    : Image.network(
                        t.receiptUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Container(
                          padding: const EdgeInsets.all(30),
                          color: Colors.white,
                          child: const Text("Foto struk tidak dapat dimuat", style: TextStyle(color: Colors.grey)),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBanner({
    required String key,
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      key: ValueKey<String>(key),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ⏳ Shimmer Loading Skeleton Screen Helper (No Packages)
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + _controller.value * 2, -0.3),
              end: Alignment(1.0 + _controller.value * 2, 0.3),
            ),
          ),
        );
      },
    );
  }
}