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
