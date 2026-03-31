import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  static Future<void> requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await messaging.getToken(
        // 填入 Firebase Console → 專案設定 → 雲端通訊 → 網頁推送憑證 (VAPID)
        vapidKey: 'BG6s5OYjENQIj_OlPtzXXcrH8FNHjvZhAJGaV4zA2Z60yK-fIldZTjFxIm4fy5GwPCjfhcew5b7dubil9_m8a5M',
      );
      print('[FCM] Token: $token');
    }
  }
}
