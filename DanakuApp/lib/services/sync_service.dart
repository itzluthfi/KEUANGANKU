import 'dart:convert';
import 'dart:async';
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
    });

    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final status = await checkConnection();
      if (connectionStatus.value != status) {
        connectionStatus.value = status;
        if (status) {
          // Ketika kembali online, otomatis trigger auto-backup untuk mengunggah perubahan lokal
          triggerAutoBackup();
        }
      }
    });
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

        final response = await http.post(
          Uri.parse('$laravelBaseUrl/backup'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode != 200) {
          throw Exception("Gagal mengunggah data ke Laravel Server");
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

  /// Memulihkan (Restore) data cadangan terakhir dari Awan dan menimpa database lokal
  Future<bool> restoreData(String email) async {
    String? jsonString;

    if (useRealServer) {
      // 🌐 LINK KE LARAVEL ASLI:
      try {
        final token = await DatabaseHelper.instance.getSetting('auth_token');
        final response = await http.get(
          Uri.parse('$laravelBaseUrl/restore'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          jsonString = jsonEncode(
            responseData['data'],
          ); // Sesuaikan dengan struktur response Laravel Anda
        } else {
          return false;
        }
      } catch (e) {
        debugPrint("Error Real Server Restore: $e");
        return false;
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

      final db = await DatabaseHelper.instance.database;

      // Gunakan Transaction SQLite agar aman dan cepat
      await db.transaction((txn) async {
        // Hapus isi tabel saat ini
        await txn.delete('transaksi');
        await txn.delete('wallets');
        await txn.delete('categories');

        // Masukkan data dompet hasil restore
        for (var w in walletsList) {
          await txn.insert('wallets', Map<String, dynamic>.from(w));
        }

        // Masukkan data transaksi hasil restore
        for (var t in transaksiList) {
          await txn.insert('transaksi', Map<String, dynamic>.from(t));
        }

        // Masukkan data kategori hasil restore
        for (var c in categoriesList) {
          await txn.insert('categories', Map<String, dynamic>.from(c));
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

    return {
      'transaksi': transaksiRaw,
      'wallets': walletsRaw,
      'categories': categoriesRaw,
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
