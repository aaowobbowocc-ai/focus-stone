import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'study_history.dart';

// ── 成就定義 ──────────────────────────────────────────────
class Achievement {
  final String id;
  final String icon;
  final String title;
  final String desc;

  const Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.desc,
  });
}

const List<Achievement> kAchievements = [
  Achievement(id: 'first_study',   icon: '🪨', title: '第一顆石頭',   desc: '完成第一次讀書'),
  Achievement(id: 'streak_3',      icon: '🔥', title: '三天打魚',     desc: '連續讀書 3 天'),
  Achievement(id: 'streak_7',      icon: '💫', title: '一週不散',     desc: '連續讀書 7 天'),
  Achievement(id: 'streak_30',     icon: '🌕', title: '月如一日',     desc: '連續讀書 30 天'),
  Achievement(id: 'total_1h',      icon: '⏰', title: '小時候',       desc: '累積讀書 1 小時'),
  Achievement(id: 'total_10h',     icon: '📚', title: '腦力全開',     desc: '累積讀書 10 小時'),
  Achievement(id: 'total_100h',    icon: '🏆', title: '學霸本色',     desc: '累積讀書 100 小時'),
  Achievement(id: 'night_owl',     icon: '🦉', title: '夜貓子',       desc: '凌晨 12 點後仍在讀書'),
  Achievement(id: 'early_bird',    icon: '🌅', title: '早起石頭',     desc: '早上 6 點前開始讀書'),
  Achievement(id: 'marathon',      icon: '🏃', title: '馬拉松',       desc: '單次讀書超過 2 小時'),
  Achievement(id: 'sessions_10',   icon: '✏️', title: '勤學不輟',     desc: '累積完成 10 次讀書'),
  Achievement(id: 'sessions_50',   icon: '🎓', title: '刻苦耐勞',     desc: '累積完成 50 次讀書'),
];

// ── 解鎖邏輯 ─────────────────────────────────────────────
Set<String> checkUnlocks(List<StudySession> sessions) {
  final unlocked = <String>{};
  if (sessions.isEmpty) return unlocked;

  final validSessions = sessions.where((s) => !s.failed).toList();
  final totalSecs = validSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  final streak = calculateStreak(sessions);
  final longestStreak = calculateLongestStreak(sessions);

  if (validSessions.isNotEmpty) unlocked.add('first_study');
  if (longestStreak >= 3)  unlocked.add('streak_3');
  if (longestStreak >= 7)  unlocked.add('streak_7');
  if (longestStreak >= 30) unlocked.add('streak_30');
  if (totalSecs >= 3600)   unlocked.add('total_1h');
  if (totalSecs >= 36000)  unlocked.add('total_10h');
  if (totalSecs >= 360000) unlocked.add('total_100h');
  if (validSessions.length >= 10) unlocked.add('sessions_10');
  if (validSessions.length >= 50) unlocked.add('sessions_50');

  for (final s in validSessions) {
    if (s.date.hour >= 0 && s.date.hour < 5) unlocked.add('night_owl');
    if (s.date.hour < 6) unlocked.add('early_bird');
    if (s.durationSeconds >= 7200) unlocked.add('marathon');
  }

  return unlocked;
}

// ── 頁面 ──────────────────────────────────────────────────
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  Set<String> _unlocked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await StudyHistory.load();
    final unlocked = checkUnlocks(sessions);
    // 持久化新解鎖（供首頁角標用）
    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getStringList('achievements') ?? [];
    final prevSet = prev.toSet();
    final newlyUnlocked = unlocked.difference(prevSet);
    if (newlyUnlocked.isNotEmpty) {
      await prefs.setStringList('achievements', unlocked.toList());
    }
    if (mounted) setState(() { _unlocked = unlocked; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B4F2E),
        foregroundColor: Colors.white,
        title: const Text('成就收藏架', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B4F2E)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDD9A3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B5E3C), width: 1.5),
                    ),
                    child: Text(
                      '已解鎖 ${_unlocked.length} / ${kAchievements.length}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7B4F2E)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: kAchievements.length,
                      itemBuilder: (_, i) {
                        final a = kAchievements[i];
                        final done = _unlocked.contains(a.id);
                        return _AchievementCard(achievement: a, unlocked: done);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _AchievementCard({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFFF5E6C8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(achievement.icon, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(achievement.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
                const SizedBox(height: 6),
                Text(achievement.desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8B5E3C))),
                const SizedBox(height: 10),
                Text(
                  unlocked ? '✅ 已解鎖' : '🔒 尚未解鎖',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? const Color(0xFF4CAF50) : const Color(0xFFAA8866),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: AnimatedOpacity(
        opacity: unlocked ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            color: unlocked ? const Color(0xFFEDD9A3) : const Color(0xFFD9CCBA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unlocked ? const Color(0xFF8B5E3C) : const Color(0xFFBBAA99),
              width: 1.5,
            ),
            boxShadow: unlocked
                ? [BoxShadow(color: Colors.brown.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(unlocked ? achievement.icon : '🔒', style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? const Color(0xFF4A2C0A) : const Color(0xFF8B7355),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
