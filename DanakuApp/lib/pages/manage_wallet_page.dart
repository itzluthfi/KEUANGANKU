import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        title: const Text("Akun", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.pink.shade50.withAlpha(100),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterItem(Icons.check_box, "Digunakan", Colors.pink),
                  const SizedBox(width: 15),
                  _buildFilterItem(Icons.indeterminate_check_box, "Bukan aset", Colors.pink),
                  const SizedBox(width: 15),
                  _buildFilterItem(Icons.check_box_outline_blank, "Tidak dipakai", Colors.grey),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: AppData.wallets.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final w = AppData.wallets[index];
                return Dismissible(
                  key: Key(w.nama + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Hapus Akun"),
                        content: Text("Apakah Anda yakin ingin menghapus akun '${w.nama}'?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    setState(() {
                      AppData.wallets.removeAt(index);
                    });
                    await DatabaseHelper.instance.saveWallets(AppData.wallets);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${w.nama} dihapus")));
                  },
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateWalletDetailPage(type: w.jenis, walletToEdit: w)),
                      ).then((_) => setState(() {}));
                    },
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_box, color: Colors.pink, size: 20),
                        const SizedBox(width: 15),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Icon(w.icon, color: Colors.blue.shade300, size: 24),
                        ),
                      ],
                    ),
                    title: Text(w.nama, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.menu, color: Colors.pink, size: 18),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () => _showAddWalletType(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.black54),
                  SizedBox(width: 5),
                  Text("Tambah", style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
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
      {"label": "Tunai", "icon": Icons.money, "desc": null},
      {"label": "Tabungan", "icon": Icons.savings, "desc": "Rekening bank atau celengan"},
      {"label": "Kartu Deposit", "icon": Icons.credit_card, "desc": null},
      {"label": "Kartu Kredit", "icon": Icons.credit_card, "desc": null},
      {"label": "Akun virtual", "icon": Icons.currency_bitcoin, "desc": "PayPal, Mata Uang Digital, dan Kartu Isi Ulang"},
      {"label": "Berinvestasi", "icon": Icons.description, "desc": "Berinvestasi dalam akun keuangan"},
      {"label": "Piutang", "icon": Icons.handshake, "desc": "Untuk uang yang belum diterima"},
      {"label": "Hutang", "icon": Icons.shopping_bag, "desc": "Untuk uang mana yang harus dibayarkan"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        title: const Text("Akun baru", style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.separated(
        itemCount: types.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = types[index];
          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateWalletDetailPage(type: t['label'] as String)),
              );
            },
            leading: Icon(t['icon'] as IconData, color: Colors.blue.shade300, size: 28),
            title: Text(t['label'] as String),
            subtitle: t['desc'] != null ? Text(t['desc'] as String, style: const TextStyle(fontSize: 11)) : null,
            trailing: const Icon(Icons.chevron_right, color: Colors.pink, size: 20),
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
      if (widget.type == "Akun virtual") _selectedIcon = Icons.account_balance_wallet;
    }
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["IDR", "USD", "EUR", "JPY"].map((c) => ListTile(
          title: Text(c),
          onTap: () {
            setState(() => _selectedCurrency = c);
            Navigator.pop(context);
          },
        )).toList(),
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
      Icons.facebook, Icons.shopping_cart, Icons.sell, Icons.receipt_long, Icons.point_of_sale,
      Icons.account_box, Icons.contactless, Icons.token, Icons.assured_workload,
    ];
    
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: const Color(0xFFFF528F),
                  title: const Text("Ikon", style: TextStyle(color: Colors.white)),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                  leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = (constraints.maxWidth / 70).floor().clamp(3, 8);
                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
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
                                color: Colors.pink.shade50.withAlpha(50),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: isSelected ? Colors.pink : Colors.transparent, width: 2),
                              ),
                              child: Icon(icon, color: isSelected ? Colors.pink : Colors.blue.shade300, size: 28),
                            ),
                          );
                        },
                      );
                    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF528F),
        title: Text(isEdit ? "Ubah ${widget.type}" : "Membuat ${widget.type}", style: const TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.all(15), child: Text("Info Akun", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            _buildInputRow("Nama Akun", _namaController, "Nama Akun", Icons.wallet_rounded),
            _buildInputRow("Keseimbangan", _saldoController, "Keseimbangan", Icons.money, isNumeric: true),
            _buildOptionRow("Mata Uang", _selectedCurrency, Icons.currency_exchange, onTap: _showCurrencyPicker),
            _buildOptionRow("Ikon", "Pilih Ikon", Icons.grid_view_rounded, onTap: _showIconPicker, customTrailing: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(5)), child: Icon(_selectedIcon, size: 20, color: Colors.blue))),
            const SizedBox(height: 20),
            _buildSwitchRow("Gunakan dalam buku saat ini", "Ditampilkan & disertakan dalam aset", Icons.visibility, true),
            _buildSwitchRow("Termasuk sebagai aset dalam buku...", "Termasuk dalam aset atau liabilitas dalam statistik", Icons.savings, true),
            const Padding(padding: EdgeInsets.all(15), child: Text("Nota", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: TextField(decoration: InputDecoration(hintText: "Bagaimana dengan menulis sesuatu?", border: InputBorder.none), maxLines: 3)),
            const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.all(15), child: Text("0/30", style: TextStyle(color: Colors.grey))))
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String hint, IconData icon, {bool isNumeric = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple.shade200),
      title: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: TextField(controller: controller, textAlign: TextAlign.right, keyboardType: isNumeric ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true), style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, String value, IconData icon, {VoidCallback? onTap, Widget? customTrailing}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.orange.shade200),
      title: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
      trailing: customTrailing ?? const Icon(Icons.chevron_right, color: Colors.pink, size: 18),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, IconData icon, bool value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade200),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Switch(value: value, onChanged: (val) {}, activeColor: Colors.pink),
    );
  }
}
