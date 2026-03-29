import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'login_page.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final hasUser = FirebaseAuth.instance.currentUser != null;
  runApp(PetRockApp(showLogin: !hasUser));
}

class PetRockApp extends StatefulWidget {
  final bool showLogin;
  const PetRockApp({super.key, required this.showLogin});

  @override
  State<PetRockApp> createState() => _PetRockAppState();
}

class _PetRockAppState extends State<PetRockApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _updateReady = false;

  @override
  void initState() {
    super.initState();
    _registerSWCallback();
  }

  void _registerSWCallback() {
    try {
      js_util.setProperty(js.context, '_flutterSWUpdateCallback', js.allowInterop(() {
        if (mounted && !_updateReady) {
          setState(() => _updateReady = true);
          _showUpdateSnackBar();
        }
      }));
    } catch (_) {
      // 非 web 平台忽略
    }
  }

  void _showUpdateSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey.currentContext;
      if (ctx == null) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 30),
          backgroundColor: const Color(0xFF7B4F2E),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Text('🪨', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '小石進化了！點擊重新載入獲取新功能',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: '立即更新',
            textColor: const Color(0xFFEDD9A3),
            onPressed: () {
              try {
                js_util.callMethod(js.context, 'eval', ['window.location.reload(true)']);
              } catch (_) {}
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: '讀書石頭',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: widget.showLogin ? const LoginPage() : const HomePage(),
    );
  }
}
