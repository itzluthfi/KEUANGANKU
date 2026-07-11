import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';
import '../widgets/custom_snackbar.dart';

import 'manage_wallet_page.dart';
import 'wallet_detail_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isObscured = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => isLoading = true);
    final list = await DatabaseHelper.instance.fetchWallets();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        if (list.isNotEmpty) {
          AppData.wallets = list;
        }
        isLoading = false;
      });
    }
  }

  void _navigateToManageWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageWalletPage()),
    ).then((_) => _loadWallets());
  }

  int get totalAsset {
    return AppData.wallets
        .where((w) => w.jenis != "Hutang")
        .fold(0, (sum, w) => sum + w.saldo);
  }

  int get totalHutang {
    return AppData.wallets
        .where((w) => w.jenis == "Hutang")
        .fold(0, (sum, w) => sum + w.saldo);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Stack(
                children: [
                  // Decorative Circles
                  Positioned(
                    right: -50, top: -20,
                    child: Container(width: 180, height: 180, decoration: BoxDecoration(color: Colors.white.withAlpha(20), shape: BoxShape.circle)),
                  ),
                  Positioned(
                    left: -30, bottom: -20,
                    child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withAlpha(15), shape: BoxShape.circle)),
                  ),
                  
                  // Content
                  SafeArea(
                    bottom: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Toolbar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.menu_book, color: Colors.white, size: 28),
                                  Row(
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white, size: 20),
                                        onPressed: () => setState(() => _isObscured = !_isObscured),
                                      ),
                                      const SizedBox(width: 15),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.monetization_on, color: Colors.white, size: 22),
                                        onPressed: () {
                                          CustomSnackBar.show(context, message: "Currency: IDR");
                                        },
                                      ),
                                      const SizedBox(width: 15),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.sort, color: Colors.white, size: 22),
                                        onPressed: _navigateToManageWallet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Dompet Title & Main Balance
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Dompet", style: TextStyle(color: Colors.white, fontSize: isTablet ? 36 : 28, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  const Text("Aset Bersih", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: isLoading
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 4),
                                            child: ShimmerWidget(width: 160, height: 22),
                                          )
                                        : Text(
                                            _isObscured ? "****" : "Rp${NumberFormat.decimalPattern('id').format(totalAsset - totalHutang)}",
                                            style: TextStyle(color: Colors.white, fontSize: isTablet ? 32 : 24, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Sub Stats (Aset & Hutang)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Row(
                                children: [
                                  Expanded(child: _buildSubStat("Aset", totalAsset)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildSubStat("Hutang", totalHutang)),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // White Content - List of Wallets
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    isLoading
                        ? Column(
                            children: [
                              _buildShimmerWalletSection(),
                              const SizedBox(height: 20),
                              _buildShimmerWalletSection(),
                            ],
                          )
                        : Column(
                            children: [
                              _buildWalletSection("Hutang", AppData.wallets.where((w) => w.jenis == "Hutang").toList()),
                              const SizedBox(height: 20),
                              _buildWalletSection("Akun virtual", AppData.wallets.where((w) => w.jenis != "Hutang").toList()),
                            ],
                          ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubStat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 5),
        isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: ShimmerWidget(width: 90, height: 16),
              )
            : Text(
                _isObscured ? "****" : "Rp${NumberFormat.decimalPattern('id').format(value)}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ],
    );
  }

  Widget _buildWalletSection(String title, List<Wallet> items) {
    int sectionTotal = items.fold(0, (sum, w) => sum + w.saldo);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.pink.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                Text(
                  "$title: ${_isObscured ? '****' : 'Rp${NumberFormat.decimalPattern('id').format(sectionTotal)}'}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Wallet Items
          ...items.map((w) => _buildWalletItem(w)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildWalletItem(Wallet w) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WalletDetailPage(wallet: w)),
        ).then((_) => _loadWallets());
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(w.icon, color: Colors.blue.shade300, size: 28),
      ),
      title: Text(w.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _isObscured ? "****" : "Rp${NumberFormat.decimalPattern('id').format(w.saldo)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text("IDR(1.0)", style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildShimmerWalletSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Shimmer Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.pink.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerWidget(width: 80, height: 14),
                ShimmerWidget(width: 100, height: 12),
              ],
            ),
          ),
          // Shimmer Wallet Items
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: List.generate(2, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  child: Row(
                    children: [
                      // Icon Shimmer
                      const ShimmerWidget(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(15))),
                      const SizedBox(width: 12),
                      // Title Shimmer
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            ShimmerWidget(width: 120, height: 14),
                            SizedBox(height: 6),
                            ShimmerWidget(width: 60, height: 10),
                          ],
                        ),
                      ),
                      // Amount Shimmer
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          ShimmerWidget(width: 70, height: 14),
                          SizedBox(height: 4),
                          ShimmerWidget(width: 40, height: 10),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
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