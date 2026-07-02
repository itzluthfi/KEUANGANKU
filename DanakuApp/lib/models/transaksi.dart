class Transaksi {
  final String keterangan;
  final int jumlah;
  final String jenis;
  final DateTime tanggal;
  final String walletNama;
  final String kategori;

  Transaksi({
    required this.keterangan,
    required this.jumlah,
    required this.jenis,
    required this.tanggal,
    required this.walletNama,
    required this.kategori,
  });
}