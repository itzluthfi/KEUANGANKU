import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'pages/main_page.dart';
import 'pages/splash_page.dart';
import 'services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    tz.initializeTimeZones();
    await NotificationService.instance.init();
    try {
      await Firebase.initializeApp();
      NotificationService.instance.setupFcmListeners();
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }
  
  if (kIsWeb) {
    // Inisialisasi sqflite untuk Web (Chrome, Edge)
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    // Inisialisasi sqflite untuk Windows & Linux (Desktop)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const DanakuApp());
}

class DanakuApp extends StatelessWidget {
  const DanakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Danaku App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Hapus Center dan SizedBox width: 400 agar aplikasi memenuhi layar
      home: const SplashPage(),
    );
  }
}