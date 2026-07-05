import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import 'manage_category_page.dart';
import 'package:intl/intl.dart';
import '../services/exchange_service.dart';
import '../services/sync_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import '../widgets/custom_snackbar.dart';

class TransactionInputPage extends StatefulWidget {
  final String initialJenis;
  final Transaksi? initialTransaksi;

  const TransactionInputPage({super.key, required this.initialJenis, this.initialTransaksi});

  @override
  State<TransactionInputPage> createState() => _TransactionInputPageState();
}

class _TransactionInputPageState extends State<TransactionInputPage> with SingleTickerProviderStateMixin {
  late String jenis;
  TransactionCategory? selectedCategory;
  String nominal = "0";
  TextEditingController keteranganController = TextEditingController();
  List<TransactionCategory> categories = [];
  DateTime selectedDate = DateTime.now();
  
  String selectedCurrency = "IDR";
  double usdToIdr = 16000.0;
  bool isLoadingRate = false;
  Wallet? selectedWallet;
  Wallet? selectedWalletTujuan;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isScanningReceipt = false;
  bool _isProcessingVoice = false;
  String _spokenText = "";
  
  int _currentSttHintIndex = 0;
  List<String> _sttHints = [];
  Timer? _sttHintTimer;
  String? _scannedReceiptName;
  List<dynamic>? _activeItems;

