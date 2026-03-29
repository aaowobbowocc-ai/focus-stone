import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // ── 目前使用者 ──────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;

  /// 匿名登入（首次使用自動建立帳號）
  static Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
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

  static Future<void> updateRockName(String name) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).set({'rockName': name}, SetOptions(merge: true));
  }

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

  // ── 好友清單 ────────────────────────────────────────
  static Future<void> addFriend(String friendUid) async {
    final id = uid;
    if (id == null || friendUid == id) return;
    await _db.collection('users').doc(id).collection('friends').doc(friendUid).set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getFriends() async {
    final id = uid;
    if (id == null) return [];
    final snap = await _db.collection('users').doc(id).collection('friends').get();
    final friends = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final userSnap = await _db.collection('users').doc(doc.id).get();
      if (userSnap.exists) {
        friends.add({'uid': doc.id, ...userSnap.data()!});
      }
    }
    return friends;
  }

  static Future<void> removeFriend(String friendUid) async {
    final id = uid;
    if (id == null) return;
    await _db.collection('users').doc(id).collection('friends').doc(friendUid).delete();
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
