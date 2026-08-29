import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../widgets/custom_snackbar.dart';
import 'ad_service.dart';

class AiQuotaService {
  static final AiQuotaService instance = AiQuotaService._init();
  AiQuotaService._init();

  static const int defaultDailyFreeQuota = 5;
  static const int rewardBonusQuota = 5;

  /// Mengambil sisa kuota AI hari ini. Otomatis reset ke 5 setiap pergantian tanggal (tengah malam).
  Future<int> getRemainingQuota() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastQuotaDate = await DatabaseHelper.instance.getSetting('ai_quota_date');

    if (lastQuotaDate != todayStr) {
      // Hari baru: reset kuota ke default (5 tiket gratis)
      await DatabaseHelper.instance.saveSetting('ai_quota_date', todayStr);
      await DatabaseHelper.instance.saveSetting('ai_quota_remaining', defaultDailyFreeQuota.toString());
      return defaultDailyFreeQuota;
    }

    final remainingStr = await DatabaseHelper.instance.getSetting('ai_quota_remaining');
    return int.tryParse(remainingStr ?? '') ?? defaultDailyFreeQuota;
  }

  /// Mengurangi 1 kuota saat fitur AI sukses digunakan
  Future<bool> consumeQuota() async {
    final remaining = await getRemainingQuota();
    if (remaining > 0) {
      final newRemaining = remaining - 1;
      await DatabaseHelper.instance.saveSetting('ai_quota_remaining', newRemaining.toString());
      return true;
    }
    return false;
  }

  /// Menambahkan bonus kuota setelah menonton video iklan berhadiah (+5)
  Future<int> addBonusQuota({int amount = rewardBonusQuota}) async {
    final current = await getRemainingQuota();
    final newQuota = current + amount;
    await DatabaseHelper.instance.saveSetting('ai_quota_remaining', newQuota.toString());
    return newQuota;
  }

  /// Memeriksa apakah masih ada kuota. Jika kuota 0, langsung tampilkan modal penawaran iklan berhadiah.
  /// Mengembalikan true jika kuota tersedia (atau reward berhasil didapat), false jika batal.
  Future<bool> checkAndRequireQuota(
    BuildContext context, {
    required VoidCallback onRewardGranted,
  }) async {
    final remaining = await getRemainingQuota();
    if (remaining > 0) {
      return true;
    }

    if (!context.mounted) return false;

    // Kuota habis -> Tampilkan Pop-up Penawaran Rewarded Ad
    final bool? watchAd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.pink, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Kuota AI Harian Habis",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit'),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Anda telah menggunakan seluruh jatah 5x Scan AI gratis hari ini.",
              style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87, fontFamily: 'Outfit'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.video_collection_outlined, color: Colors.pink, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tonton video singkat (15–30 dtk) untuk mendapatkan +5 Kuota AI Tambahan!",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.pink, fontFamily: 'Outfit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Lanjut Tanpa AI",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
            label: const Text(
              "Tonton Video (+5)",
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (watchAd == true && context.mounted) {
      final success = await AdService.instance.showRewardedAd(
        context: context,
        onUserEarnedReward: () async {
          final newTotal = await addBonusQuota(amount: rewardBonusQuota);
          if (context.mounted) {
            CustomSnackBar.show(
              context,
              message: "Selamat! +$rewardBonusQuota Kuota Scan AI berhasil ditambahkan. (Sisa: $newTotal)",
              isSuccess: true,
            );
          }
          onRewardGranted();
        },
      );
      return success;
    }

    return false;
  }
}
