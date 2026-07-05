import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_page.dart';
import 'pin_lock_page.dart';
import '../data/database_helper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // System UI status bar setup for splash screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Jalankan timer untuk beralih layar setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _navigateToNextScreen();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    final pinEnabled = await DatabaseHelper.instance.getSetting('pin_enabled');
    final securePin = await DatabaseHelper.instance.getSetting('secure_pin');

    if (!mounted) return;

    if (pinEnabled == 'true' && securePin != null) {
      // Beralih ke layar PIN
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const PinLockPage(),
          settings: const RouteSettings(name: '/pin-lock'),
        ),
        (route) => false,
      );
    } else {
      // Langsung masuk ke halaman utama jika PIN tidak aktif
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: 0.5 + (_scaleAnimation.value * 0.5),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFFFF528F),
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "DANAKU",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Catat Keuangan dengan Cerdas",
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
