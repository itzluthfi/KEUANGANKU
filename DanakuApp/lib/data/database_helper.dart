import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_data.dart';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE books (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE transaksi (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER DEFAULT 1,
      keterangan TEXT,
      jumlah INTEGER,
      jenis TEXT,
      tanggal TEXT,
      walletNama TEXT,
      kategori TEXT,
      items_json TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER DEFAULT 1,
      nama TEXT,
      saldo INTEGER,
      jenis TEXT,
      icon_code INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE settings (
      key TEXT PRIMARY KEY,
      value TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT,
      jenis TEXT,
      icon_code INTEGER,
      image_path TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE recurring_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER DEFAULT 1,
      keterangan TEXT,
      jumlah INTEGER,
      jenis TEXT,
      kategori TEXT,
      walletNama TEXT,
      interval TEXT,
      nextDueDate TEXT,
      isActive INTEGER DEFAULT 1
    )
    ''');

    // Insert default book
    await db.insert('books', {'nama': 'Buku Utama'});

    // Insert default wallets from AppData (now only contains "Utama")
    for (var w in AppData.wallets) {
      await db.insert('wallets', {
        'book_id': 1,
        'nama': w.nama, 
        'saldo': w.saldo, 
        'jenis': w.jenis, 
        'icon_code': w.icon.codePoint
      });
    }
    
    // Insert default categories
    for (var cat in AppData.pengeluaranCategories) {
      await db.insert('categories', cat.toMap('keluar'));
    }
    for (var cat in AppData.pemasukanCategories) {
      await db.insert('categories', cat.toMap('masuk'));
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add books table
      await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT
      )
      ''');
      // Insert default book
      await db.insert('books', {'nama': 'Buku Utama'});

      // Add book_id column to existing tables
      await db.execute('ALTER TABLE transaksi ADD COLUMN book_id INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE wallets ADD COLUMN book_id INTEGER DEFAULT 1');
      
      // Update existing records to use book_id = 1
      await db.update('transaksi', {'book_id': 1});
      await db.update('wallets', {'book_id': 1});
    }
    if (oldVersion < 3) {
      await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER DEFAULT 1,
        keterangan TEXT,
        jumlah INTEGER,
        jenis TEXT,
        kategori TEXT,
        walletNama TEXT,
        interval TEXT,
        nextDueDate TEXT,
        isActive INTEGER DEFAULT 1
      )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE transaksi ADD COLUMN items_json TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
  }

  // --- FUNGSI BOOKS ---
  Future<List<Book>> fetchBooks() async {
    final db = await database;
    final result = await db.query('books');
    return result.map((json) => Book.fromMap(json)).toList();
  }

  Future<int> insertBook(String nama) async {
    final db = await database;
    return await db.insert('books', {'nama': nama});
  }

  // Categories functions
  Future<List<TransactionCategory>> fetchCategories(String jenis) async {
    final db = await database;
    final result = await db.query('categories', where: 'jenis = ?', whereArgs: [jenis]);
    return result.map((json) => TransactionCategory.fromMap(json)).toList();
  }

  Future<void> insertCategory(TransactionCategory cat, String jenis) async {
    final db = await database;
    await db.insert('categories', cat.toMap(jenis));
    // Trigger pencadangan otomatis senyap di background
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    // Trigger pencadangan otomatis senyap di background
    SyncService.instance.triggerAutoBackup();
  }

  // --- FUNGSI SETTINGS (UNTUK OFFLINE KURS) ---
  Future<void> saveLastRate(double rate) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'last_idr_rate', 'value': rate.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getLastRate() async {
    final db = await database;
    final maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['last_idr_rate']
    );

    if (maps.isNotEmpty) {
      return double.tryParse(maps.first['value'] as String) ?? 15800.0;
    }
    return 15800.0;
  }

  // --- FUNGSI PENGATURAN GENERIK (UNTUK AUTH & BACKUP SIMULASI) ---
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key]
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [key]
    );
  }

  // --- FUNGSI TRANSAKSI ---
  Future<void> insertTransaksi(Transaksi t) async {
    final db = await database;
    await db.transaction((txn) async {
      Map<String, dynamic> tMap = t.toMap();
      tMap['book_id'] = AppData.activeBookId;
      await txn.insert('transaksi', tMap);

      final List<Map<String, dynamic>> walletMaps = await txn.query(
        'wallets',
        where: 'nama = ? AND book_id = ?',
        whereArgs: [t.walletNama, AppData.activeBookId],
      );

      if (walletMaps.isNotEmpty) {
        int saldoSekarang = walletMaps.first['saldo'] as int;
        int saldoBaru;
        if (t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran') {
          saldoBaru = saldoSekarang - t.jumlah;
        } else {
          saldoBaru = saldoSekarang + t.jumlah;
        }
        await txn.update(
          'wallets', 
          {'saldo': saldoBaru}, 
          where: 'nama = ? AND book_id = ?', 
          whereArgs: [t.walletNama, AppData.activeBookId]
        );
      }
    });

    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }

  Future<List<Transaksi>> fetchTransaksi() async {
    final db = await database;
    final result = await db.query('transaksi', where: 'book_id = ?', whereArgs: [AppData.activeBookId], orderBy: 'tanggal DESC');
    return result.map((json) => Transaksi.fromMap(json)).toList();
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    final db = await database;
    await db.delete('wallets', where: 'book_id = ?', whereArgs: [AppData.activeBookId]);
    for (var w in wallets) {
      await db.insert('wallets', {
        'book_id': AppData.activeBookId,
        'nama': w.nama, 
        'saldo': w.saldo, 
        'jenis': w.jenis, 
        'icon_code': w.icon.codePoint
      });
    }
  }

  Future<List<Wallet>> fetchWallets() async {
    final db = await database;
    final result = await db.query('wallets', where: 'book_id = ?', whereArgs: [AppData.activeBookId]);
    return result.map((json) => Wallet(
      nama: json['nama'] as String, 
      saldo: json['saldo'] as int,
      jenis: json['jenis'] != null ? json['jenis'] as String : "Akun Virtual",
      icon: json['icon_code'] != null ? IconMapper.getIcon(json['icon_code'] as int) : Icons.account_balance_wallet
    )).toList();
  }

  Future<void> deleteTransaksi(Transaksi t) async {
    final db = await database;
    await db.transaction((txn) async {
      // Reverse the wallet balance
      final List<Map<String, dynamic>> walletMaps = await txn.query(
        'wallets',
        where: 'nama = ? AND book_id = ?',
        whereArgs: [t.walletNama, AppData.activeBookId],
      );

      if (walletMaps.isNotEmpty) {
        int saldoSekarang = walletMaps.first['saldo'] as int;
        int saldoBaru;
        if (t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran') {
          saldoBaru = saldoSekarang + t.jumlah;
        } else {
          saldoBaru = saldoSekarang - t.jumlah;
        }
        await txn.update(
          'wallets', 
          {'saldo': saldoBaru}, 
          where: 'nama = ? AND book_id = ?', 
          whereArgs: [t.walletNama, AppData.activeBookId]
        );
      }

      await txn.delete('transaksi', where: 'id = ?', whereArgs: [t.id]);
    });

    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> updateTransaksi(Transaksi oldT, Transaksi newT) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Reverse old impact
      final List<Map<String, dynamic>> oldWalletMaps = await txn.query(
        'wallets',
        where: 'nama = ? AND book_id = ?',
        whereArgs: [oldT.walletNama, AppData.activeBookId],
      );

      if (oldWalletMaps.isNotEmpty) {
        int saldoSekarang = oldWalletMaps.first['saldo'] as int;
        int reversedSaldo;
        if (oldT.jenis.toLowerCase() == 'keluar' || oldT.jenis.toLowerCase() == 'pengeluaran') {
          reversedSaldo = saldoSekarang + oldT.jumlah;
        } else {
          reversedSaldo = saldoSekarang - oldT.jumlah;
        }
        await txn.update(
          'wallets', 
          {'saldo': reversedSaldo}, 
          where: 'nama = ? AND book_id = ?', 
          whereArgs: [oldT.walletNama, AppData.activeBookId]
        );
      }

      // 2. Apply new impact
      final List<Map<String, dynamic>> newWalletMaps = await txn.query(
        'wallets',
        where: 'nama = ? AND book_id = ?',
        whereArgs: [newT.walletNama, AppData.activeBookId],
      );

      if (newWalletMaps.isNotEmpty) {
        int saldoTarget;
        if (oldT.walletNama == newT.walletNama) {
          final updatedWallet = await txn.query(
            'wallets', 
            where: 'nama = ? AND book_id = ?', 
            whereArgs: [newT.walletNama, AppData.activeBookId]
          );
          saldoTarget = updatedWallet.first['saldo'] as int;
        } else {
          saldoTarget = newWalletMaps.first['saldo'] as int;
        }

        int saldoBaru;
        if (newT.jenis.toLowerCase() == 'keluar' || newT.jenis.toLowerCase() == 'pengeluaran') {
          saldoBaru = saldoTarget - newT.jumlah;
        } else {
          saldoBaru = saldoTarget + newT.jumlah;
        }
        await txn.update(
          'wallets', 
          {'saldo': saldoBaru}, 
          where: 'nama = ? AND book_id = ?', 
          whereArgs: [newT.walletNama, AppData.activeBookId]
        );
      }

      Map<String, dynamic> newTMap = newT.toMap();
      newTMap['book_id'] = AppData.activeBookId;
      await txn.update(
        'transaksi', 
        newTMap, 
        where: 'id = ?', 
        whereArgs: [oldT.id]
      );
    });

    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> resetData() async {
    final db = await database;
    await db.delete('transaksi', where: 'book_id = ?', whereArgs: [AppData.activeBookId]);
    await db.delete('wallets', where: 'book_id = ?', whereArgs: [AppData.activeBookId]);
    await db.insert('wallets', {
      'book_id': AppData.activeBookId,
      'nama': 'Utama',
      'saldo': 0,
      'jenis': 'Akun Virtual',
      'icon_code': Icons.account_balance_wallet.codePoint,
    });
    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
  }

  // --- FUNGSI TRANSAKSI BERULANG ---
  Future<List<RecurringTransaction>> fetchRecurringTransactions() async {
    final db = await database;
    final result = await db.query(
      'recurring_transactions',
      where: 'book_id = ?',
      whereArgs: [AppData.activeBookId],
    );
    return result.map((json) => RecurringTransaction.fromMap(json)).toList();
  }

  Future<int> insertRecurringTransaction(RecurringTransaction rt) async {
    final db = await database;
    final map = rt.toMap();
    map['book_id'] = AppData.activeBookId;
    final id = await db.insert('recurring_transactions', map);
    SyncService.instance.triggerAutoBackup();
    return id;
  }

  Future<int> updateRecurringTransaction(RecurringTransaction rt) async {
    final db = await database;
    final map = rt.toMap();
    map['book_id'] = AppData.activeBookId;
    final rows = await db.update(
      'recurring_transactions',
      map,
      where: 'id = ?',
      whereArgs: [rt.id],
    );
    SyncService.instance.triggerAutoBackup();
    return rows;
  }

  Future<int> deleteRecurringTransaction(int id) async {
    final db = await database;
    final rows = await db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    SyncService.instance.triggerAutoBackup();
    return rows;
  }
}