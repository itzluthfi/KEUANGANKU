import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // Ditambahkan sebagai dependensi jika ingin menghubungkan ke Laravel asli
import '../data/database_helper.dart';
import '../data/app_data.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  
  final ValueNotifier<bool> connectionStatus = ValueNotifier<bool>(true);
  Timer? _connectionCheckTimer;

  SyncService._init() {
    _startConnectionCheck();
    Future.delayed(const Duration(seconds: 3), () {
      uploadFcmToken();
    });
  }

  void _startConnectionCheck() {
    checkConnection().then((status) {
      connectionStatus.value = status;
      if (status) {
        syncOfflineReceipts();
      }
    });

    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final status = await checkConnection();
      if (connectionStatus.value != status) {
        connectionStatus.value = status;
        if (status) {
          // Ketika kembali online, otomatis trigger auto-backup untuk mengunggah perubahan lokal
          syncOfflineReceipts();
          triggerAutoBackup();
        }
      }
    });
  }

  Future<void> syncOfflineReceipts() async {
    if (!useRealServer) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> offlineReceipts = await db.query(
        'transaksi',
        where: 'receipt_path IS NOT NULL AND receipt_url IS NULL',
      );

      if (offlineReceipts.isEmpty) return;

      debugPrint("Menemukan ${offlineReceipts.length} struk offline untuk diunggah...");

      for (var r in offlineReceipts) {
        final path = r['receipt_path'] as String;
        final id = r['id'] as int;

        final file = File(path);
        if (!await file.exists()) {
          debugPrint("File struk tidak ditemukan di path lokal: $path");
          continue;
        }

        debugPrint("Mengunggah struk offline: $path");
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$laravelBaseUrl/receipts'),
        );
        request.headers['X-Danaku-API-Key'] = 'secure_danaku_key_2026';
        request.files.add(await http.MultipartFile.fromPath('image', path));

        final streamed = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamed);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final url = data['url'] as String?;
          if (url != null) {
            await db.update(
              'transaksi',
              {'receipt_url': url},
              where: 'id = ?',
              whereArgs: [id],
            );
            debugPrint("Struk berhasil diunggah dan disimpan ke database: $url");
          }
        } else {
          debugPrint("Gagal mengunggah struk offline (ID: $id): status ${response.statusCode}");
        }
      }

      // Update memory state
      final freshTransaksi = await DatabaseHelper.instance.fetchTransaksi();
      AppData.transaksi = freshTransaksi;
    } catch (e) {
      debugPrint("Error syncOfflineReceipts: $e");
    }
  }

  Future<bool> checkConnection() async {
    try {
      await http.get(Uri.parse(laravelBaseUrl)).timeout(const Duration(seconds: 2));
      return true;
    } catch (_) {
      return false;
    }
  }

  // Mode Penggunaan:
  // false = Menggunakan penyimpanan lokal terisolasi SQLite (Simulasi Awan) - 100% jalan secara offline
  // true = Menghubungkan secara nyata ke server REST API Laravel Anda di internet
  final bool useRealServer = true;
  // Gunakan 'http://127.0.0.1:8000/api' untuk Windows/Web, atau 'http://10.0.2.2:8000/api' untuk Android Emulator
  final String laravelBaseUrl = "https://api-danaku.sir-l.web.id/api";

  /// =========================================================================
  /// 🔑 BAGIAN 1: OTENTIKASI & MANAJEMEN AKUN
  /// =========================================================================

  /// Memeriksa apakah ada pengguna yang sedang login saat aplikasi dibuka
  Future<String?> getLoggedInUser() async {
    return await DatabaseHelper.instance.getSetting('logged_in_user');
  }

  /// Melakukan login / masuk akun
  Future<bool> login(String email, String password) async {
    if (useRealServer) {
      // 🌐 LINK KE LARAVEL ASLI:
      try {
        final response = await http.post(
          Uri.parse('$laravelBaseUrl/login'),
          body: {'email': email, 'password': password},
        );
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final token = responseData['token']; // Asumsi Laravel me-return token
          await DatabaseHelper.instance.saveSetting('logged_in_user', email);
          await DatabaseHelper.instance.saveSetting('auth_token', token);
          uploadFcmToken(); // Upload token setelah login sukses
          return true;
        }
        return false;
      } catch (e) {
        debugPrint("Error Real Server Login: $e");
        return false;
      }
    } else {
      // 💾 SIMULASI AWAN LOKAL:
      // Simulasi delay jaringan agar terasa realistis
      await Future.delayed(const Duration(milliseconds: 1000));

      // Ambil password terdaftar di database internal
      final savedPassword = await DatabaseHelper.instance.getSetting(
        'user_pwd_$email',
      );

      if (savedPassword != null && savedPassword == password) {
        // Simpan status login
        await DatabaseHelper.instance.saveSetting('logged_in_user', email);
        return true;
      }
      return false; // Email belum terdaftar atau password salah
    }
  }

  /// Mendaftarkan akun baru
  Future<bool> register(String email, String password) async {
    if (useRealServer) {
      // 🌐 LINK KE LARAVEL ASLI:
      try {
        final response = await http.post(
          Uri.parse('$laravelBaseUrl/register'),
          body: {'email': email, 'password': password},
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final token = responseData['token'];
          await DatabaseHelper.instance.saveSetting('logged_in_user', email);
          await DatabaseHelper.instance.saveSetting('auth_token', token);
          return true;
        }
        return false;
      } catch (e) {
        debugPrint("Error Real Server Register: $e");
        return false;
      }
    } else {
      // 💾 SIMULASI AWAN LOKAL:
      await Future.delayed(const Duration(milliseconds: 1000));

      // Simpan data pendaftaran secara lokal di tabel settings
      await DatabaseHelper.instance.saveSetting('user_pwd_$email', password);
      await DatabaseHelper.instance.saveSetting('logged_in_user', email);
      return true;
    }
  }

  /// Keluar dari akun (Logout)
  Future<void> logout() async {
    await DatabaseHelper.instance.deleteSetting('logged_in_user');
    await DatabaseHelper.instance.deleteSetting('auth_token');
  }

  /// =========================================================================
  /// ☁️ BAGIAN 2: PENCADANGAN & PEMULIHAN DATA
  /// =========================================================================

  /// Mencadangkan seluruh data transaksi, dompet, dan kategori saat ini ke Awan
  Future<void> backupData(String email) async {
    if (useRealServer) {
      // 🌐 LINK KE LARAVEL ASLI:
      try {
        final token = await DatabaseHelper.instance.getSetting('auth_token');
        final payload = await _buildBackupPayload();

        debugPrint("Real Server Backup: URL=$laravelBaseUrl/backup, Token=$token");

        final response = await http.post(
          Uri.parse('$laravelBaseUrl/backup'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        );

        debugPrint("Real Server Backup Response: Status=${response.statusCode}, Body=${response.body}");

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception("Server Error (${response.statusCode}): ${response.body}");
        }
      } catch (e) {
        debugPrint("Error Real Server Backup: $e");
        rethrow;
      }
    } else {
      // 💾 SIMULASI AWAN LOKAL:
      // Animasi delay progress simulasi
      await Future.delayed(const Duration(milliseconds: 2000));

      final payload = await _buildBackupPayload();
      final jsonString = jsonEncode(payload);

      // Simpan backup JSON terikat dengan email di database settings internal
      await DatabaseHelper.instance.saveSetting(
        'user_backup_$email',
        jsonString,
      );
    }
  }

  /// Melakukan pencadangan senyap di background (secara otomatis)
  /// jika ada user yang sedang login.
  Future<void> triggerAutoBackup() async {
    final email = await getLoggedInUser();
    if (email == null) return;

    if (useRealServer) {
      try {
        final token = await DatabaseHelper.instance.getSetting('auth_token');
        final payload = await _buildBackupPayload();

        http
            .post(
              Uri.parse('$laravelBaseUrl/backup'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            )
            .then((response) {
              if (response.statusCode == 200) {
                debugPrint(
                  "Auto-backup senyap berhasil dikirim ke Server Laravel",
                );
              }
            })
            .catchError((e) {
              debugPrint("Error Auto-backup Real Server: $e");
            });
      } catch (e) {
        debugPrint("Error Auto-backup: $e");
      }
    } else {
      final payload = await _buildBackupPayload();
      final jsonString = jsonEncode(payload);
      await DatabaseHelper.instance.saveSetting(
        'user_backup_$email',
        jsonString,
      );
      debugPrint("Auto-backup senyap berhasil disinkronkan untuk: $email");
    }
  }

  Future<Map<String, dynamic>?> fetchBackupPreview(String email) async {
    String? jsonString;
    if (useRealServer) {
      try {
        final token = await DatabaseHelper.instance.getSetting('auth_token');
        final response = await http.get(
          Uri.parse('$laravelBaseUrl/restore'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          return responseData['data'] as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint("Error fetching backup preview: $e");
      }
    } else {
      jsonString = await DatabaseHelper.instance.getSetting('user_backup_$email');
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    }
    return null;
  }

  /// Memulihkan data transaksi, dompet, dan kategori dari Awan berdasarkan email user
  Future<bool> restoreData(String email) async {
    String? jsonString;
    if (useRealServer) {
      // 🌐 LINK KE LARAVEL ASLI:
      try {
        final token = await DatabaseHelper.instance.getSetting('auth_token');
        debugPrint("Real Server Restore: URL=$laravelBaseUrl/restore, Token=$token");

        final response = await http.get(
          Uri.parse('$laravelBaseUrl/restore'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        debugPrint("Real Server Restore Response: Status=${response.statusCode}, Body=${response.body}");

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          jsonString = jsonEncode(
            responseData['data'],
          ); // Sesuaikan dengan struktur response Laravel Anda
        } else {
          debugPrint("Real Server Restore failed with status: ${response.statusCode}");
          return false;
        }
      } catch (e) {
        debugPrint("Error Real Server Restore: $e");
        rethrow;
      }
    } else {
      // 💾 SIMULASI AWAN LOKAL:
      await Future.delayed(const Duration(milliseconds: 2000));

      // Ambil data backup bertipe JSON string berdasarkan email
      jsonString = await DatabaseHelper.instance.getSetting(
        'user_backup_$email',
      );
    }

    if (jsonString == null) {
      return false; // Tidak ada data cadangan
    }

    try {
      final backupPayload = jsonDecode(jsonString) as Map<String, dynamic>;
      final transaksiList = backupPayload['transaksi'] as List;
      final walletsList = backupPayload['wallets'] as List;
      final categoriesList = backupPayload['categories'] as List;
      final deletedRecordsList = (backupPayload['deleted_records'] as List?) ?? [];

      final db = await DatabaseHelper.instance.database;

      // Gunakan Transaction SQLite agar aman, cepat, dan mencegah duplikasi
      await db.transaction((txn) async {
        // 0. Sinkronisasi Deletions dari Awan
        for (var dr in deletedRecordsList) {
          final drMap = Map<String, dynamic>.from(dr);
          final uuid = drMap['uuid'] as String?;
          if (uuid != null && uuid.isNotEmpty) {
            // Hapus transaksi lokal yang memiliki UUID ini
            await txn.delete('transaksi', where: 'uuid = ?', whereArgs: [uuid]);
            // Catat UUID penghapusan ini di deleted_records lokal jika belum terdaftar
            final existingDel = await txn.query('deleted_records', where: 'uuid = ?', whereArgs: [uuid]);
            if (existingDel.isEmpty) {
              await txn.insert('deleted_records', {
                'uuid': uuid,
                'deleted_at': drMap['deleted_at'] ?? DateTime.now().toIso8601String(),
              });
            }
          }
        }

        // 1. Sinkronisasi & Merge Dompet
        for (var w in walletsList) {
          final wMap = Map<String, dynamic>.from(w);
          final existing = await txn.query(
            'wallets',
            where: 'nama = ? AND book_id = ?',
            whereArgs: [wMap['nama'], wMap['book_id']],
          );
          if (existing.isEmpty) {
            await txn.insert('wallets', {
              'book_id': wMap['book_id'],
              'nama': wMap['nama'],
              'saldo': wMap['saldo'],
              'jenis': wMap['jenis'],
              'icon_code': wMap['icon_code'],
            });
          } else {
            // Update detail dompet dari cloud
            await txn.update(
              'wallets',
              {
                'saldo': wMap['saldo'],
                'jenis': wMap['jenis'],
                'icon_code': wMap['icon_code'],
              },
              where: 'nama = ? AND book_id = ?',
              whereArgs: [wMap['nama'], wMap['book_id']],
            );
          }
        }

        // 2. Sinkronisasi & Merge Kategori
        for (var c in categoriesList) {
          final cMap = Map<String, dynamic>.from(c);
          final existing = await txn.query(
            'categories',
            where: 'name = ? AND type = ? AND book_id = ?',
            whereArgs: [cMap['name'], cMap['type'], cMap['book_id']],
          );
          if (existing.isEmpty) {
            await txn.insert('categories', {
              'book_id': cMap['book_id'],
              'name': cMap['name'],
              'type': cMap['type'],
              'icon_code': cMap['icon_code'],
            });
          }
        }

        // 3. Sinkronisasi & Merge Transaksi (Deduplikasi cerdas berdasarkan UUID dengan fallback detail)
        for (var t in transaksiList) {
          final tMap = Map<String, dynamic>.from(t);
          final uuid = tMap['uuid'] as String?;
          
          if (uuid != null && uuid.isNotEmpty) {
            // Lewati jika transaksi sudah terhapus locally
            final localDeleted = await txn.query('deleted_records', where: 'uuid = ?', whereArgs: [uuid]);
            if (localDeleted.isNotEmpty) {
              continue;
            }

            final existing = await txn.query(
              'transaksi',
              where: 'uuid = ?',
              whereArgs: [uuid],
            );

            if (existing.isEmpty) {
              await txn.insert('transaksi', {
                'book_id': tMap['book_id'],
                'keterangan': tMap['keterangan'],
                'jumlah': tMap['jumlah'],
                'jenis': tMap['jenis'],
                'tanggal': tMap['tanggal'],
                'walletNama': tMap['walletNama'],
                'kategori': tMap['kategori'],
                'items_json': tMap['items_json'],
                'receipt_path': tMap['receipt_path'],
                'receipt_url': tMap['receipt_url'],
                'uuid': uuid,
              });
            } else {
              await txn.update(
                'transaksi',
                {
                  'book_id': tMap['book_id'],
                  'keterangan': tMap['keterangan'],
                  'jumlah': tMap['jumlah'],
                  'jenis': tMap['jenis'],
                  'tanggal': tMap['tanggal'],
                  'walletNama': tMap['walletNama'],
                  'kategori': tMap['kategori'],
                  'items_json': tMap['items_json'],
                  'receipt_path': tMap['receipt_path'],
                  'receipt_url': tMap['receipt_url'],
                },
                where: 'uuid = ?',
                whereArgs: [uuid],
              );
            }
          } else {
            // Fallback untuk data cadangan lama tanpa UUID
            final existing = await txn.query(
              'transaksi',
              where: 'keterangan = ? AND jumlah = ? AND jenis = ? AND tanggal = ? AND walletNama = ? AND kategori = ? AND book_id = ?',
              whereArgs: [
                tMap['keterangan'],
                tMap['jumlah'],
                tMap['jenis'],
                tMap['tanggal'],
                tMap['walletNama'],
                tMap['kategori'],
                tMap['book_id'],
              ],
            );

            if (existing.isEmpty) {
              final generatedUuid = DatabaseHelper.instance.generateUuid();
              await txn.insert('transaksi', {
                'book_id': tMap['book_id'],
                'keterangan': tMap['keterangan'],
                'jumlah': tMap['jumlah'],
                'jenis': tMap['jenis'],
                'tanggal': tMap['tanggal'],
                'walletNama': tMap['walletNama'],
                'kategori': tMap['kategori'],
                'items_json': tMap['items_json'],
                'receipt_path': tMap['receipt_path'],
                'receipt_url': tMap['receipt_url'],
                'uuid': generatedUuid,
              });
            }
          }
        }
      });

      // Sinkronkan memori aplikasi (AppData) dengan data SQLite yang baru direstore
      final freshWallets = await DatabaseHelper.instance.fetchWallets();
      AppData.wallets = freshWallets;

      final freshTransaksi = await DatabaseHelper.instance.fetchTransaksi();
      AppData.transaksi = freshTransaksi;

      return true;
    } catch (e) {
      debugPrint("Error saat parsing/mengimpor data restore: $e");
      return false;
    }
  }

  /// Helper untuk menyusun payload JSON cadangan dari seluruh tabel database lokal
  Future<Map<String, dynamic>> _buildBackupPayload() async {
    final db = await DatabaseHelper.instance.database;

    final transaksiRaw = await db.query('transaksi');
    final walletsRaw = await db.query('wallets');
    final categoriesRaw = await db.query('categories');
    final deletedRecordsRaw = await db.query('deleted_records');

    return {
      'transaksi': transaksiRaw,
      'wallets': walletsRaw,
      'categories': categoriesRaw,
      'deleted_records': deletedRecordsRaw,
      'backup_date': DateTime.now().toIso8601String(),
    };
  }

  /// Mengambil FCM token dan mengunggahnya ke Laravel
  Future<void> uploadFcmToken() async {
    try {
      final token = await DatabaseHelper.instance.getSetting('auth_token');
      if (token == null) return;

      // 1. Dapatkan Token dari Firebase Messaging
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      debugPrint("Mendapatkan FCM Token: $fcmToken");

      // 2. Unggah ke Laravel
      final response = await http.post(
        Uri.parse('$laravelBaseUrl/save-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint("FCM Token berhasil diunggah ke server.");
      } else {
        debugPrint("Gagal mengunggah FCM Token: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error uploadFcmToken: $e");
    }
  }
}
