import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushService {
  static Future<void> requestPermission([BuildContext? context]) async {
    // 先用 Notification API 檢查目前權限狀態
    // ignore: avoid_web_libraries_in_flutter
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final status = settings.authorizationStatus;

      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        await messaging.getToken(
          vapidKey: 'BG6s5OYjENQIj_OlPtzXXcrH8FNHjvZhAJGaV4zA2Z60yK-fIldZTjFxIm4fy5GwPCjfhcew5b7dubil9_m8a5M',
        );
        if (context != null && context.mounted) {
          _showSnack(context, '🔔 推播通知已開啟！石頭會記得叫你讀書呢。');
        }
      } else if (status == AuthorizationStatus.denied) {
        if (context != null && context.mounted) {
          _showSnack(context, '通知權限被拒絕了。請到瀏覽器設定手動開啟。');
        }
      }
    } catch (e) {
      debugPrint('[FCM] Error: $e');
    }
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Color(0xFF4A2C0A))),
        backgroundColor: const Color(0xFFEDD9A3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
