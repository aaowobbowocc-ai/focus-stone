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
