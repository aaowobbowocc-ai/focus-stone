// ai_backend_service.dart — 呼叫 FocusStone AI 後端
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIBackendService {
  // 本機開發用 localhost，上線後換成部署的 URL
  static const String _base = 'http://localhost:8000';

  /// 根據讀書時數 & streak 取得激勵語句
  static Future<String?> getMotivation({
    required String rockName,
    required int studySeconds,
    required int streak,
    required int totalMinutes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/ai/motivate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rock_name': rockName,
          'study_seconds': studySeconds,
          'streak': streak,
          'total_minutes': totalMinutes,
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['message'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// 根據週數據取得個人化讀書建議
  static Future<String?> getAdvice({
    required String rockName,
    required double weeklyHours,
    required int streak,
    required int longestStreak,
    required double avgSessionMinutes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/ai/advice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rock_name': rockName,
          'weekly_hours': weeklyHours,
          'streak': streak,
          'longest_streak': longestStreak,
          'avg_session_minutes': avgSessionMinutes,
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['advice'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// 取得 AI 生成圖片 URL（Pollinations.ai，免費）
  static String getImageUrl(String prompt, {int width = 512, int height = 512}) {
    final encoded = Uri.encodeComponent(prompt);
    final seed = prompt.hashCode.abs() % 99999;
    return 'https://image.pollinations.ai/prompt/$encoded'
        '?width=$width&height=$height&seed=$seed&nologo=true';
  }
}
