import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import 'manage_wallet_page.dart';

class WalletDetailPage extends StatefulWidget {
  final Wallet wallet;
  const WalletDetailPage({super.key, required this.wallet});

  @override
  State<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends State<WalletDetailPage> {
  List<Transaksi> _walletTransactions = [];
  bool _isAnalysisMode = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final all = await DatabaseHelper.instance.fetchTransaksi();
    setState(() {
      _walletTransactions = all.where((t) => t.walletNama == widget.wallet.nama).toList();
    });
  }

  int get totalMasuk {
    return _walletTransactions
        .where((t) => t.jenis == "masuk")
        .fold(0, (sum, t) => sum + t.jumlah);
  }

  int get totalKeluar {
    return _walletTransactions
        .where((t) => t.jenis == "keluar" || t.jenis == "pengeluaran")
        .fold(0, (sum, t) => sum + t.jumlah);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Detail akun", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateWalletDetailPage(type: widget.wallet.jenis, walletToEdit: widget.wallet)),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Summary Card
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(15)),
                        child: Icon(widget.wallet.icon, color: Colors.orange.shade300, size: 40),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.wallet.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Rp${NumberFormat.decimalPattern('id').format(widget.wallet.saldo)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const Text("IDR", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chevron_left, color: Colors.pink, size: 20),
                      const SizedBox(width: 10),
                      Text(DateFormat('M/yyyy').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_drop_down, color: Colors.pink),
                      const SizedBox(width: 10),
                      const Icon(Icons.chevron_right, color: Colors.pink, size: 20),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildSummaryRow("Penghasilan", totalMasuk, Colors.pink),
                  const SizedBox(height: 10),
                  _buildSummaryRow("Pengeluaran", totalKeluar, Colors.pink.shade300),
                ],
              ),
            ),
            
            // Mode Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 100),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  _buildToggleBtn("Analisis", _isAnalysisMode),
                  _buildToggleBtn("Detail", !_isAnalysisMode),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Content Based on Mode
            if (_isAnalysisMode) ...[
              // Simple Graph Mockup
              Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(20),
                height: 250,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildSmallTag("Aset", true),
                        const SizedBox(width: 10),
                        _buildSmallTag("Tren", false),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: WalletChartPainter(transactions: _walletTransactions, initialBalance: widget.wallet.saldo),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Transaction List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _walletTransactions.length,
                itemBuilder: (context, index) {
                  final t = _walletTransactions[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.receipt_long, color: Colors.pink, size: 20),
                    ),
                    title: Text(t.kategori, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMMM yyyy').format(t.tanggal)),
                    trailing: Text(
                      "${t.jenis == 'masuk' ? '+' : '-'}Rp${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                      style: TextStyle(color: t.jenis == 'masuk' ? Colors.blue : Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(
          child: Container(
            height: 35,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.centerLeft,
            child: Text("Rp${NumberFormat.decimalPattern('id').format(value)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        const Text("0%", style: TextStyle(color: Colors.pink, fontSize: 12)),
      ],
    );
  }

  Widget _buildToggleBtn(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isAnalysisMode = (label == "Analisis")),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.pink : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildSmallTag(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.pink.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: isActive ? Colors.pink : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class WalletChartPainter extends CustomPainter {
  final List<Transaksi> transactions;
  final int initialBalance;

  WalletChartPainter({required this.transactions, required this.initialBalance});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // Draw Grid
    int horizontalLines = 5;
    int verticalLines = 6;
    for (int i = 0; i <= horizontalLines; i++) {
      double y = size.height / horizontalLines * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i <= verticalLines; i++) {
      double x = size.width / verticalLines * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (transactions.isEmpty) return;

    // Calculate Data Points (Last 7 Days)
    List<double> balanceTrend = [];
    int currentBalance = initialBalance;
    balanceTrend.add(currentBalance.toDouble());

    // Sort transactions by date ASC
    final sorted = List<Transaksi>.from(transactions)..sort((a, b) => a.tanggal.compareTo(b.tanggal));
    
    for (var t in sorted) {
      if (t.jenis == "masuk") {
        currentBalance += t.jumlah;
      } else {
        currentBalance -= t.jumlah;
      }
      balanceTrend.add(currentBalance.toDouble());
    }

    if (balanceTrend.length < 2) {
      // Just a flat line if only 1 point
      balanceTrend.insert(0, initialBalance.toDouble());
    }

    double maxVal = balanceTrend.reduce((curr, next) => curr > next ? curr : next);
    double minVal = balanceTrend.reduce((curr, next) => curr < next ? curr : next);
    double range = (maxVal - minVal).abs();
    if (range == 0) range = 1;

    List<Offset> points = [];
    double xStep = size.width / (balanceTrend.length - 1);
    for (int i = 0; i < balanceTrend.length; i++) {
      double x = i * xStep;
      double y = size.height - ((balanceTrend[i] - minVal) / range * (size.height * 0.8) + (size.height * 0.1));
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Draw Shaded Area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.green.withAlpha(80), Colors.green.withAlpha(10)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw Line
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Draw Dots
    final dotPaint = Paint()..color = Colors.green;
    for (var p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
