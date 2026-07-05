import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';
import '../data/database_helper.dart';

class ManageWalletPage extends StatefulWidget {
  const ManageWalletPage({super.key});

  @override
  State<ManageWalletPage> createState() => _ManageWalletPageState();
}

class _ManageWalletPageState extends State<ManageWalletPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "Pengaturan Akun / Dompet",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Column(
        children: [
          // Filter / Status Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterItem(Icons.check_circle_rounded, "Digunakan", Colors.green),
                _buildFilterItem(Icons.remove_circle_rounded, "Bukan Aset", Colors.orange),
                _buildFilterItem(Icons.cancel_rounded, "Nonaktif", Colors.grey),
              ],
            ),
          ),
          
          Expanded(
            child: AppData.wallets.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada akun. Klik + untuk menambah.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: AppData.wallets.length,
                    itemBuilder: (context, index) {
                      final w = AppData.wallets[index];
                      final isDebt = w.jenis == "Hutang";
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(w.nama + index.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text("Hapus Akun", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Text("Apakah Anda yakin ingin menghapus akun '${w.nama}'?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false), 
                                    child: const Text("Batal", style: TextStyle(color: Colors.grey))
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.pop(context, true), 
                                    child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            setState(() {
                              AppData.wallets.removeAt(index);
                            });
                            await DatabaseHelper.instance.saveWallets(AppData.wallets);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Akun '${w.nama}' berhasil dihapus.")),
                              );
                            }
                          },
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CreateWalletDetailPage(type: w.jenis, walletToEdit: w)),
                              ).then((_) => setState(() {}));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Icon Container
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (isDebt ? Colors.red.shade50 : Colors.green.shade50),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      w.icon, 
                                      color: (isDebt ? Colors.red.shade600 : Colors.green.shade600), 
                                      size: 24
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Main Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w.nama, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            w.jenis, 
                                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Balance Info
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Rp${NumberFormat.decimalPattern('id').format(w.saldo)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDebt ? Colors.red.shade600 : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF528F),
        onPressed: _showAddWalletType,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Tambah Akun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label, 
          style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)
        ),
      ],
    );
  }

  void _showAddWalletType() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWalletTypePage()),
    ).then((_) => setState(() {}));
  }
}

class AddWalletTypePage extends StatelessWidget {
  const AddWalletTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final types = [
      {"label": "Tunai", "icon": Icons.money, "desc": "Celengan, uang cash fisik, dompet"},
      {"label": "Tabungan", "icon": Icons.savings, "desc": "Rekening bank aktif untuk menabung"},
      {"label": "Kartu Deposit", "icon": Icons.credit_card, "desc": "Kartu e-money, Brizzi, Flazz, dll."},
      {"label": "Kartu Kredit", "icon": Icons.payment_rounded, "desc": "Catatan limit/tagihan kartu kredit"},
      {"label": "Akun virtual", "icon": Icons.wallet_rounded, "desc": "Gopay, OVO, Dana, LinkAja, PayPal"},
      {"label": "Berinvestasi", "icon": Icons.trending_up_rounded, "desc": "Akun saham, reksa dana, obligasi"},
      {"label": "Piutang", "icon": Icons.handshake_rounded, "desc": "Uang Anda yang dipinjam orang lain"},
      {"label": "Hutang", "icon": Icons.shopping_bag_rounded, "desc": "Kewajiban pembayaran kepada pihak lain"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        toolbarHeight: 65,
        title: const Text("Pilih Jenis Akun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final t = types[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1.5,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateWalletDetailPage(type: t['label'] as String)),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(t['icon'] as IconData, color: const Color(0xFFFF528F), size: 24),
              ),
              title: Text(
                t['label'] as String, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
              ),
              subtitle: Text(
                t['desc'] as String, 
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.pink, size: 22),
            ),
          );
        },
      ),
    );
  }
}

class CreateWalletDetailPage extends StatefulWidget {
  final String type;
  final Wallet? walletToEdit;
  const CreateWalletDetailPage({super.key, required this.type, this.walletToEdit});

  @override
  State<CreateWalletDetailPage> createState() => _CreateWalletDetailPageState();
}

