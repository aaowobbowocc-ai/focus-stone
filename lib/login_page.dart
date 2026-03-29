import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String? _error;

  Future<void> _loginAnonymous() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseService.signInAnonymously();
      _goHome();
    } catch (e) {
      setState(() { _loading = false; _error = '登入失敗，請稍後再試'; });
    }
  }

  Future<void> _loginGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseService.signInWithGoogle();
      _goHome();
    } catch (e) {
      setState(() { _loading = false; _error = 'Google 登入失敗，請稍後再試' });
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/stone.png', width: 110, height: 110, fit: BoxFit.contain),
                const SizedBox(height: 22),
                const Text(
                  '讀書石頭',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '你的讀書陪伴夥伴',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8B5E3C)),
                ),
                const SizedBox(height: 52),

                if (_loading)
                  const CircularProgressIndicator(color: Color(0xFF7B4F2E))
                else ...[
                  // Google 登入
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loginGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A2C0A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFAA8866)),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('G', style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17,
                            color: Color(0xFF4285F4),
                          )),
                          SizedBox(width: 10),
                          Text('使用 Google 帳號登入',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 匿名
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loginAnonymous,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5E3C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Color(0xFFCCAA88)),
                      ),
                      child: const Text('先匿名使用', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '匿名使用者可在好友頁面隨時綁定 Google 帳號',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFFAA8866)),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
