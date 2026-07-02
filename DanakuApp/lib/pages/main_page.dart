import 'package:flutter/material.dart';
import 'home_page.dart';
import 'wallet_page.dart';
import 'report_page.dart';
import 'transaction_input_page.dart';
import 'setting_page.dart';
import 'pin_lock_page.dart';
import '../data/database_helper.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey();
  bool _showPinLock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPinLock());
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
        backgroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionInputPage(initialJenis: "masuk"),
            ),
          );
          _homeKey.currentState?.loadData();
        },
        child: const Icon(Icons.add, color: Colors.pink),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting"),
        ],
      ),
    );
  }
}