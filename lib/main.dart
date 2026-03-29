import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final hasUser = FirebaseAuth.instance.currentUser != null;
  runApp(PetRockApp(showLogin: !hasUser));
}

class PetRockApp extends StatelessWidget {
  final bool showLogin;
  const PetRockApp({super.key, required this.showLogin});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '讀書石頭',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: showLogin ? const LoginPage() : const HomePage(),
    );
  }
}
