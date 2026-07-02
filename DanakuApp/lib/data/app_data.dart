import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Book {
  int? id;
  String nama;

  Book({this.id, required this.nama});

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      nama: map['nama'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
    };
  }
}

class Wallet {
  String nama;
  int saldo;
  String jenis; // "Hutang", "Akun Virtual", "Aset", etc.
  IconData icon;

  Wallet({
    required this.nama, 
    required this.saldo, 
    this.jenis = "Akun Virtual", 
    this.icon = Icons.credit_card_rounded
  });
}

class RecurringTransaction {
  final int? id;
  final int bookId;
  final String keterangan;
  final int jumlah;
  final String jenis;
  final String kategori;
  final String walletNama;
  final String interval; // 'harian', 'mingguan', 'bulanan'
  final DateTime nextDueDate;
  final bool isActive;

  RecurringTransaction({
    this.id,
    this.bookId = 1,
    required this.keterangan,
    required this.jumlah,
    required this.jenis,
    required this.kategori,
    required this.walletNama,
    required this.interval,
    required this.nextDueDate,
    this.isActive = true,
  });

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'],
      bookId: map['book_id'] ?? 1,
      keterangan: map['keterangan'] ?? '',
      jumlah: map['jumlah'] ?? 0,
      jenis: map['jenis'] ?? '',
      kategori: map['kategori'] ?? '',
      walletNama: map['walletNama'] ?? '',
      interval: map['interval'] ?? 'bulanan',
      nextDueDate: DateTime.parse(map['nextDueDate']),
      isActive: (map['isActive'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'jenis': jenis,
      'kategori': kategori,
      'walletNama': walletNama,
      'interval': interval,
      'nextDueDate': DateFormat('yyyy-MM-dd').format(nextDueDate),
      'isActive': isActive ? 1 : 0,
    };
  }
}

class Transaksi {
  final int? id;
  final int bookId;
  final String keterangan;
  final int jumlah;
  final String jenis; // "masuk" atau "keluar"
  final DateTime tanggal;
  final String walletNama;
  final String kategori;

  Transaksi({
    this.id,
    this.bookId = 1,
    required this.keterangan,
    required this.jumlah,
    required this.jenis,
    required this.tanggal,
    required this.walletNama,
    required this.kategori,
  });

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      bookId: map['book_id'] ?? 1,
      keterangan: map['keterangan'] ?? '',
      jumlah: map['jumlah'] ?? 0,
      jenis: map['jenis'] ?? '',
      tanggal: DateTime.parse(map['tanggal']),
      walletNama: map['walletNama'] ?? '',
      kategori: map['kategori'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'keterangan': keterangan,
      'jumlah': jumlah,
      'jenis': jenis,
      'tanggal': tanggal.toIso8601String(),
      'walletNama': walletNama,
      'kategori': kategori,
    };
  }
}

class TransactionCategory {
  final int? id;
  final String nama;
  final IconData? icon;
  final String? imagePath;

  TransactionCategory({this.id, required this.nama, this.icon, this.imagePath});

  Map<String, dynamic> toMap(String jenis) {
    return {
      'id': id,
      'nama': nama,
      'jenis': jenis,
      'icon_code': icon?.codePoint,
      'image_path': imagePath,
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'],
      nama: map['nama'],
      icon: map['icon_code'] != null ? IconMapper.getIcon(map['icon_code']) : null,
      imagePath: map['image_path'],
    );
  }
}

class AppData {
  static int activeBookId = 1;
  static String activeBookName = "catatan mada";

  static List<Wallet> wallets = [
    Wallet(nama: "Utama", saldo: 0, jenis: "Akun Virtual", icon: Icons.account_balance_wallet),
  ];

  static List<Transaksi> transaksi = [];
  