class _CreateWalletDetailPageState extends State<CreateWalletDetailPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _saldoController = TextEditingController();
  String _selectedCurrency = "IDR";
  IconData _selectedIcon = Icons.credit_card;

  @override
  void initState() {
    super.initState();
    if (widget.walletToEdit != null) {
      _namaController.text = widget.walletToEdit!.nama;
      _saldoController.text = widget.walletToEdit!.saldo.toString();
      _selectedIcon = widget.walletToEdit!.icon;
    } else {
      if (widget.type == "Tunai") _selectedIcon = Icons.money;
      if (widget.type == "Tabungan") _selectedIcon = Icons.savings;
      if (widget.type == "Akun virtual") _selectedIcon = Icons.wallet;
    }
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("Pilih Mata Uang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(),
            ...["IDR", "USD", "EUR", "JPY"].map((c) => ListTile(
              title: Center(child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))),
              onTap: () {
                setState(() => _selectedCurrency = c);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    final icons = [
      Icons.money, Icons.credit_card, Icons.currency_bitcoin, Icons.shopping_bag,
      Icons.account_balance, Icons.wallet, Icons.savings, Icons.phone_android,
      Icons.local_atm, Icons.payments, Icons.currency_exchange, Icons.account_balance_wallet,
      Icons.card_membership, Icons.storefront, Icons.stars, Icons.security,
      Icons.volunteer_activism, Icons.qr_code_2, Icons.nfc, Icons.apple,
      Icons.shopping_cart, Icons.sell, Icons.receipt_long, Icons.point_of_sale,
      Icons.account_box, Icons.contactless, Icons.token, Icons.assured_workload,
    ];
    
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: const Color(0xFFFF528F),
                  elevation: 0,
                  title: const Text("Pilih Ikon", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white), 
                    onPressed: () => Navigator.pop(context)
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: icons.length,
                    itemBuilder: (context, index) {
                      final icon = icons[index];
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedIcon = icon);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.pink.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? Colors.pink : Colors.grey.shade200, width: 2),
                          ),
                          child: Icon(icon, color: isSelected ? Colors.pink : Colors.blueGrey, size: 24),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.walletToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 0,
        toolbarHeight: 65,
        title: Text(
          isEdit ? "Ubah ${widget.type}" : "Membuat ${widget.type}", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), 
          onPressed: () => Navigator.pop(context)
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text("INFO UTAMA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 0.8)),
            ),
            
            // Premium Form Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildInputRow("Nama Akun", _namaController, "misal: Utama, BCA, Gopay", Icons.wallet_rounded),
                  const Divider(),
                  _buildInputRow("Keseimbangan / Saldo", _saldoController, "Nominal saldo awal", Icons.money_rounded, isNumeric: true),
                  const Divider(),
                  _buildOptionRow("Mata Uang", _selectedCurrency, Icons.currency_exchange_rounded, onTap: _showCurrencyPicker),
                  const Divider(),
                  _buildOptionRow(
                    "Ikon Akun", 
                    "Pilih Ikon", 
                    Icons.grid_view_rounded, 
                    onTap: _showIconPicker, 
                    customTrailing: Container(
                      padding: const EdgeInsets.all(8), 
                      decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle), 
                      child: Icon(_selectedIcon, size: 20, color: Colors.pink)
                    )
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text("SETELAN LAINNYA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 0.8)),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _buildSwitchRow("Gunakan dalam transaksi saat ini", "Ditampilkan & disertakan dalam pencatatan harian", Icons.visibility_rounded, true),
                  const Divider(),
                  _buildSwitchRow("Termasuk sebagai aset utama", "Nilai saldo dihitung dalam total kekayaan bersih", Icons.savings_rounded, true),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF528F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (_namaController.text.isNotEmpty) {
                    if (isEdit) {
                      int idx = AppData.wallets.indexOf(widget.walletToEdit!);
                      if (idx != -1) {
                        AppData.wallets[idx].nama = _namaController.text;
                        AppData.wallets[idx].saldo = int.tryParse(_saldoController.text) ?? 0;
                        AppData.wallets[idx].icon = _selectedIcon;
                      }
                    } else {
                      final newW = Wallet(
                        nama: _namaController.text,
                        saldo: int.tryParse(_saldoController.text) ?? 0,
                        jenis: widget.type == "Hutang" ? "Hutang" : "Akun Virtual",
                        icon: _selectedIcon,
                      );
                      AppData.wallets.add(newW);
                    }
                    await DatabaseHelper.instance.saveWallets(AppData.wallets);
                    if (mounted) {
                      Navigator.pop(context);
                      if (!isEdit) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    }
                  }
                },
                child: const Text("Simpan Akun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String hint, IconData icon, {bool isNumeric = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF528F), size: 22),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller, 
              textAlign: TextAlign.right, 
              keyboardType: isNumeric ? TextInputType.number : TextInputType.text, 
              decoration: InputDecoration(
                hintText: hint, 
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none, 
                isDense: true
              ), 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, String value, IconData icon, {VoidCallback? onTap, Widget? customTrailing}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF528F), size: 22),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            customTrailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, IconData icon, bool value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF528F), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(
            value: value, 
            onChanged: (val) {}, 
            activeColor: Colors.pink,
            activeTrackColor: Colors.pink.shade100,
          ),
        ],
      ),
    );
  }
}
