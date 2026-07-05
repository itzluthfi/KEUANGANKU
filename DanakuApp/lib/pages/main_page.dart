import 'package:flutter/material.dart';
import 'home_page.dart';
import 'wallet_page.dart';
import 'report_page.dart';
import 'transaction_input_page.dart';
import 'setting_page.dart';
import 'pin_lock_page.dart';
import '../data/database_helper.dart';
import 'package:lottie/lottie.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int currentIndex = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey();
  bool _showPinLock = false;
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPinLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final diff = DateTime.now().difference(_pausedTime!);
        if (diff.inSeconds >= 30) {
          _checkPinLock();
        }
      }
      _pausedTime = null;
    }
  }

  Future<void> _checkPinLock() async {
    final pinEnabled = await DatabaseHelper.instance.getSetting('pin_enabled');
    final securePin = await DatabaseHelper.instance.getSetting('secure_pin');
    if (pinEnabled == 'true' && securePin != null) {
      setState(() {
        _showPinLock = true;
      });
      if (mounted) {
        final unlocked = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PinLockPage(),
            settings: const RouteSettings(name: '/pin-lock'),
          ),
        );
        if (unlocked == true) {
          setState(() {
            _showPinLock = false;
          });
        }
      }
    }
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomePage(key: _homeKey);
      case 1:
        return const WalletPage();
      case 2:
        return const ReportPage();
      case 3:
        return const SettingPage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showPinLock) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF528F), Color(0xFFFF7A9F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: _getPage(currentIndex),
      floatingActionButton: currentIndex == 0 ? FloatingActionButton(
        backgroundColor: const Color(0xFFFF528F),
        elevation: 6,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionInputPage(initialJenis: "masuk"),
            ),
          );
          _homeKey.currentState?.loadData();
        },
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ) : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFFF528F),
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
            ),
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      currentIndex == 0 ? const Color(0xFFFF528F) : Colors.grey.shade400,
                      BlendMode.srcIn,
                    ),
                    child: Lottie.asset(
                      'assets/icons/home-icon.json',
                      key: ValueKey(currentIndex == 0),
                      width: 24,
                      height: 24,
                      animate: true,
                      repeat: false,
                    ),
                  ),
                ),
                label: "Beranda",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      currentIndex == 1 ? const Color(0xFFFF528F) : Colors.grey.shade400,
                      BlendMode.srcIn,
                    ),
                    child: Lottie.asset(
                      'assets/icons/wallet.json',
                      key: ValueKey(currentIndex == 1),
                      width: 24,
                      height: 24,
                      animate: true,
                      repeat: false,
                    ),
                  ),
                ),
                label: "Dompet",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      currentIndex == 2 ? const Color(0xFFFF528F) : Colors.grey.shade400,
                      BlendMode.srcIn,
                    ),
                    child: Lottie.asset(
                      'assets/icons/chart-loop.json',
                      width: 24,
                      height: 24,
                      animate: true,
                      repeat: true,
                    ),
                  ),
                ),
                label: "Laporan",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      currentIndex == 3 ? const Color(0xFFFF528F) : Colors.grey.shade400,
                      BlendMode.srcIn,
                    ),
                    child: Lottie.asset(
                      'assets/icons/loop-setting.json',
                      width: 24,
                      height: 24,
                      animate: true,
                      repeat: true,
                    ),
                  ),
                ),
                label: "Pengaturan",
              ),
            ],
          ),
        ),
      ),
    );
  }
}