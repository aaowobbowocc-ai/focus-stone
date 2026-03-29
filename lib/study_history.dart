import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudySession {
  final DateTime date;
  final int durationSeconds;
  final bool failed;
  final String name;

  const StudySession({
    required this.date,
    required this.durationSeconds,
    this.failed = false,
    this.name = '',
  });

  String toJson() => jsonEncode({
        'date': date.toIso8601String(),
        'duration': durationSeconds,
        'failed': failed,
        'name': name,
      });

  static StudySession fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return StudySession(
      date: DateTime.parse(map['date'] as String),
      durationSeconds: map['duration'] as int,
      failed: (map['failed'] as bool?) ?? false,
      name: (map['name'] as String?) ?? '',
    );
  }
}

String formatStudyDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}時${m}分';
  if (m > 0) return '${m}分${s}秒';
  return '${s}秒';
}

/// 計算目前連續讀書天數（今天或昨天有讀書才算連續）
int calculateStreak(List<StudySession> sessions) {
  if (sessions.isEmpty) return 0;
  final studyDays = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet();
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  // 從今天開始往回數，若今天沒有則從昨天開始
  DateTime check = studyDays.contains(todayDate)
      ? todayDate
      : todayDate.subtract(const Duration(days: 1));
  int streak = 0;
  while (studyDays.contains(check)) {
    streak++;
    check = check.subtract(const Duration(days: 1));
  }
  return streak;
}

/// 計算歷史最長連續天數
int calculateLongestStreak(List<StudySession> sessions) {
  if (sessions.isEmpty) return 0;
  final days = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet()
      .toList()
    ..sort();
  int longest = 1, current = 1;
  for (int i = 1; i < days.length; i++) {
    if (days[i].difference(days[i - 1]).inDays == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}

/// 回傳最近 [days] 天每天的讀書秒數，index 0 = 最舊，最後一個 = 今天
List<int> getDailySeconds(List<StudySession> sessions, int days) {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final result = List<int>.filled(days, 0);
  for (final s in sessions) {
    final d = DateTime(s.date.year, s.date.month, s.date.day);
    final diff = today.difference(d).inDays;
    if (diff >= 0 && diff < days) {
      result[days - 1 - diff] += s.durationSeconds;
    }
  }
  return result;
}

class StudyHistory {
  static const _key = 'study_sessions';

  static Future<List<StudySession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.reversed.map(StudySession.fromJson).toList();
  }

  static Future<void> save(StudySession session) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(session.toJson());
    await prefs.setStringList(_key, list);
  }

  /// [displayIndex] 是顯示清單的索引（最新=0），對應儲存清單的倒數位置
  static Future<void> updateName(int displayIndex, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final storageIndex = list.length - 1 - displayIndex;
    if (storageIndex < 0 || storageIndex >= list.length) return;
    final session = StudySession.fromJson(list[storageIndex]);
    list[storageIndex] = StudySession(
      date: session.date,
      durationSeconds: session.durationSeconds,
      failed: session.failed,
      name: newName,
    ).toJson();
    await prefs.setStringList(_key, list);
  }
}
