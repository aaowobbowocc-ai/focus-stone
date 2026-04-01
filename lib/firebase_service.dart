import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── 目前使用者 ──────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;

  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// 匿名登入（首次使用自動建立帳號）
  static Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  /// Google 登入（Web）
  static Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    await _auth.signInWithPopup(provider);
  }

  /// 匿名帳號綁定 Google（保留所有資料）
  static Future<void> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return;
    final provider = GoogleAuthProvider();
    await user.linkWithPopup(provider);
  }

  // ── 用戶資料 ────────────────────────────────────────
  static Future<void> initUser({required String rockName}) async {
    final id = uid;
    if (id == null) return;
    final ref = _db.collection('users').doc(id);
    final snap = await ref.get();
    if (!snap.exists) {
      final code = _generateFriendCode();
      await ref.set({
        'rockName': rockName,
        'friendCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (rockName.isNotEmpty) {
      await ref.update({'rockName': rockName});
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final id = uid;
    if (id == null) return null;
    final snap = await _db.collection('users').doc(id).get();
    return snap.data();
  }

  static Future<void> _updateUserField(String field, dynamic value) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).set({field: value}, SetOptions(merge: true));
  }

  static Future<void> updateRockName(String name) => _updateUserField('rockName', name);
  static Future<void> updateAvatar(int avatarId) => _updateUserField('avatarId', avatarId);
  static Future<void> updateCoins(int coins) => _updateUserField('coins', coins);
  static Future<void> updateOwnedAvatars(List<int> owned) => _updateUserField('ownedAvatars', owned);

  // ── 好友碼 ──────────────────────────────────────────
  static String _generateFriendCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static Future<String?> getMyFriendCode() async {
    final id = uid;
    if (id == null) return null;
    final data = await getUserData();
    if (data == null) return null;
    if (data['friendCode'] != null) return data['friendCode'] as String;
    // 舊帳號沒有邀請碼，補產生一個
    final code = _generateFriendCode();
    await _db.collection('users').doc(id).set({'friendCode': code}, SetOptions(merge: true));
    return code;
  }

  /// 用好友碼搜尋用戶，回傳 {uid, rockName, friendCode} 或 null
  static Future<Map<String, dynamic>?> findUserByCode(String code) async {
    final snap = await _db
        .collection('users')
        .where('friendCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return {'uid': doc.id, ...doc.data()};
  }

  // ── 好友邀請 ────────────────────────────────────────
  /// 發送好友邀請（寫入對方的 friendRequests 子集合）
  static Future<void> sendFriendRequest(String toUid) async {
    final id = uid;
    if (id == null || toUid == id) return;
    final prefs = await SharedPreferences.getInstance();
    await _db.collection('users').doc(toUid).collection('friendRequests').doc(id).set({
      'fromUid': id,
      'rockName': prefs.getString('rock_name') ?? '',
      'avatarId': prefs.getInt('avatar_id') ?? 0,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  /// 取得我的待處理邀請
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final id = uid;
    if (id == null) return [];
    final snap = await _db.collection('users').doc(id).collection('friendRequests').get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }

  /// 接受好友邀請：雙方互加
  static Future<void> acceptFriendRequest(String fromUid) async {
    final id = uid;
    if (id == null) return;
    final now = FieldValue.serverTimestamp();
    await Future.wait([
      _db.collection('users').doc(id).collection('friends').doc(fromUid).set({'addedAt': now}),
      _db.collection('users').doc(fromUid).collection('friends').doc(id).set({'addedAt': now}),
    ]);
    await _db.collection('users').doc(id).collection('friendRequests').doc(fromUid).delete();
  }

  /// 拒絕好友邀請
  static Future<void> rejectFriendRequest(String fromUid) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).collection('friendRequests').doc(fromUid).delete();
  }

  // ── 好友清單 ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getFriends() async {
    final id = uid;
    if (id == null) return [];
    final snap = await _db.collection('users').doc(id).collection('friends').get();
    if (snap.docs.isEmpty) return [];
    // 平行讀取所有好友資料
    final userSnaps = await Future.wait(
      snap.docs.map((d) => _db.collection('users').doc(d.id).get()),
    );
    return [
      for (int i = 0; i < snap.docs.length; i++)
        if (userSnaps[i].exists)
          {'uid': snap.docs[i].id, ...userSnaps[i].data()!},
    ];
  }

  /// 刪除好友：雙方同時移除
  static Future<void> removeFriend(String friendUid) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).collection('friends').doc(friendUid).delete();
    await _db.collection('users').doc(friendUid).collection('friends').doc(id).delete();
  }

  // ── 今日讀書比較 ─────────────────────────────────────────
  static Future<int> _getTodaySeconds(String userId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();
      return snap.docs.fold<int>(0, (sum, d) => sum + ((d.data()['duration'] as int?) ?? 0));
    } catch (_) {
      return 0;
    }
  }

  /// 回傳自己 + 好友今日讀書秒數，含 uid / rockName / avatarId / todaySeconds / isSelf
  static Future<List<Map<String, dynamic>>> getTodayComparisonData() async {
    final id = uid;
    if (id == null) return [];

    final selfDataFuture = getUserData();
    final friendsFuture = getFriends();
    final selfData = await selfDataFuture;
    final friends = await friendsFuture;

    final allEntries = <Map<String, dynamic>>[
      {'uid': id, 'rockName': selfData?['rockName'] ?? '我', 'avatarId': (selfData?['avatarId'] as int?) ?? 0, 'isSelf': true},
      for (final f in friends)
        {'uid': f['uid'], 'rockName': f['rockName'] ?? '無名石頭', 'avatarId': (f['avatarId'] as int?) ?? 0, 'isSelf': false},
    ];

    final todayList = await Future.wait(
      allEntries.map((e) => _getTodaySeconds(e['uid'] as String)),
    );

    return [
      for (int i = 0; i < allEntries.length; i++)
        {...allEntries[i], 'todaySeconds': todayList[i]},
    ]..sort((a, b) => (b['todaySeconds'] as int).compareTo(a['todaySeconds'] as int));
  }

  // ── 好友排行榜 ──────────────────────────────────────────
  static Future<int> _getWeeklySeconds(String userId, DateTime weekStart) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();
      return snap.docs.fold<int>(0, (sum, d) => sum + ((d.data()['duration'] as int?) ?? 0));
    } catch (_) {
      return 0;
    }
  }

  /// 回傳自己 + 好友本週讀書秒數排行，含 uid / rockName / avatarId / weeklySeconds / isSelf
  static Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    final id = uid;
    if (id == null) return [];
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final selfDataFuture = getUserData();
    final friendsFuture = getFriends();
    final selfData = await selfDataFuture;
    final friends = await friendsFuture;

    final allEntries = <Map<String, dynamic>>[
      {'uid': id, 'rockName': selfData?['rockName'] ?? '', 'avatarId': (selfData?['avatarId'] as int?) ?? 0, 'isSelf': true},
      for (final f in friends)
        {'uid': f['uid'], 'rockName': f['rockName'] ?? '', 'avatarId': (f['avatarId'] as int?) ?? 0, 'isSelf': false},
    ];

    final weeklyList = await Future.wait(
      allEntries.map((e) => _getWeeklySeconds(e['uid'] as String, weekStart)),
    );

    return [
      for (int i = 0; i < allEntries.length; i++)
        {...allEntries[i], 'weeklySeconds': weeklyList[i]},
    ]..sort((a, b) => (b['weeklySeconds'] as int).compareTo(a['weeklySeconds'] as int));
  }

  // ── 讀書紀錄同步 ────────────────────────────────────
  static Future<void> syncSession({
    required DateTime date,
    required int durationSeconds,
    required bool failed,
    required String name,
  }) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).collection('sessions').add({
      'date': Timestamp.fromDate(date),
      'duration': durationSeconds,
      'failed': failed,
      'name': name,
    });
  }

  /// 推薦好友：取得尚未加入的其他用戶（最多 5 位）
  static Future<List<Map<String, dynamic>>> getRecommendedUsers() async {
    final id = uid;
    if (id == null) return [];
    // 取得已是好友的 UID 集合
    final friends = await getFriends();
    final friendUids = friends.map((f) => f['uid'] as String).toSet();
    // 取得待確認邀請的 UID 集合
    final requests = await getPendingRequests();
    final requestUids = requests.map((r) => r['uid'] as String).toSet();
    // 撈用戶（不依賴 createdAt，避免舊帳號被過濾掉）
    final snap = await _db
        .collection('users')
        .limit(30)
        .get();
    final result = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      if (doc.id == id) continue;
      if (friendUids.contains(doc.id)) continue;
      if (requestUids.contains(doc.id)) continue;
      final data = doc.data();
      result.add({
        'uid': doc.id,
        'rockName': data['rockName'] ?? '無名石頭',
        'avatarId': data['avatarId'] ?? 0,
        'friendCode': data['friendCode'] ?? '',
      });
      if (result.length >= 5) break;
    }
    return result;
  }

  // ── 好友鼓勵 ────────────────────────────────────────────
  static const List<String> encouragementMessages = [
    '加油！你一定做得到！🔥',
    '今天也努力讀書了，棒棒！📚',
    '石頭都在看著你，繼續衝！🪨',
    '一起加油！我們都可以的！✊',
    '辛苦了！休息一下再繼續！☕',
    '你的努力石頭都記得！🌸',
    '今天讀了多少？超厲害！⭐',
    '不要放棄！距離目標更近了！🏆',
  ];

  /// 送鼓勵給好友
  static Future<void> sendEncouragement(String toUid, String message) async {
    final id = uid;
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    final rockName = prefs.getString('rock_name') ?? '無名石頭';
    final avatarId = prefs.getInt('avatar_id') ?? 0;
    await _db.collection('users').doc(toUid).collection('encouragements').add({
      'fromUid': id,
      'fromName': rockName,
      'fromAvatarId': avatarId,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// 取得我收到的鼓勵（最新 20 則）
  static Future<List<Map<String, dynamic>>> getEncouragements() async {
    final id = uid;
    if (id == null) return [];
    final snap = await _db
        .collection('users')
        .doc(id)
        .collection('encouragements')
        .orderBy('sentAt', descending: true)
        .limit(20)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// 取得未讀鼓勵數量
  static Future<int> getUnreadEncouragementCount() async {
    final id = uid;
    if (id == null) return 0;
    final snap = await _db
        .collection('users')
        .doc(id)
        .collection('encouragements')
        .where('read', isEqualTo: false)
        .get();
    return snap.docs.length;
  }

  /// 標記全部鼓勵已讀
  static Future<void> markEncouragementsRead() async {
    final id = uid;
    if (id == null) return;
    final snap = await _db
        .collection('users')
        .doc(id)
        .collection('encouragements')
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// 取得某用戶最近 N 筆紀錄
  static Future<List<Map<String, dynamic>>> getFriendSessions(
      String friendUid, {int limit = 20}) async {
    final snap = await _db
        .collection('users')
        .doc(friendUid)
        .collection('sessions')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
