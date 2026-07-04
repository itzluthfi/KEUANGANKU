import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk salin path laporan
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/app_data.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../services/exchange_service.dart';
import 'manage_category_page.dart';
import 'manage_wallet_page.dart';
import 'pin_lock_page.dart';
import 'manage_recurring_page.dart';
import 'notification_inbox_page.dart';
import 'package:lottie/lottie.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? _loggedInEmail;
  bool _checkingLogin = true;

  // State untuk fitur-fitur baru
  int _monthlyBudget = 0;
  int _monthlyExpense = 0;
  String _reminderTime = "20:00";
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCustomSettings();
  }

  Future<void> _checkLoginStatus() async {
    final email = await SyncService.instance.getLoggedInUser();
    setState(() {
      _loggedInEmail = email;
      _checkingLogin = false;
    });
  }

  Future<void> _loadCustomSettings() async {
    // 1. Ambil batasan anggaran bulanan
    final budgetStr = await DatabaseHelper.instance.getSetting('monthly_budget');
    final budget = int.tryParse(budgetStr ?? "0") ?? 0;

    // 2. Ambil waktu pengingat harian
    final reminder = await DatabaseHelper.instance.getSetting('reminder_time');
    
    // 3. Hitung total pengeluaran bulan ini
    final all = await DatabaseHelper.instance.fetchTransaksi();
    final now = DateTime.now();
    final expense = all
        .where((t) => t.tanggal.month == now.month && t.tanggal.year == now.year && (t.jenis.toLowerCase() == "keluar" || t.jenis.toLowerCase() == "pengeluaran"))
        .fold(0, (sum, t) => sum + t.jumlah);

    // 4. Ambil status kunci PIN
    final pinEnabledStr = await DatabaseHelper.instance.getSetting('pin_enabled');

    setState(() {
      _monthlyBudget = budget;
      _reminderTime = reminder ?? "20:00";
      _monthlyExpense = expense;
      _pinEnabled = pinEnabledStr == 'true';
    });
  }

  Future<bool?> _showStyledConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = Colors.pink,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return showDialog<bool>(
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
                  decoration: BoxDecoration(
                    color: confirmColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: confirmColor, size: 45),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("Batal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                confirmLabel,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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

  Future<void> _showStyledInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    Color accentColor = Colors.pink,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return showDialog<void>(
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
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: accentColor, size: 45),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Tutup",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
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

  void _resetData(BuildContext context) async {
    bool confirm = await _showStyledConfirmDialog(
      context: context,
      title: "Reset Data",
      message: "Apakah Anda yakin ingin menghapus semua transaksi dan mereset saldo dompet ke Utama (0)? Tindakan ini menghapus data di HP Anda secara lokal.",
      confirmLabel: "Ya, Reset",
      confirmColor: Colors.red,
      icon: Icons.warning_amber_rounded,
    ) ?? false;

    if (confirm == true) {
      await DatabaseHelper.instance.resetData();
      AppData.transaksi.clear();
      AppData.wallets = [
        Wallet(nama: "Utama", saldo: 0, jenis: "Akun Virtual", icon: Icons.account_balance_wallet)
      ];
      _loadCustomSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data lokal berhasil direset ke nol."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LoginBottomSheet(),
    ).then((success) {
      if (success == true) {
        _checkLoginStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil menghubungkan ke Awan Danaku!"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          )
        );
      }
    });
  }

  void _handleLogout() async {
    bool confirm = await _showStyledConfirmDialog(
      context: context,
      title: "Keluar Akun Awan",
      message: "Apakah Anda yakin ingin memutuskan sambungan dari Awan Danaku? Data lokal Anda tidak akan terhapus.",
      confirmLabel: "Keluar",
      confirmColor: Colors.red.shade400,
      icon: Icons.logout_rounded,
    ) ?? false;

    if (confirm == true) {
      await SyncService.instance.logout();
      _checkLoginStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sambungan awan diputuskan."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueGrey,
          )
        );
      }
    }
  }

  void _triggerBackup() async {
    if (_loggedInEmail == null) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SyncProgressDialog(
        actionType: "backup",
        email: _loggedInEmail!,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pencadangan selesai! Data Anda aman."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        )
      );
    }
  }

  void _triggerRestore() async {
    if (_loggedInEmail == null) return;

    bool confirm = await _showStyledConfirmDialog(
      context: context,
      title: "Pulihkan Data",
      message: "Tindakan ini akan menimpa seluruh transaksi & dompet lokal di HP ini dengan data cadangan terbaru Anda di Awan Danaku. Lanjutkan?",
      confirmLabel: "Ya, Pulihkan",
      confirmColor: Colors.blue,
      icon: Icons.cloud_download_outlined,
    ) ?? false;

    if (confirm != true) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SyncProgressDialog(
        actionType: "restore",
        email: _loggedInEmail!,
      ),
    );

    if (result == true && mounted) {
      _loadCustomSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pemulihan selesai! Data keuangan diperbarui."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        )
      );
    }
  }

  /// =========================================================================
  /// 🎛️ BAGIAN 3: AKSI UNTUK GRID MENU ITEM
  /// =========================================================================

  // 1. Kotak Pesan
  void _showInboxDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_unread_rounded, color: Colors.pink, size: 36),
                    const SizedBox(height: 10),
                    const Text(
                      "Kotak Pesan",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.maxFinite,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            _buildMessageItem(
                              title: "Selamat Datang di Danaku!",
                              body: "Mulai kelola keuangan bulanan Anda dengan mudah. Jangan lupa atur target Anggaran Anda di grid menu!",
                              time: "Baru saja",
                              isNew: true,
                            ),
                            const Divider(),
                            _buildMessageItem(
                              title: "💡 Tips Keuangan Pekan Ini",
                              body: "Mencatat transaksi kecil seperti parkir atau kopi membantu melacak 15% kebocoran dana bulanan Anda.",
                              time: "1 hari yang lalu",
                              isNew: false,
                            ),
                            const Divider(),
                            _buildMessageItem(
                              title: "☁️ Fitur Awan Aktif",
                              body: "Sekarang Anda dapat mencadangkan seluruh data transaksi ke server Awan Danaku dengan opsional menggunakan Email.",
                              time: "2 hari yang lalu",
                              isNew: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem({required String title, required String body, required String time, required bool isNew}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isNew ? Colors.pink : Colors.black87)),
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("Baru", style: TextStyle(color: Colors.pink, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  // 2. Kategori Selection Sheet
  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Kelola Kategori Transaksi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_circle_up_rounded, color: Colors.red),
            ),
            title: const Text("Kategori Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Kelola kategori belanja, bensin, dll."),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageCategoryPage(jenis: 'keluar')),
              ).then((_) => _loadCustomSettings());
            },
          ),
          const Divider(indent: 70),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_circle_down_rounded, color: Colors.green),
            ),
            title: const Text("Kategori Pemasukan", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Kelola kategori gaji, uang saku, bonus, dll."),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageCategoryPage(jenis: 'masuk')),
              ).then((_) => _loadCustomSettings());
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 3. Dompet Navigation
  void _navigateToDompet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageWalletPage()),
    ).then((_) => _loadCustomSettings());
  }

  // 4. Tukar Mata Uang Live Converter Dialog
  void _showExchangeDialog() {
    showDialog(
      context: context,
      builder: (context) => const _ExchangeDialog(),
    );
  }

  // 5. Atur Anggaran Bulanan Dialog
  void _showBudgetDialog() {
    final controller = TextEditingController(text: _monthlyBudget > 0 ? _monthlyBudget.toString() : "");
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.track_changes_rounded, color: Colors.pink, size: 36),
                    const SizedBox(height: 10),
                    const Text(
                      "Anggaran Bulanan",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Atur limit pengeluaran bulanan Anda untuk mendisiplinkan keuangan.",
                      style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: "Rp ",
                        labelText: "Limit Bulanan",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text("Batal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final newBudget = int.tryParse(controller.text) ?? 0;
                              await DatabaseHelper.instance.saveSetting('monthly_budget', newBudget.toString());
                              _loadCustomSettings();
                              if (context.mounted) Navigator.pop(context);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Batas anggaran berhasil diperbarui!"),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.pink,
                                  )
                                );
                              }
                            },
                            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. Pengingat Harian
  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Colors.pink, size: 36),
                    const SizedBox(height: 10),
                    const Text(
                      "Pengingat Harian",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Ingatkan saya setiap hari untuk mencatat pengeluaran agar laporan tetap akurat.",
                      style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Waktu Pengingat:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                          Text(_reminderTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.pink)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.pink,
                          side: const BorderSide(color: Colors.pink),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.notifications_active_outlined, size: 18),
                        label: const Text("Kirim Notifikasi Uji Coba", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                            await NotificationService.instance.requestPermissions();
                            await NotificationService.instance.showInstantNotification();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text("Tutup", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              final timeParts = _reminderTime.split(":");
                              final hour = int.tryParse(timeParts[0]) ?? 20;
                              final minute = int.tryParse(timeParts[1]) ?? 0;

                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: hour, minute: minute),
                              );

                              if (picked != null) {
                                final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                await DatabaseHelper.instance.saveSetting('reminder_time', formatted);
                                _loadCustomSettings();
                                
                                if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                                  await NotificationService.instance.requestPermissions();
                                  await NotificationService.instance.scheduleDailyNotification(picked.hour, picked.minute);
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Pengingat diubah ke pukul $formatted!"),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.pink,
                                    )
                                  );
                                }
                              }
                            },
                            child: const Text("Ubah Jam", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 7. Ekspor Laporan Keuangan (Excel, PDF, CSV)
  void _showExportOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            const Text(
              "Ekspor Laporan Keuangan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pilih format laporan transaksi keuangan yang Anda inginkan.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.table_rows_rounded, color: Colors.green),
              ),
              title: const Text("Format Excel (.xlsx)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Laporan rapi siap olah di Microsoft Excel atau Google Sheets"),
              onTap: () {
                Navigator.pop(context);
                _runExportProcess("excel");
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              ),
              title: const Text("Format PDF (.pdf)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Format cetak dokumen resmi yang rapi dengan tabel"),
              onTap: () {
                Navigator.pop(context);
                _runExportProcess("pdf");
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.insert_drive_file_rounded, color: Colors.blue),
              ),
              title: const Text("Format CSV (.csv)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Format teks raw terpisah koma yang sangat ringan"),
              onTap: () {
                Navigator.pop(context);
                _runExportProcess("csv");
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _runExportProcess(String format) async {
    String formatName = format.toUpperCase();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(width: 20),
              Expanded(
                child: Text("Mengekspor transaksi ke $formatName..."),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      String path;
      if (format == "excel") {
        path = await ExportService.exportTransaksiToExcel();
      } else if (format == "pdf") {
        path = await ExportService.exportTransaksiToPDF();
      } else {
        path = await ExportService.exportTransaksiToCSV();
      }
      
      if (context.mounted) Navigator.pop(context); // Tutup dialog loading
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("Ekspor Sukses!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Data transaksi sukses diekspor ke format $formatName.", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Anda dapat membagikan berkas laporan ini atau menyimpannya langsung ke File Manager ponsel Anda.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Share.shareXFiles([XFile(path)], text: "Laporan Keuangan Danaku ($formatName)");
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share, size: 18, color: Colors.blue),
                  SizedBox(width: 6),
                  Text("Bagikan Berkas", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Selesai", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Ekspor Gagal"),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
          ],
        ),
      );
    }
  }

  // 8. Tentang
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: "Danaku App",
      applicationVersion: "v1.2.0 (Plus Menu)",
      applicationIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Color(0xFFFF528F), shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
      ),
      applicationLegalese: "© 2026 Danaku Developer Team. Dilengkapi modul pencadangan awan opsional dan alat pencatatan keuangan modern.",
    );
  }

  void _navigateToRecurring() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageRecurringPage()),
    ).then((_) => _loadCustomSettings());
  }

  void _showPinSettingDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: Colors.pink),
                  SizedBox(width: 10),
                  Text("Kunci PIN Keamanan", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Lindungi catatan keuangan Anda dengan PIN 4-digit setiap kali aplikasi dibuka.",
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Aktifkan Kunci PIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    activeColor: Colors.pink,
                    value: _pinEnabled,
                    onChanged: (val) async {
                      if (val) {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PinLockPage()),
                        );
                        if (result == true) {
                          _loadCustomSettings();
                        }
                      } else {
                        await DatabaseHelper.instance.saveSetting('pin_enabled', 'false');
                        setDialogState(() {
                          _pinEnabled = false;
                        });
                        _loadCustomSettings();
                      }
                    },
                  ),
                  if (_pinEnabled) ...[
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.password_rounded, color: Colors.pink),
                      title: const Text("Ubah PIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("Ganti PIN lama dengan PIN baru", style: TextStyle(fontSize: 11)),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PinLockPage()),
                        );
                        if (result == true) {
                          _loadCustomSettings();
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
                ),
              ],
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
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        title: const Text("Pengaturan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationInboxPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 20),
              
              ValueListenableBuilder<bool>(
                valueListenable: SyncService.instance.connectionStatus,
                builder: (context, isOnline, child) {
                  if (isOnline) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.orange.shade800),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Anda sedang Offline. Fitur sinkronisasi Awan & kecerdasan buatan (AI) dinonaktifkan sementara.",
                            style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ☁️ KARTU KONEKSI AWAN (CLOUD BACKUP CARD)
              _checkingLogin
                  ? const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFFF528F))),
                    )
                  : _buildCloudSyncCard(isTablet),
              
              const SizedBox(height: 25),

              // 📊 PROGRESS ANGGARAN BULANAN (BUDGET BAR) - Hanya muncul jika batas anggaran diset > 0
              if (_monthlyBudget > 0) ...[
                _buildBudgetProgressBar(),
                const SizedBox(height: 25),
              ],
              
              // 🛠️ GRID MENU FITUR "LEBIH" (2-3 KOLOM PASTEL)
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text("FITUR UTAMA & LAYANAN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              ),
              GridView.count(
                crossAxisCount: isTablet ? 4 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
                children: [
                  GridMenuItem(
                    lottieAsset: "assets/icons/mail.json",
                    label: "Kotak Pesan",
                    onTap: _showInboxDialog,
                  ),
                  GridMenuItem(
                    icon: Icons.category_rounded,
                    label: "Kategori",
                    onTap: _showCategorySelection,
                  ),
                  GridMenuItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: "Dompet",
                    onTap: _navigateToDompet,
                  ),
                  GridMenuItem(
                    lottieAsset: "assets/icons/explore.json",
                    label: "Tukar Kurs",
                    onTap: _showExchangeDialog,
                  ),
                  GridMenuItem(
                    lottieAsset: "assets/icons/activity.json",
                    label: "Anggaran",
                    onTap: _showBudgetDialog,
                  ),
                  GridMenuItem(
                    lottieAsset: "assets/icons/notification.json",
                    label: "Pengingat",
                    onTap: _showReminderDialog,
                  ),
                  GridMenuItem(
                    lottieAsset: "assets/icons/download.json",
                    label: "Ekspor Laporan",
                    onTap: _showExportOptionsSheet,
                  ),
                  GridMenuItem(
                    lottieAsset: "assets/icons/archive.json",
                    label: "Transaksi Berulang",
                    onTap: _navigateToRecurring,
                  ),
                  GridMenuItem(
                    lottieAsset: "assets/icons/lock.json",
                    label: "Kunci PIN",
                    onTap: _showPinSettingDialog,
                  ),
                  GridMenuItem(
                    lottieAsset: "assets/icons/info.json",
                    label: "Tentang",
                    onTap: _showAbout,
                  ),
                ],
              ),
              
              const SizedBox(height: 25),

              // 🚫 RESET DATA & KELUAR
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text("SISTEM", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              ),
              Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  onTap: () => _resetData(context),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.refresh, color: Colors.red),
                  ),
                  title: const Text("Reset Semua Data", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  subtitle: const Text("Hapus transaksi & nol-kan saldo lokal", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

}

// Stateful Grid Menu Item to control Lottie animation speed and loop timing
class GridMenuItem extends StatefulWidget {
  final String? lottieAsset;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  const GridMenuItem({
    super.key,
    this.lottieAsset,
    this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<GridMenuItem> createState() => _GridMenuItemState();
}

class _GridMenuItemState extends State<GridMenuItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.pink.shade50;
    Color iconColor = Colors.pink;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 1.5,
        shadowColor: Colors.black12,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: widget.lottieAsset != null ? const EdgeInsets.all(10) : const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: widget.lottieAsset != null
                  ? SizedBox(
                      width: 26,
                      height: 26,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                        child: Lottie.asset(
                          widget.lottieAsset!,
                          controller: _controller,
                          onLoaded: (composition) {
                            // Slow down duration of the loop to 2x composition duration to prevent glitching
                            _controller.duration = composition.duration * 2.2;
                            _controller.repeat();
                          },
                        ),
                      ),
                    )
                  : Icon(widget.icon ?? Icons.help_outline, color: iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // Progres Bar untuk Budget limit bulanan
  Widget _buildBudgetProgressBar() {
    double ratio = _monthlyExpense / _monthlyBudget;
    if (ratio > 1.0) ratio = 1.0;
    bool isOver = _monthlyExpense > _monthlyBudget;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Anggaran Bulanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                isOver ? "Limit Terlampaui!" : "Aman",
                style: TextStyle(
                  color: isOver ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              color: isOver ? Colors.redAccent : Colors.teal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Terpakai: Rp${NumberFormat.decimalPattern('id').format(_monthlyExpense)}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              Text(
                "Limit: Rp${NumberFormat.decimalPattern('id').format(_monthlyBudget)}",
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCloudSyncCard(bool isTablet) {
    final bool isOffline = _loggedInEmail == null;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOffline
              ? [Colors.pink.shade300, Colors.pink.shade600] // Pink Offline
              : [Colors.pink.shade400, Colors.pink.shade800], // Pink Active
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isOffline ? Colors.pink.shade300 : Colors.pink.shade400).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background Cloud Shapes Decoration
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(Icons.cloud_queue, size: 160, color: Colors.white.withOpacity(0.12)),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOffline ? "Mode Offline" : "Awan Terhubung",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (!isOffline)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 22),
                        tooltip: "Keluar Akun Awan",
                        onPressed: _handleLogout,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                isOffline
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Amankan Data Keuangan Anda",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Masuk/Daftar untuk mengaktifkan fitur pencadangan data otomatis di server Awan Danaku.",
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            child: Text(
                              _loggedInEmail![0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _loggedInEmail!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Pencadangan Awan Aktif",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                
                // Cloud Sync Buttons Action
                isOffline
                    ? SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.pink.shade700,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _showLoginSheet,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined),
                              SizedBox(width: 10),
                              Text("Masuk / Daftar Akun Awan", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _triggerBackup,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload, size: 18),
                                    SizedBox(width: 8),
                                    Text("Cadangkan", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.pink.shade700,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _triggerRestore,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_download, size: 18),
                                    SizedBox(width: 8),
                                    Text("Pulihkan", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================================================================
/// 👥 DIALOG LIVE TUKAR KURS MATA UANG (REAL & CONVERTER)
/// =========================================================================
class _ExchangeDialog extends StatefulWidget {
  const _ExchangeDialog();

  @override
  State<_ExchangeDialog> createState() => _ExchangeDialogState();
}

class _ExchangeDialogState extends State<_ExchangeDialog> {
  final _inputController = TextEditingController();
  
  bool _loading = true;
  String _errorMsg = "";
  
  double usdToIdr = 15850.0;
  double eurToIdr = 17150.0;
  double sgdToIdr = 11750.0;

  double _convertedResult = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchLiveRates();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _fetchLiveRates() async {
    try {
      final data = await ExchangeService().fetchRates();
      final rates = data['rates'] as Map<String, dynamic>;
      final idr = (rates['IDR'] as num).toDouble();
      final eur = (rates['EUR'] as num).toDouble();
      final sgd = (rates['SGD'] as num).toDouble();

      setState(() {
        usdToIdr = idr;
        eurToIdr = idr / eur;
        sgdToIdr = idr / sgd;
        _loading = false;
      });
    } catch (e) {
      // Graceful fallback ke offline default rates jika offline / error API
      setState(() {
        _loading = false;
        // Tetap menggunakan rates default tetapi menampilkan info fallback offline
      });
    }
  }

  void _doConversion() {
    final value = double.tryParse(_inputController.text) ?? 0.0;
    setState(() {
      _convertedResult = value * usdToIdr;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.currency_exchange_rounded, color: Colors.pink),
          SizedBox(width: 10),
          Text("Kurs Mata Uang", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: _loading
          ? const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator(color: Colors.pink)),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Harga Tukar Live Rupiah (IDR):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 10),
                  _buildRateTile("1 USD (Dolar AS)", usdToIdr, Colors.green),
                  _buildRateTile("1 EUR (Euro)", eurToIdr, Colors.blue),
                  _buildRateTile("1 SGD (Dolar Singapura)", sgdToIdr, Colors.purple),
                  
                  const Divider(height: 24),
                  
                  const Text("Kalkulator Konverter (USD ➡️ IDR):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _doConversion(),
                    decoration: InputDecoration(
                      prefixText: "\$ ",
                      labelText: "Jumlah USD",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  if (_convertedResult > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        "= Rp${NumberFormat.decimalPattern('id').format(_convertedResult.round())}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink),
                      ),
                    ),
                  ]
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildRateTile(String currency, double rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(currency, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(
            "Rp${NumberFormat.decimalPattern('id').format(rate.round())}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

/// =========================================================================
/// 📋 BOTTOM SHEET UNTUK FORM LOGIN & DAFTAR
/// =========================================================================
class _LoginBottomSheet extends StatefulWidget {
  const _LoginBottomSheet();

  @override
  State<_LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<_LoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _processing = false;
  bool _obscurePassword = true;
  String _errorMsg = "";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _processing = true;
      _errorMsg = "";
    });

    final email = _emailController.text.trim();
    final pwd = _passwordController.text;
    bool success;

    if (_isLoginMode) {
      success = await SyncService.instance.login(email, pwd);
      if (!success) {
        setState(() {
          _errorMsg = "Email belum terdaftar atau password salah.";
          _processing = false;
        });
      }
    } else {
      success = await SyncService.instance.register(email, pwd);
      if (!success) {
        setState(() {
          _errorMsg = "Pendaftaran gagal. Silakan coba lagi.";
          _processing = false;
        });
      }
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Indicator handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 25),
              
              Text(
                _isLoginMode ? "Masuk ke Awan Danaku" : "Buat Akun Awan Danaku",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isLoginMode
                    ? "Masukkan email cadangan Anda untuk mengunduh data Anda kembali."
                    : "Akun ini digunakan untuk melacak dan menyimpan file cadangan Anda.",
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              
              if (_errorMsg.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 15),
              
              // Email Input Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: "Alamat Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Email wajib diisi";
                  }
                  if (!value.contains("@")) {
                    return "Format email tidak valid (wajib menggunakan @)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Password Input Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  labelText: "Kata Sandi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Kata sandi wajib diisi";
                  }
                  if (value.length < 6) {
                    return "Kata sandi minimal 6 karakter";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF528F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                  ),
                  onPressed: _processing ? null : _handleSubmit,
                  child: _processing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : Text(
                          _isLoginMode ? "Hubungkan Akun" : "Daftar Akun Baru",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Toggle Login/Register Mode
              Center(
                child: TextButton(
                  onPressed: _processing
                      ? null
                      : () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _errorMsg = "";
                          });
                        },
                  child: Text(
                    _isLoginMode
                        ? "Belum memiliki akun Awan? Daftar Sekarang"
                        : "Sudah memiliki akun Awan? Masuk Sekarang",
                    style: const TextStyle(color: Color(0xFFFF528F), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =========================================================================
/// 🌀 DIALOG SPINNER PROGRES SINKRONISASI INTERAKTIF
/// =========================================================================
class _SyncProgressDialog extends StatefulWidget {
  final String actionType; // "backup" atau "restore"
  final String email;

  const _SyncProgressDialog({required this.actionType, required this.email});

  @override
  State<_SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<_SyncProgressDialog> {
  int currentStep = 0;
  bool isSuccess = false;
  bool isError = false;
  String errorMessage = "";

  late List<String> steps;

  @override
  void initState() {
    super.initState();
    if (widget.actionType == "backup") {
      steps = [
        "Menghubungkan ke Awan Danaku...",
        "Mengompresi data transaksi lokal...",
        "Mengamankan data dengan enkripsi...",
        "Mengunggah berkas cadangan...",
      ];
    } else {
      steps = [
        "Menghubungkan ke Awan Danaku...",
        "Mengunduh berkas cadangan terbaru...",
        "Mendekripsi data payload...",
        "Sinkronisasi dengan database SQLite...",
      ];
    }
    _runSync();
  }

  void _runSync() async {
    try {
      // Loop simulator untuk status visual dinamis
      for (int i = 0; i < steps.length; i++) {
        if (!mounted) return;
        setState(() {
          currentStep = i;
        });
        await Future.delayed(const Duration(milliseconds: 650));
      }

      if (widget.actionType == "backup") {
        await SyncService.instance.backupData(widget.email);
      } else {
        bool success = await SyncService.instance.restoreData(widget.email);
        if (!success) {
          throw Exception("Tidak ditemukan data cadangan untuk email ini.");
        }
      }

      if (!mounted) return;
      setState(() {
        isSuccess = true;
      });
      
      // Delay sejenak agar visual sukses checkmark terlihat puas
      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isError = true;
        errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError) ...[
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 18),
              const Text("Sinkronisasi Gagal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Tutup"),
                ),
              ),
            ] else if (isSuccess) ...[
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 68),
              const SizedBox(height: 18),
              Text(
                widget.actionType == "backup" ? "Pencadangan Berhasil!" : "Pemulihan Berhasil!",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                widget.actionType == "backup"
                    ? "Seluruh catatan transaksi lokal Anda kini aman tersimpan di Awan."
                    : "Data SQLite lokal telah diperbarui dengan file cadangan awan Anda.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
            ] else ...[
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF528F),
                  strokeWidth: 4.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.actionType == "backup" ? "Mencadangkan Data" : "Memulihkan Data",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  steps[currentStep],
                  key: ValueKey<int>(currentStep),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / steps.length,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFFFF528F),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
