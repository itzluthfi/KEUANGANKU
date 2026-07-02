import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart'; // Sesuaikan path ke model Transaksi Anda

class TransaksiItem extends StatelessWidget {
  final Transaksi transaksi;
  final VoidCallback? onTap;

  const TransaksiItem({
    super.key,
    required this.transaksi,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah jenis transaksi adalah pemasukan
    final bool isMasuk = transaksi.jenis.toLowerCase() == "masuk" ||
        transaksi.jenis.toLowerCase() == "pemasukan";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isMasuk
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isMasuk ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          transaksi.keterangan,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${DateFormat('dd MMM yyyy').format(transaksi.tanggal)} • ${transaksi.walletNama}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Rp ${NumberFormat.decimalPattern('id').format(transaksi.jumlah)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMasuk ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
            Text(
              transaksi.kategori,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}