  static List<TransactionCategory> pengeluaranCategories = [
    TransactionCategory(nama: "Makan", imagePath: "assets/icons/makan.png"),
    TransactionCategory(nama: "Minum", imagePath: "assets/icons/minum.png"),
    TransactionCategory(nama: "Bensin", imagePath: "assets/icons/bensin.png"),
    TransactionCategory(nama: "Parkir", icon: Icons.local_parking_rounded),
    TransactionCategory(nama: "Kopi", icon: Icons.coffee_rounded),
    TransactionCategory(nama: "Sosial", icon: Icons.auto_awesome_rounded),
    TransactionCategory(nama: "Harian", icon: Icons.shopping_bag_rounded),
    TransactionCategory(nama: "Admin", icon: Icons.account_balance_rounded),
    TransactionCategory(nama: "Hadiah", icon: Icons.card_giftcard_rounded),
    TransactionCategory(nama: "Ban", icon: Icons.tire_repair_rounded),
    TransactionCategory(nama: "Jalan", icon: Icons.traffic_rounded),
    TransactionCategory(nama: "HP", icon: Icons.phone_android_rounded),
  ];

  static List<TransactionCategory> pemasukanCategories = [
    TransactionCategory(nama: "Gaji", imagePath: "assets/icons/gaji.png"),
    TransactionCategory(nama: "Uang Saku", icon: Icons.account_balance_wallet_rounded),
    TransactionCategory(nama: "Bonus", icon: Icons.star_rounded),
    TransactionCategory(nama: "Lainnya", icon: Icons.auto_graph_rounded),
  ];
}

class IconMapper {
  static final Map<int, IconData> _iconMap = {
    Icons.money.codePoint: Icons.money,
    Icons.credit_card.codePoint: Icons.credit_card,
    Icons.currency_bitcoin.codePoint: Icons.currency_bitcoin,
    Icons.shopping_bag.codePoint: Icons.shopping_bag,
    Icons.account_balance.codePoint: Icons.account_balance,
    Icons.wallet.codePoint: Icons.wallet,
    Icons.savings.codePoint: Icons.savings,
    Icons.phone_android.codePoint: Icons.phone_android,
    Icons.local_atm.codePoint: Icons.local_atm,
    Icons.payments.codePoint: Icons.payments,
    Icons.currency_exchange.codePoint: Icons.currency_exchange,
    Icons.account_balance_wallet.codePoint: Icons.account_balance_wallet,
    Icons.card_membership.codePoint: Icons.card_membership,
    Icons.storefront.codePoint: Icons.storefront,
    Icons.stars.codePoint: Icons.stars,
    Icons.security.codePoint: Icons.security,
    Icons.volunteer_activism.codePoint: Icons.volunteer_activism,
    Icons.qr_code_2.codePoint: Icons.qr_code_2,
    Icons.nfc.codePoint: Icons.nfc,
    Icons.apple.codePoint: Icons.apple,
    Icons.facebook.codePoint: Icons.facebook,
    Icons.shopping_cart.codePoint: Icons.shopping_cart,
    Icons.sell.codePoint: Icons.sell,
    Icons.receipt_long.codePoint: Icons.receipt_long,
    Icons.point_of_sale.codePoint: Icons.point_of_sale,
    Icons.account_box.codePoint: Icons.account_box,
    Icons.contactless.codePoint: Icons.contactless,
    Icons.token.codePoint: Icons.token,
    Icons.assured_workload.codePoint: Icons.assured_workload,
    
    Icons.local_parking_rounded.codePoint: Icons.local_parking_rounded,
    Icons.coffee_rounded.codePoint: Icons.coffee_rounded,
    Icons.auto_awesome_rounded.codePoint: Icons.auto_awesome_rounded,
    Icons.shopping_bag_rounded.codePoint: Icons.shopping_bag_rounded,
    Icons.account_balance_rounded.codePoint: Icons.account_balance_rounded,
    Icons.card_giftcard_rounded.codePoint: Icons.card_giftcard_rounded,
    Icons.tire_repair_rounded.codePoint: Icons.tire_repair_rounded,
    Icons.traffic_rounded.codePoint: Icons.traffic_rounded,
    Icons.phone_android_rounded.codePoint: Icons.phone_android_rounded,
    Icons.account_balance_wallet_rounded.codePoint: Icons.account_balance_wallet_rounded,
    Icons.star_rounded.codePoint: Icons.star_rounded,
    Icons.auto_graph_rounded.codePoint: Icons.auto_graph_rounded,
    Icons.credit_card_rounded.codePoint: Icons.credit_card_rounded,
    Icons.category.codePoint: Icons.category,
    
    Icons.handshake.codePoint: Icons.handshake,
    Icons.description.codePoint: Icons.description,
  };

  static IconData getIcon(int codePoint) {
    return _iconMap[codePoint] ?? Icons.category;
  }
}

