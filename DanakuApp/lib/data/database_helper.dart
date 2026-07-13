import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'app_data.dart';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_app_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path, 
      version: 9, 
      onCreate: _createDB, 
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT,
          deleted_at TEXT
        )
        ''');
      },
    );
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
      items_json TEXT,
      receipt_path TEXT,
      receipt_url TEXT,
      uuid TEXT,
      transfer_linked_uuid TEXT
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

    await db.execute('''
    CREATE TABLE IF NOT EXISTS category_budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER DEFAULT 1,
      kategori TEXT UNIQUE,
      limit_jumlah INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS debts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER DEFAULT 1,
      tipe TEXT,
      kontak TEXT,
      keterangan TEXT,
      jumlah INTEGER,
      terbayar INTEGER DEFAULT 0,
      tanggal TEXT,
      jatuh_tempo TEXT,
      status TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      book_id INTEGER DEFAULT 1,
      nama TEXT,
      target_jumlah INTEGER,
      terkumpul INTEGER DEFAULT 0,
      jatuh_tempo TEXT,
      status TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS deleted_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT,
      deleted_at TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS ai_chat_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      advice_text TEXT,
      provider TEXT,
      total_income INTEGER,
      total_expense INTEGER,
      created_at TEXT
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
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE transaksi ADD COLUMN receipt_path TEXT');
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE transaksi ADD COLUMN receipt_url TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 6) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS category_budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER DEFAULT 1,
        kategori TEXT UNIQUE,
        limit_jumlah INTEGER
      )
      ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER DEFAULT 1,
        tipe TEXT,
        kontak TEXT,
        keterangan TEXT,
        jumlah INTEGER,
        terbayar INTEGER DEFAULT 0,
        tanggal TEXT,
        jatuh_tempo TEXT,
        status TEXT
      )
      ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER DEFAULT 1,
        nama TEXT,
        target_jumlah INTEGER,
        terkumpul INTEGER DEFAULT 0,
        jatuh_tempo TEXT,
        status TEXT
      )
      ''');
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE transaksi ADD COLUMN uuid TEXT');
      } catch (e) {
        // Column might already exist
      }
      await db.execute('''
      CREATE TABLE IF NOT EXISTS deleted_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT,
        deleted_at TEXT
      )
      ''');
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE transaksi ADD COLUMN transfer_linked_uuid TEXT');
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 9) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        advice_text TEXT,
        provider TEXT,
        total_income INTEGER,
        total_expense INTEGER,
        created_at TEXT
      )
      ''');
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
    if (key == 'secure_pin' || key == 'auth_token') {
      try {
        await _secureStorage.write(key: key, value: value);
        return;
      } catch (e) {
        debugPrint("Secure storage write error: $e");
      }
    }

    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    if (key == 'secure_pin' || key == 'auth_token') {
      try {
        final val = await _secureStorage.read(key: key);
        if (val != null) return val;
      } catch (e) {
        debugPrint("Secure storage read error: $e");
      }
    }

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
    if (key == 'secure_pin' || key == 'auth_token') {
      try {
        await _secureStorage.delete(key: key);
      } catch (e) {
        debugPrint("Secure storage delete error: $e");
      }
    }

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
      if (tMap['uuid'] == null || tMap['uuid'].toString().isEmpty) {
        tMap['uuid'] = generateUuid();
      }
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

    if (t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran') {
      _checkBudgetNotification();
      _checkCategoryBudgetNotification(t.kategori);
    }
    updateHomeWidgetData();
  }

  Future<void> _checkBudgetNotification() async {
    final budgetStr = await getSetting('monthly_budget');
    final budget = int.tryParse(budgetStr ?? '0') ?? 0;
    if (budget <= 0) return;

    final all = await fetchTransaksi();
    final now = DateTime.now();
    final currentMonthExpense = all
        .where((tr) => tr.tanggal.month == now.month && tr.tanggal.year == now.year && (tr.jenis.toLowerCase() == 'keluar' || tr.jenis.toLowerCase() == 'pengeluaran'))
        .fold(0, (sum, tr) => sum + tr.jumlah);

    if (currentMonthExpense >= budget) {
      await NotificationService.instance.showCustomNotification(
        id: 999,
        title: "🚨 Batas Anggaran Terlewati!",
        body: "Total pengeluaran Anda bulan ini (Rp ${NumberFormat.decimalPattern('id').format(currentMonthExpense)}) telah melampaui limit anggaran bulanan (Rp ${NumberFormat.decimalPattern('id').format(budget)}).",
      );
    } else if (currentMonthExpense >= budget * 0.8) {
      await NotificationService.instance.showCustomNotification(
        id: 998,
        title: "⚠️ Peringatan Batas Anggaran (80%)",
        body: "Total pengeluaran Anda bulan ini (Rp ${NumberFormat.decimalPattern('id').format(currentMonthExpense)}) telah mencapai 80% dari limit anggaran bulanan (Rp ${NumberFormat.decimalPattern('id').format(budget)}).",
      );
    }
  }

  Future<void> _checkCategoryBudgetNotification(String kategori) async {
    final db = await database;
    final List<Map<String, dynamic>> categoryLimitMaps = await db.query(
      'category_budgets',
      where: 'kategori = ? AND book_id = ?',
      whereArgs: [kategori, AppData.activeBookId],
    );

    if (categoryLimitMaps.isNotEmpty) {
      int limit = categoryLimitMaps.first['limit_jumlah'] as int;
      if (limit <= 0) return;

      final all = await fetchTransaksi();
      final now = DateTime.now();

      final categorySpent = all
          .where((tr) => tr.kategori.toLowerCase() == kategori.toLowerCase() && tr.tanggal.month == now.month && tr.tanggal.year == now.year && (tr.jenis.toLowerCase() == 'keluar' || tr.jenis.toLowerCase() == 'pengeluaran'))
          .fold(0, (sum, tr) => sum + tr.jumlah);

      if (categorySpent >= limit) {
        await NotificationService.instance.showCustomNotification(
          id: 1000 + kategori.hashCode,
          title: "🚨 Anggaran Kategori Terlampaui!",
          body: "Pengeluaran untuk kategori '$kategori' (Rp ${NumberFormat.decimalPattern('id').format(categorySpent)}) telah melampaui limit bulanan kategori Anda (Rp ${NumberFormat.decimalPattern('id').format(limit)}).",
        );
      } else if (categorySpent >= limit * 0.8) {
        await NotificationService.instance.showCustomNotification(
          id: 1000 + kategori.hashCode,
          title: "⚠️ Peringatan Anggaran Kategori (80%)",
          body: "Pengeluaran untuk kategori '$kategori' (Rp ${NumberFormat.decimalPattern('id').format(categorySpent)}) telah mencapai 80% dari limit bulanan kategori Anda (Rp ${NumberFormat.decimalPattern('id').format(limit)}).",
        );
      }
    }
  }

  Future<List<Transaksi>> fetchTransaksi() async {
    final db = await database;
    final result = await db.query('transaksi', where: 'book_id = ?', whereArgs: [AppData.activeBookId], orderBy: 'tanggal DESC');
    return result.map((json) => Transaksi.fromMap(json)).toList();
  }

  Future<Map<String, String>?> getSuggestionForDescription(String desc) async {
    if (desc.trim().isEmpty) return null;
    final db = await database;
    final result = await db.rawQuery('''
      SELECT kategori, walletNama, COUNT(*) as cnt 
      FROM transaksi 
      WHERE LOWER(keterangan) = ? AND book_id = ?
      GROUP BY kategori, walletNama 
      ORDER BY cnt DESC LIMIT 1
    ''', [desc.trim().toLowerCase(), AppData.activeBookId]);

    if (result.isNotEmpty) {
      return {
        'kategori': result.first['kategori'] as String? ?? '',
        'walletNama': result.first['walletNama'] as String? ?? '',
      };
    }
    return null;
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

  Future<void> _reverseWalletBalance(Transaction txn, String walletNama, String jenis, int jumlah) async {
    final List<Map<String, dynamic>> walletMaps = await txn.query(
      'wallets',
      where: 'nama = ? AND book_id = ?',
      whereArgs: [walletNama, AppData.activeBookId],
    );

    if (walletMaps.isNotEmpty) {
      int saldoSekarang = walletMaps.first['saldo'] as int;
      int saldoBaru;
      if (jenis.toLowerCase() == 'keluar' || jenis.toLowerCase() == 'pengeluaran') {
        saldoBaru = saldoSekarang + jumlah;
      } else {
        saldoBaru = saldoSekarang - jumlah;
      }
      await txn.update(
        'wallets', 
        {'saldo': saldoBaru}, 
        where: 'nama = ? AND book_id = ?', 
        whereArgs: [walletNama, AppData.activeBookId]
      );
    }
  }

  Future<void> _applyWalletBalance(Transaction txn, String walletNama, String jenis, int jumlah) async {
    final List<Map<String, dynamic>> walletMaps = await txn.query(
      'wallets',
      where: 'nama = ? AND book_id = ?',
      whereArgs: [walletNama, AppData.activeBookId],
    );

    if (walletMaps.isNotEmpty) {
      int saldoSekarang = walletMaps.first['saldo'] as int;
      int saldoBaru;
      if (jenis.toLowerCase() == 'keluar' || jenis.toLowerCase() == 'pengeluaran') {
        saldoBaru = saldoSekarang - jumlah;
      } else {
        saldoBaru = saldoSekarang + jumlah;
      }
      await txn.update(
        'wallets', 
        {'saldo': saldoBaru}, 
        where: 'nama = ? AND book_id = ?', 
        whereArgs: [walletNama, AppData.activeBookId]
      );
    }
  }

  Future<void> deleteTransaksi(Transaksi t) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Dapatkan UUID dan linked UUID dari DB (jika belum ada di objek)
      String? txUuid = t.uuid;
      String? linkedUuid = t.transferLinkedUuid;
      
      final List<Map<String, dynamic>> trMaps = await txn.query(
        'transaksi',
        columns: ['uuid', 'transfer_linked_uuid'],
        where: 'id = ?',
        whereArgs: [t.id],
      );
      
      if (trMaps.isNotEmpty) {
        txUuid = trMaps.first['uuid'] as String?;
        linkedUuid = trMaps.first['transfer_linked_uuid'] as String?;
      }

      // 2. Reverse wallet balance transaksi utama
      await _reverseWalletBalance(txn, t.walletNama, t.jenis, t.jumlah);

      // 3. Catat di deleted_records
      if (txUuid != null && txUuid.isNotEmpty) {
        await txn.insert('deleted_records', {
          'uuid': txUuid,
          'deleted_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Hapus transaksi utama
      await txn.delete('transaksi', where: 'id = ?', whereArgs: [t.id]);

      // 5. Handle pasangan transfer jika terhubung
      if (linkedUuid != null && linkedUuid.isNotEmpty) {
        final List<Map<String, dynamic>> counterparts = await txn.query(
          'transaksi',
          where: 'transfer_linked_uuid = ? AND id != ?',
          whereArgs: [linkedUuid, t.id],
        );
        for (var cp in counterparts) {
          final cpId = cp['id'] as int;
          final cpUuid = cp['uuid'] as String?;
          final cpWallet = cp['walletNama'] as String;
          final cpJenis = cp['jenis'] as String;
          final cpJumlah = cp['jumlah'] as int;

          // Reverse wallet balance pasangan
          await _reverseWalletBalance(txn, cpWallet, cpJenis, cpJumlah);

          // Catat di deleted_records
          if (cpUuid != null && cpUuid.isNotEmpty) {
            await txn.insert('deleted_records', {
              'uuid': cpUuid,
              'deleted_at': DateTime.now().toIso8601String(),
            });
          }

          // Hapus pasangan
          await txn.delete('transaksi', where: 'id = ?', whereArgs: [cpId]);
        }
      }
    });

    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
    updateHomeWidgetData();
  }

  Future<void> updateTransaksi(Transaksi oldT, Transaksi newT) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Dapatkan linked UUID transaksi lama dari DB
      String? linkedUuid = oldT.transferLinkedUuid;
      final List<Map<String, dynamic>> trMaps = await txn.query(
        'transaksi',
        columns: ['transfer_linked_uuid'],
        where: 'id = ?',
        whereArgs: [oldT.id],
      );
      if (trMaps.isNotEmpty) {
        linkedUuid = trMaps.first['transfer_linked_uuid'] as String?;
      }

      // 2. Update transaksi utama
      await _reverseWalletBalance(txn, oldT.walletNama, oldT.jenis, oldT.jumlah);
      await _applyWalletBalance(txn, newT.walletNama, newT.jenis, newT.jumlah);

      Map<String, dynamic> newTMap = newT.toMap();
      newTMap['book_id'] = AppData.activeBookId;
      newTMap['transfer_linked_uuid'] = linkedUuid; // pastikan tetap terhubung
      await txn.update(
        'transaksi', 
        newTMap, 
        where: 'id = ?', 
        whereArgs: [oldT.id]
      );

      // 3. Update pasangan transfer jika ada
      if (linkedUuid != null && linkedUuid.isNotEmpty) {
        final List<Map<String, dynamic>> counterparts = await txn.query(
          'transaksi',
          where: 'transfer_linked_uuid = ? AND id != ?',
          whereArgs: [linkedUuid, oldT.id],
        );
        for (var cp in counterparts) {
          final cpId = cp['id'] as int;
          final cpWallet = cp['walletNama'] as String;
          final cpJenis = cp['jenis'] as String;
          final cpJumlah = cp['jumlah'] as int;

          // Hitung & update saldo lama pasangan
          await _reverseWalletBalance(txn, cpWallet, cpJenis, cpJumlah);
          
          // Terapkan saldo baru pasangan dengan nominal yang baru (newT.jumlah)
          await _applyWalletBalance(txn, cpWallet, cpJenis, newT.jumlah);

          // Update data pasangan di tabel transaksi (keterangan, jumlah, tanggal)
          await txn.update(
            'transaksi',
            {
              'jumlah': newT.jumlah,
              'tanggal': newT.tanggal.toIso8601String(),
              'keterangan': newT.keterangan,
            },
            where: 'id = ?',
            whereArgs: [cpId],
          );
        }
      }
    });

    // Trigger pencadangan otomatis senyap di background jika user login
    SyncService.instance.triggerAutoBackup();
    updateHomeWidgetData();
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

  // --- CRUD ANGGARAN KATEGORI ---
  Future<List<Map<String, dynamic>>> fetchCategoryBudgets() async {
    final db = await database;
    return await db.query('category_budgets', where: 'book_id = ?', whereArgs: [AppData.activeBookId]);
  }

  Future<void> saveCategoryBudget(String kategori, int limitJumlah) async {
    final db = await database;
    await db.insert(
      'category_budgets',
      {
        'book_id': AppData.activeBookId,
        'kategori': kategori,
        'limit_jumlah': limitJumlah,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> deleteCategoryBudget(String kategori) async {
    final db = await database;
    await db.delete(
      'category_budgets',
      where: 'kategori = ? AND book_id = ?',
      whereArgs: [kategori, AppData.activeBookId],
    );
    SyncService.instance.triggerAutoBackup();
  }

  // --- CRUD UTANG PIUTANG (DEBTS) ---
  Future<List<Map<String, dynamic>>> fetchDebts() async {
    final db = await database;
    return await db.query('debts', where: 'book_id = ?', whereArgs: [AppData.activeBookId]);
  }

  Future<int> insertDebt(Map<String, dynamic> debt) async {
    final db = await database;
    final map = Map<String, dynamic>.from(debt);
    map['book_id'] = AppData.activeBookId;
    final id = await db.insert('debts', map);
    SyncService.instance.triggerAutoBackup();
    return id;
  }

  Future<void> updateDebtPayback(int id, int terbayar, String status) async {
    final db = await database;
    await db.update(
      'debts',
      {
        'terbayar': terbayar,
        'status': status,
      },
      where: 'id = ? AND book_id = ?',
      whereArgs: [id, AppData.activeBookId],
    );
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> deleteDebt(int id) async {
    final db = await database;
    await db.delete(
      'debts',
      where: 'id = ? AND book_id = ?',
      whereArgs: [id, AppData.activeBookId],
    );
    SyncService.instance.triggerAutoBackup();
  }

  // --- CRUD GOALS (SAVINGS) ---
  Future<List<Map<String, dynamic>>> fetchGoals() async {
    final db = await database;
    return await db.query('goals', where: 'book_id = ?', whereArgs: [AppData.activeBookId]);
  }

  Future<void> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;
    final map = Map<String, dynamic>.from(goal);
    map['book_id'] = AppData.activeBookId;
    await db.insert('goals', map);
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> updateGoalTerkumpul(int id, int terkumpul, String status) async {
    final db = await database;
    await db.update(
      'goals',
      {
        'terkumpul': terkumpul,
        'status': status,
      },
      where: 'id = ? AND book_id = ?',
      whereArgs: [id, AppData.activeBookId],
    );
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete(
      'goals',
      where: 'id = ? AND book_id = ?',
      whereArgs: [id, AppData.activeBookId],
    );
    SyncService.instance.triggerAutoBackup();
  }

  Future<void> updateHomeWidgetData() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    try {
      final all = await fetchTransaksi();
      final now = DateTime.now();
      final currentMonthExpense = all
          .where((tr) => tr.tanggal.month == now.month && tr.tanggal.year == now.year && (tr.jenis.toLowerCase() == 'keluar' || tr.jenis.toLowerCase() == 'pengeluaran'))
          .fold(0, (sum, tr) => sum + tr.jumlah);

      final currentMonthIncome = all
          .where((tr) => tr.tanggal.month == now.month && tr.tanggal.year == now.year && (tr.jenis.toLowerCase() == 'masuk' || tr.jenis.toLowerCase() == 'pemasukan'))
          .fold(0, (sum, tr) => sum + tr.jumlah);

      final balance = currentMonthIncome - currentMonthExpense;

      final formattedExpense = "Rp ${NumberFormat.decimalPattern('id').format(currentMonthExpense)}";
      final formattedIncome = "Rp ${NumberFormat.decimalPattern('id').format(currentMonthIncome)}";
      final formattedBalance = "Rp ${NumberFormat.decimalPattern('id').format(balance)}";

      await HomeWidget.saveWidgetData<String>("expense_value", formattedExpense);
      await HomeWidget.saveWidgetData<String>("income_value", formattedIncome);
      await HomeWidget.saveWidgetData<String>("balance_value", formattedBalance);

      await HomeWidget.updateWidget(
        name: 'HomeWidgetProvider',
        androidName: 'HomeWidgetProvider',
      );
      debugPrint("Home widget updated: Exp $formattedExpense, Inc $formattedIncome, Bal $formattedBalance");
    } catch (e) {
      debugPrint("Error updating home widget data: $e");
    }
  }

  String generateUuid() {
    final random = Random();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  // --- FUNGSI RIWAYAT SARAN AI ---
  Future<int> insertAiAdvice(String advice, String provider, int income, int expense) async {
    final db = await database;
    return await db.insert('ai_chat_history', {
      'advice_text': advice,
      'provider': provider,
      'total_income': income,
      'total_expense': expense,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchAiAdviceHistory() async {
    final db = await database;
    return await db.query('ai_chat_history', orderBy: 'created_at DESC');
  }

  Future<int> clearAiAdviceHistory() async {
    final db = await database;
    return await db.delete('ai_chat_history');
  }
}