  late AnimationController _pulseController;
  final List<Transaksi> _queuedTransactions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaksi != null) {
      final t = widget.initialTransaksi!;
      jenis = t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan' ? 'masuk' : 'keluar';
      nominal = t.jumlah.toString();
      keteranganController.text = t.keterangan;
      selectedDate = t.tanggal;
      selectedWallet = AppData.wallets.firstWhere((w) => w.nama == t.walletNama, orElse: () => AppData.wallets.first);
      if (t.itemsJson != null && t.itemsJson!.isNotEmpty) {
        try {
          _activeItems = jsonDecode(t.itemsJson!);
        } catch (e) {
          debugPrint("Error decoding itemsJson in initState: $e");
        }
      }
    } else {
      jenis = widget.initialJenis;
      if (AppData.wallets.isNotEmpty) {
        selectedWallet = AppData.wallets.first;
      }
    }
    if (AppData.wallets.length > 1) {
      selectedWalletTujuan = AppData.wallets[1];
    } else if (AppData.wallets.isNotEmpty) {
      selectedWalletTujuan = AppData.wallets.first;
    }

    _loadCategories();
    _loadLastRate();

    _sttHints = [
      "Bicara: 'Makan siang 20 ribu'",
      "Bicara: 'Terima uang saku 100 ribu'",
      "Bicara: 'Beli bensin 30 ribu dari dompet Utama'",
      "Bicara: 'Kopi susu 15000 rupiah'",
    ];
    _sttHintTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentSttHintIndex = (_currentSttHintIndex + 1) % _sttHints.length;
        });
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sttHintTimer?.cancel();
    keteranganController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLastRate() async {
    final rate = await DatabaseHelper.instance.getLastRate();
    if (rate > 0) {
      setState(() => usdToIdr = rate);
    }
  }

  Future<void> _showWalletPicker() async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Dompet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              ...AppData.wallets.map((w) => ListTile(
                leading: Icon(w.icon, color: Colors.pink),
                title: Text(w.nama),
                trailing: Text("Rp${NumberFormat.decimalPattern('id').format(w.saldo)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  setState(() => selectedWallet = w);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchRate() async {
    setState(() => isLoadingRate = true);
    try {
      final data = await ExchangeService().fetchRates();
      if (data.containsKey('rates') && data['rates'].containsKey('IDR')) {
        double newRate = data['rates']['IDR'].toDouble();
        setState(() => usdToIdr = newRate);
        await DatabaseHelper.instance.saveLastRate(newRate);
      }
    } catch (e) {
      debugPrint("Gagal fetch rate: $e");
    } finally {
      setState(() => isLoadingRate = false);
    }
  }

  Future<void> _loadCategories() async {
    final list = await DatabaseHelper.instance.fetchCategories(jenis);
    setState(() {
      categories = list;
      if (widget.initialTransaksi != null) {
        selectedCategory = categories.firstWhere(
          (c) => c.nama == widget.initialTransaksi!.kategori,
          orElse: () => categories.isNotEmpty ? categories.first : TransactionCategory(nama: "Unknown", icon: Icons.category),
        );
      } else if (categories.isNotEmpty) {
        selectedCategory = categories.first;
      } else {
        selectedCategory = null;
      }
    });
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pink,
              onPrimary: Colors.white,
              onSurface: Colors.pink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.pink,
                onPrimary: Colors.white,
                onSurface: Colors.pink,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _scanReceipt() async {
    final isOnline = SyncService.instance.connectionStatus.value;
    if (!isOnline) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text("Koneksi Diperlukan"),
              ],
            ),
            content: const Text(
              "Fitur pengurai struk belanja dengan kecerdasan buatan (AI) memerlukan koneksi internet aktif untuk menghubungi server Danaku.",
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Scan Struk Belanja",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.pink.shade100),
                          ),
                          child: const Text(
                            "by AI",
                            style: TextStyle(
                              color: Colors.pink,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.pink),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Row(
                              children: const [
                                Icon(Icons.auto_awesome, color: Colors.pink),
                                SizedBox(width: 8),
                                Text("Cara Kerja AI Scan", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            content: const Text(
                              "1. Ambil foto struk belanja Anda dengan kamera atau pilih dari galeri.\n\n"
                              "2. AI OCR akan mendeteksi nominal total belanja, tanggal, kategori transaksi, dan nama toko secara otomatis.\n\n"
                              "3. Transaksi Anda akan terisi otomatis ke dalam form tanpa perlu mengetik manual.\n\n"
                              "Tips: Pastikan teks pada struk terlihat jelas, tidak kabur, dan mendapat cahaya yang cukup agar akurasi AI maksimal.",
                              style: TextStyle(height: 1.4, fontSize: 14),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Mengerti", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.pink),
                title: const Text("Kamera"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.pink),
                title: const Text("Galeri Foto"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() => _isScanningReceipt = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${SyncService.instance.laravelBaseUrl}/ai/parse-receipt'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', pickedFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        _showReceiptItemsBottomSheet(data);
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? "Gagal memproses struk.";
        if (!mounted) return;
        CustomSnackBar.show(context, message: "Error AI: $errorMsg", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(context, message: "Koneksi gagal: $e", isError: true);
    } finally {
      setState(() => _isScanningReceipt = false);
    }
  }

  Future<void> _toggleListening() async {
    final isOnline = SyncService.instance.connectionStatus.value;
    if (!isOnline) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text("Koneksi Diperlukan"),
              ],
            ),
            content: const Text(
              "Fitur pengurai teks transaksi berbasis suara (AI) memerlukan koneksi internet aktif untuk menghubungi server Danaku.",
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Tutup", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        debugPrint('Speech Status: $val');
        if (val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) {
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
      },
    );

    if (!available) {
      if (mounted) {
        CustomSnackBar.show(context, message: "Perekam suara tidak tersedia di perangkat Anda.", isError: true);
      }
      return;
    }

    setState(() {
      _isListening = true;
      _spokenText = "";
    });

    _speech.listen(
      onResult: (val) {
        setState(() {
          _spokenText = val.recognizedWords;
        });
      },
      localeId: "id_ID",
    );

    if (!mounted) return;
  }

  Future<void> _processVoiceCommand(String text) async {
    setState(() => _isProcessingVoice = true);

    try {
      final response = await http.post(
        Uri.parse('${SyncService.instance.laravelBaseUrl}/ai/parse-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          nominal = data['jumlah'].toString();
          keteranganController.text = data['keterangan'];
          jenis = data['jenis'];
          _activeItems = data['items'];
          selectedDate = safeParseDate(data['tanggal']);
        });

        await _loadCategories();

        setState(() {
          selectedCategory = categories.firstWhere(
            (c) => c.nama.toLowerCase() == data['kategori'].toString().toLowerCase(),
            orElse: () => categories.isNotEmpty ? categories.first : categories.first,
          );
        });

        if (!mounted) return;
        CustomSnackBar.show(
          context,
          message: "Suara diproses: \"$text\"",
          isSuccess: true,
        );

        // If voice command contains multiple sub-items, show review bottom sheet
        if (data['items'] != null && (data['items'] as List).length > 1) {
          _showReceiptItemsBottomSheet(data);
        }
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? "Gagal memproses suara.";
        if (!mounted) return;
        CustomSnackBar.show(
          context,
          message: "Error AI: $errorMsg",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        message: "Koneksi gagal: $e",
        isError: true,
      );
    } finally {
      setState(() => _isProcessingVoice = false);
    }
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == "DEL") {
        if (nominal.length > 1) {
          nominal = nominal.substring(0, nominal.length - 1);
        } else {
          nominal = "0";
        }
      } else if (value == ".") {
        if (!nominal.contains(".")) {
          nominal += ".";
        }
      } else {
        if (nominal == "0") {
          nominal = value;
        } else {
          if (nominal.length < 15) {
            nominal += value;
          }
        }
      }
    });
  }

  DateTime safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        final clean = dateStr.trim();
        final parts = clean.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (_) {}
      return DateTime.now();
    }
  }

  Future<void> _saveTransaction() async {
    double? parsedAmount = double.tryParse(nominal);
    double baseAmount = parsedAmount ?? 0;
    int currentJumlah = selectedCurrency == "USD" ? (baseAmount * usdToIdr).toInt() : baseAmount.toInt();

    if (currentJumlah <= 0) {
      CustomSnackBar.show(context, message: "Nominal harus lebih dari 0", isError: true);
      return;
    }

    if (widget.initialTransaksi != null) {
      // MODE EDIT
      if (jenis != 'transfer' && selectedCategory == null) {
        CustomSnackBar.show(context, message: "Pilih kategori terlebih dahulu", isError: true);
        return;
      }
      if (selectedWallet == null) {
        CustomSnackBar.show(context, message: "Pilih dompet terlebih dahulu", isError: true);
        return;
      }

      final updated = Transaksi(
        id: widget.initialTransaksi!.id,
        keterangan: keteranganController.text.isEmpty ? selectedCategory!.nama : keteranganController.text,
        jumlah: currentJumlah,
        jenis: jenis,
        tanggal: selectedDate,
        walletNama: selectedWallet!.nama,
        kategori: selectedCategory!.nama,
        itemsJson: _activeItems != null ? jsonEncode(_activeItems) : null,
      );

      try {
        await DatabaseHelper.instance.updateTransaksi(widget.initialTransaksi!, updated);
        if (mounted) {
          CustomSnackBar.show(context, message: "Transaksi berhasil diperbarui!", isSuccess: true);
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(context, message: "Gagal memperbarui transaksi: $e", isError: true);
        }
      }
      return;
    }

    // MODE INPUT BARU
    if (jenis == 'transfer') {
      if (selectedWalletTujuan == null || selectedWallet == null) {
        CustomSnackBar.show(context, message: "Pilih dompet asal dan tujuan", isError: true);
        return;
      }
      if (selectedWallet!.nama == selectedWalletTujuan!.nama) {
        CustomSnackBar.show(context, message: "Dompet asal dan tujuan tidak boleh sama", isError: true);
        return;
      }
      
      _queuedTransactions.add(Transaksi(
        keterangan: keteranganController.text.isEmpty ? "Transfer ke ${selectedWalletTujuan!.nama}" : keteranganController.text,
        jumlah: currentJumlah,
        jenis: "keluar",
        tanggal: selectedDate,
        walletNama: selectedWallet!.nama,
        kategori: "Transfer",
      ));
      _queuedTransactions.add(Transaksi(
        keterangan: keteranganController.text.isEmpty ? "Transfer dari ${selectedWallet!.nama}" : keteranganController.text,
        jumlah: currentJumlah,
        jenis: "masuk",
        tanggal: selectedDate,
        walletNama: selectedWalletTujuan!.nama,
        kategori: "Transfer",
      ));
    } else {
      if (selectedCategory == null || selectedWallet == null) {
        CustomSnackBar.show(context, message: "Lengkapi kategori dan dompet", isError: true);
        return;
      }
      _queuedTransactions.add(Transaksi(
        keterangan: keteranganController.text.isEmpty ? selectedCategory!.nama : keteranganController.text,
        jumlah: currentJumlah,
        jenis: jenis,
        tanggal: selectedDate,
        walletNama: selectedWallet!.nama,
        kategori: selectedCategory!.nama,
        itemsJson: _activeItems != null ? jsonEncode(_activeItems) : null,
      ));
    }

    if (_queuedTransactions.isEmpty) {
      CustomSnackBar.show(context, message: "Antrean kosong, isi nominal terlebih dahulu", isError: true);
      return;
    }

    // Checking budget warnings for expenses in queue
    int totalNewExpenses = _queuedTransactions
        .where((t) => t.jenis.toLowerCase() == "keluar" || t.jenis.toLowerCase() == "pengeluaran")
        .fold(0, (sum, t) => sum + t.jumlah);

    if (totalNewExpenses > 0) {
      final budgetStr = await DatabaseHelper.instance.getSetting('monthly_budget');
      final budget = int.tryParse(budgetStr ?? "0") ?? 0;
      if (budget > 0) {
        final all = await DatabaseHelper.instance.fetchTransaksi();
        final now = DateTime.now();
        int currentExpense = all
            .where((t) => t.tanggal.month == now.month && t.tanggal.year == now.year && (t.jenis.toLowerCase() == "keluar" || t.jenis.toLowerCase() == "pengeluaran"))
            .fold(0, (sum, t) => sum + t.jumlah);

        if (currentExpense + totalNewExpenses > budget) {
          if (mounted) {
            final confirmSave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.pink),
                    SizedBox(width: 10),
                    Text("Anggaran Terlampaui!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Transaksi pengeluaran ini akan membuat total pengeluaran bulanan Anda melampaui batas anggaran.",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Text("• Anggaran Bulanan: Rp${NumberFormat.decimalPattern('id').format(budget)}", style: const TextStyle(fontSize: 12)),
                    Text("• Pengeluaran Saat Ini: Rp${NumberFormat.decimalPattern('id').format(currentExpense)}", style: const TextStyle(fontSize: 12)),
                    Text("• Transaksi Baru (Total): Rp${NumberFormat.decimalPattern('id').format(totalNewExpenses)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                    const Divider(),
                    Text(
                      "Melampaui anggaran sebesar Rp${NumberFormat.decimalPattern('id').format(currentExpense + totalNewExpenses - budget)}.",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pink),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Tetap Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            if (confirmSave != true) {
              return;
            }
          }
        }
      }
    }

    try {
      for (var t in _queuedTransactions) {
        await DatabaseHelper.instance.insertTransaksi(t);
      }
      
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: "${_queuedTransactions.length} transaksi berhasil disimpan!",
          isSuccess: true,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: "Gagal menyimpan ke database: $e",
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double? parsedAmount = double.tryParse(nominal);
    double converted = selectedCurrency == "USD" ? (parsedAmount ?? 0) * usdToIdr : (parsedAmount ?? 0);
    final screenSize = MediaQuery.of(context).size;
    final isShortScreen = screenSize.height < 700;
    final availableHeight = screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: availableHeight,
                    child: Column(
                      children: [
                        // Top Navigation Bar (Row 1: Close Button & Centered Title)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.pink, size: 26),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                "Transaksi Baru",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 48), // Balanced spacer for title centering
                            ],
                          ),
                        ),

                        // Toggle Switch (Row 2: Full Width Left-to-Right)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Row(
                              children: [
                                Expanded(child: _buildTypeToggle("keluar", "Keluar", Icons.arrow_circle_up)),
                                Expanded(child: _buildTypeToggle("masuk", "Masuk", Icons.arrow_circle_down)),
                                Expanded(child: _buildTypeToggle("transfer", "Transfer", Icons.swap_horiz_rounded)),
                              ],
                            ),
                          ),
                        ),

                        // Action Icons Row (Row 3: Centered below the Toggle)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isScanningReceipt
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink),
                                      ),
                                    )
                                  : Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.pink.shade50.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.document_scanner, color: Colors.pink, size: 22),
                                        onPressed: _scanReceipt,
                                        tooltip: "Pindai Struk",
                                      ),
                                    ),
                              if (_queuedTransactions.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.pink, size: 22),
                                        onPressed: _showQueueManager,
                                        tooltip: "Kelola Antrean",
                                      ),
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _queuedTransactions.length.toString(),
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.pink, size: 22),
                                  onPressed: _queueCurrentTransaction,
                                  tooltip: "Antrekan Transaksi",
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.pink,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                  onPressed: _saveTransaction,
                                  tooltip: "Simpan Semua",
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (!isShortScreen) const SizedBox(height: 10),

                        // Main Content (Category Grid or Transfer Form)
                        Expanded(
                          child: jenis == 'transfer'
                              ? _buildTransferForm()
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount = (constraints.maxWidth / 80).floor().clamp(3, 8);
                                    return GridView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: 0.8,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 15,
                                      ),
                                      itemCount: categories.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == categories.length) {
                                          return GestureDetector(
                                            onTap: () async {
                                              await Navigator.push(context, MaterialPageRoute(builder: (context) => ManageCategoryPage(jenis: jenis)));
                                              _loadCategories();
                                            },
                                            child: _buildCategoryItem(null, "Manage", Icons.settings_rounded, false, null),
                                          );
                                        }

                                        final cat = categories[index];
                                        return GestureDetector(
                                          onTap: () => setState(() => selectedCategory = cat),
                                          child: _buildCategoryItem(cat.imagePath, cat.nama, cat.icon, selectedCategory == cat, null),
                                        );
                                      },
                                    );
                                  }
                                ),
                        ),

                        // Numpad Area
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.pink.shade400,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                          ),
                          padding: EdgeInsets.fromLTRB(15, isShortScreen ? 8 : 15, 15, 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSttHintCarousel(),
                              const SizedBox(height: 6),
                              // Input Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: _showWalletPicker,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(selectedWallet?.icon ?? Icons.wallet, color: Colors.green, size: 20),
                                          const SizedBox(width: 4),
                                          Text(
                                            selectedWallet?.nama ?? "Dompet",
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                          const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: TextField(
                                        controller: keteranganController,
                                        decoration: const InputDecoration(
                                          hintText: "Catatan (Keterangan)",
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    
                                    _isProcessingVoice
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pink),
                                            ),
                                          )
                                        : IconButton(
                                            icon: Icon(
                                              _isListening ? Icons.mic : Icons.mic_none,
                                              color: _isListening ? Colors.red : Colors.pink,
                                            ),
                                            onPressed: _toggleListening,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                    const SizedBox(width: 10),
                                    
                                    // Currency Selector & Nominal
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (selectedCurrency == "USD") ...[
                                              const Text("USD", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 4),
                                            ],
                                            Text(
                                              nominal,
                                              style: TextStyle(
                                                fontSize: nominal.length > 10 ? 16 : 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selectedCurrency == "USD")
                                          Text(
                                            "≈ Rp${NumberFormat.decimalPattern('id').format(converted.toInt())}",
                                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildNumpad(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Microphone Listening Blur Overlay
            if (_isListening)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 35),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, 5))],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Mendengarkan...",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF528F)),
                            ),
                            const SizedBox(height: 25),
                            _buildPulsingMicAnimation(),
                            const SizedBox(height: 25),
                            Text(
                              _spokenText.isEmpty 
                                  ? "Katakan nominal dan transaksi Anda...\n(Contoh: 'Makan siang 20 ribu')" 
                                  : _spokenText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 25),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    onPressed: () {
                                      _speech.stop();
                                      setState(() => _isListening = false);
                                    },
                                    child: Text("Batal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF528F),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      _speech.stop();
                                      setState(() => _isListening = false);
                                      if (_spokenText.isNotEmpty) {
                                        _processVoiceCommand(_spokenText);
                                      } else {
                                        CustomSnackBar.show(context, message: "Tidak ada suara yang terdeteksi.", isError: true);
                                      }
                                    },
                                    child: const Text("Selesai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // AI Receipt Scanner Blur/Thinking Overlay
            if (_isScanningReceipt)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 35),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, 5))],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                color: Color(0xFFFF528F),
                              ),
                            ),
                            const SizedBox(height: 25),
                            const Text(
                              "AI Sedang Berpikir...",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF528F)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Menganalisis struk belanja Anda untuk mendeteksi nominal & barang secara otomatis. Mohon tunggu sebentar...",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(String type, String label, IconData icon) {
    bool isActive = jenis == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          jenis = type;
          _loadCategories();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(color: isActive ? Colors.pink : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String? imagePath, String nama, IconData? icon, bool isSelected, Color? color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double iconSize = constraints.maxWidth * 0.4;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.pink.shade50 : Colors.transparent,
                border: Border.all(color: isSelected ? Colors.pink : Colors.transparent, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: imagePath != null
                  ? Image.asset(imagePath, width: iconSize, height: iconSize)
                  : Icon(icon, color: isSelected ? Colors.pink : Colors.grey.shade600, size: iconSize),
            ),
            const SizedBox(height: 4),
            Text(nama, style: TextStyle(color: isSelected ? Colors.pink : Colors.black87, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      }
    );
  }

  Widget _buildNumpad() {
    bool isToday = DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    String dateLabel = isToday ? "TODAY" : DateFormat('dd/MM HH:mm').format(selectedDate);
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildNumpadButton(dateLabel, isAction: true, isDate: true)),
            Expanded(child: _buildNumpadButton("", icon: Icons.account_balance_wallet, isAction: true, iconColor: Colors.pink)),
            Expanded(child: _buildNumpadButton("", icon: Icons.check_circle_outline, isAction: true, iconColor: Colors.pink)),
          ],
        ),
        _buildNumpadRow(["x", "7", "8", "9"]),
        _buildNumpadRow(["/", "4", "5", "6"]),
        _buildNumpadRow(["-", "1", "2", "3"]),
        Row(
          children: [
            Expanded(child: _buildNumpadButton("+", isOperator: true)),
            Expanded(child: _buildNumpadButton(".")),
            Expanded(child: _buildNumpadButton("0")),
            Expanded(child: _buildNumpadButton("DEL", isOperator: true, icon: Icons.backspace)),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> labels) {
    return Row(
      children: labels.map((l) => Expanded(child: _buildNumpadButton(l, isOperator: l == "x" || l == "/" || l == "-" || l == "+"))).toList(),
    );
  }

  Widget _buildNumpadButton(String label, {bool isOperator = false, bool isAction = false, bool isDate = false, IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          if (isDate) {
            _selectDateTime();
          } else if (label == "" && icon == Icons.account_balance_wallet) _showWalletPicker();
          else if (label == "" && (icon == Icons.check_circle_outline || icon == Icons.check_box)) _saveTransaction();
          else if (label == "DEL" || icon == Icons.backspace) _onNumpadTap("DEL");
          else if (label.isNotEmpty) _onNumpadTap(label);
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(color: isAction ? Colors.pink.shade100 : (isOperator ? Colors.white.withAlpha(75) : Colors.white), borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 1))]),
          alignment: Alignment.center,
          child: icon != null ? Icon(icon, color: iconColor ?? Colors.pink.shade700) : Text(label, style: TextStyle(fontSize: isDate ? 13 : 20, fontWeight: FontWeight.bold, color: isAction ? Colors.pink.shade900 : Colors.black87)),
        ),
      ),
    );
  }

  Future<void> _showWalletTujuanPicker() async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Dompet Tujuan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              ...AppData.wallets.map((w) => ListTile(
                leading: Icon(w.icon, color: Colors.pink),
                title: Text(w.nama),
                trailing: Text("Rp${NumberFormat.decimalPattern('id').format(w.saldo)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  setState(() => selectedWalletTujuan = w);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("TRANSFER ANTAR DOMPET", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 0.8)),
            const SizedBox(height: 20),
            // Dompet Asal
            InkWell(
              onTap: _showWalletPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.outbox_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Dari Dompet (Sumber)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(selectedWallet?.nama ?? "Pilih Dompet", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.pink),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Arrow divider
            const Center(
              child: Icon(Icons.arrow_downward_rounded, color: Colors.pink, size: 28),
            ),
            const SizedBox(height: 15),
            // Dompet Tujuan
            InkWell(
              onTap: _showWalletTujuanPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inbox_rounded, color: Colors.green, size: 24),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ke Dompet (Tujuan)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(selectedWalletTujuan?.nama ?? "Pilih Dompet Tujuan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.pink),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showReceiptItemsBottomSheet(Map<String, dynamic> data) {
    final List<dynamic> items = data['items'] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 10
                      : 20,
                ),
                child: Column(
                  children: [
                    const Text("Rincian Struk AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("Toko: ${data['keterangan'] ?? 'Struk Belanja'}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const Divider(height: 20),
                    Expanded(
                      child: items.isEmpty
                        ? const Center(child: Text("Tidak ada rincian item terbaca", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                title: Text(item['nama'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text("${item['qty'] ?? 1}x @ Rp${NumberFormat.decimalPattern('id').format((item['harga'] ?? 0) / (item['qty'] ?? 1))}", style: const TextStyle(fontSize: 12)),
                                trailing: Text("Rp${NumberFormat.decimalPattern('id').format(item['harga'] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              );
                            },
                          ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Struk:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Rp${NumberFormat.decimalPattern('id').format(data['jumlah'] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.pink),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: () {
                              for (var item in items) {
                                _queuedTransactions.add(Transaksi(
                                  keterangan: "${item['nama']} (${data['keterangan']})",
                                  jumlah: (item['harga'] as num).toInt(),
                                  jenis: "keluar",
                                  tanggal: safeParseDate(data['tanggal']),
                                  walletNama: selectedWallet?.nama ?? AppData.wallets.first.nama,
                                  kategori: item['kategori'] ?? data['kategori'] ?? 'Harian',
                                ));
                              }
                              setState(() {
                                nominal = "0";
                                keteranganController.clear();
                              });
                              Navigator.pop(context);
                              CustomSnackBar.show(
                                context,
                                message: "${items.length} item struk berhasil dimasukkan ke antrean!",
                                isSuccess: true,
                              );
                            },
                            child: const Text("Pecah Transaksi", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: () async {
                              setState(() {
                                nominal = data['jumlah'].toString();
                                keteranganController.text = data['keterangan'];
                                jenis = data['jenis'] ?? 'keluar';
                                selectedDate = safeParseDate(data['tanggal']);
                                _scannedReceiptName = data['keterangan'];
                                _activeItems = items;
                              });

                              // Load categories for the new jenis
                              await _loadCategories();

                              setState(() {
                                selectedCategory = categories.firstWhere(
                                  (c) => c.nama.toLowerCase() == data['kategori'].toString().toLowerCase(),
                                  orElse: () => categories.isNotEmpty ? categories.first : categories.first,
                                );
                              });
                              
                              if (mounted) Navigator.pop(context);
                            },
                            child: const Text("Gabungkan Semua", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  void _queueCurrentTransaction() {
    double? parsedAmount = double.tryParse(nominal);
    double baseAmount = parsedAmount ?? 0;
    int jumlah = selectedCurrency == "USD" ? (baseAmount * usdToIdr).toInt() : baseAmount.toInt();

    if (jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominal harus lebih dari 0")));
      return;
    }
    if (jenis != 'transfer' && selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih kategori terlebih dahulu")));
      return;
    }
    if (selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih dompet terlebih dahulu")));
      return;
    }

    if (jenis == 'transfer') {
      if (selectedWalletTujuan == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih dompet tujuan")));
        return;
      }
      if (selectedWallet!.nama == selectedWalletTujuan!.nama) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dompet asal dan tujuan tidak boleh sama")));
        return;
      }
      
      _queuedTransactions.add(Transaksi(
        keterangan: keteranganController.text.isEmpty ? "Transfer ke ${selectedWalletTujuan!.nama}" : keteranganController.text,
        jumlah: jumlah,
        jenis: "keluar",
        tanggal: selectedDate,
        walletNama: selectedWallet!.nama,
        kategori: "Transfer",
      ));
      
      _queuedTransactions.add(Transaksi(
        keterangan: keteranganController.text.isEmpty ? "Transfer dari ${selectedWallet!.nama}" : keteranganController.text,
        jumlah: jumlah,
        jenis: "masuk",
        tanggal: selectedDate,
        walletNama: selectedWalletTujuan!.nama,
        kategori: "Transfer",
      ));
    } else {
      _queuedTransactions.add(Transaksi(
        keterangan: keteranganController.text.isEmpty ? selectedCategory!.nama : keteranganController.text,
        jumlah: jumlah,
        jenis: jenis,
        tanggal: selectedDate,
        walletNama: selectedWallet!.nama,
        kategori: selectedCategory!.nama,
        itemsJson: _activeItems != null ? jsonEncode(_activeItems) : null,
      ));
    }

    setState(() {
      nominal = "0";
      keteranganController.clear();
      _scannedReceiptName = null;
      _activeItems = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaksi berhasil dimasukkan ke antrean!")),
    );
  }

  void _showQueueManager() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Antrean Transaksi (${_queuedTransactions.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        TextButton(
                          onPressed: () {
                            setState(() => _queuedTransactions.clear());
                            Navigator.pop(context);
                          },
                          child: const Text("Hapus Semua", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _queuedTransactions.length,
                        itemBuilder: (context, index) {
                          final t = _queuedTransactions[index];
                          final isIncome = t.jenis.toLowerCase() == 'masuk';
                          return ListTile(
                            title: Text(t.keterangan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("${t.kategori} • ${t.walletNama}", style: const TextStyle(fontSize: 11)),
                            trailing: Text("Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}", style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.red)),
                            leading: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () {
                                setState(() => _queuedTransactions.removeAt(index));
                                setModalState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _saveTransaction();
                      },
                      child: const Text("Simpan Semua Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildPulsingMicAnimation() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(20 * _pulseController.value),
          decoration: BoxDecoration(
            color: Colors.pink.withValues(alpha: 0.1 + (0.2 * (1 - _pulseController.value))),
            shape: BoxShape.circle,
          ),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
            child: const Icon(Icons.mic, color: Colors.white, size: 36),
          ),
        );
      },
    );
  }

  Widget _buildSttHintCarousel() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Row(
          key: ValueKey<int>(_currentSttHintIndex),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tips_and_updates_outlined, color: Colors.yellowAccent, size: 12),
            const SizedBox(width: 6),
            Text(
              _sttHints.isNotEmpty ? _sttHints[_currentSttHintIndex] : "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
