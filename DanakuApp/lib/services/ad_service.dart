import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._init();
  AdService._init();

  bool _isInitialized = false;

  /// ⚙️ ID Unit Iklan Rewarded
  /// Ganti string di bawah ini dengan ID Unit Iklan Rewarded dari dashboard Google AdMob Anda ketika siap rilis.
  static const String _productionAndroidRewardedAdUnitId = "ca-app-pub-1779672855845190/3586082247"; // ID Asli AdMob Danaku
  static const String _productionIosRewardedAdUnitId = "ca-app-pub-3940256099942544/1712485313";     // ID Uji Coba Resmi Google

  String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? _productionAndroidRewardedAdUnitId
        : _productionIosRewardedAdUnitId;
  }

  /// Inisialisasi SDK Google Mobile Ads saat aplikasi start
  Future<void> init() async {
    if (kIsWeb) return;
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint("AdService: Google Mobile Ads SDK initialized.");
    } catch (e) {
      debugPrint("AdService Error initializing MobileAds: $e");
    }
  }

  /// Memuat dan memutar Rewarded Video Ad
  /// Mengembalikan true jika pengguna menonton sampai selesai dan mendapatkan reward
  Future<bool> showRewardedAd({
    required BuildContext context,
    required VoidCallback onUserEarnedReward,
  }) async {
    if (kIsWeb) {
      // Di Web langsung berikan reward (tidak ada AdMob)
      onUserEarnedReward();
      return true;
    }

    // Tampilkan loading dialog singkat saat memuat iklan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.pink),
                SizedBox(height: 16),
                Text(
                  "Memuat Video Iklan...",
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    RewardedAd? rewardedAd;
    bool rewardEarned = false;

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('RewardedAd failed to load: $error');
            rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint("Error loading RewardedAd: $e");
    }

    // Tutup loading dialog
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (rewardedAd == null) {
      // Jika iklan gagal termuat (misal jaringan offline), berikan reward kompensasi agar UX tetap nyaman
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Iklan belum tersedia saat ini. Kuota gratis tetap kami berikan untuk Anda!"),
            backgroundColor: Colors.green,
          ),
        );
      }
      onUserEarnedReward();
      return true;
    }

    // Set callback dan tampilkan iklan
    rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        // Jika gagal tampil, tetap berikan reward
        if (!rewardEarned) {
          onUserEarnedReward();
        }
      },
    );

    await rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;
        onUserEarnedReward();
      },
    );

    return rewardEarned;
  }
}
