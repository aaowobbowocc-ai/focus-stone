import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  String _myCode = '';
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final code = await FirebaseService.getMyFriendCode();
    final friends = await FirebaseService.getFriends();
    if (mounted) {
      setState(() {
        _myCode = code ?? '';
        _friends = friends;
        _isAnonymous = FirebaseService.isAnonymous;
        _loading = false;
      });
    }
  }

  Future<void> _linkGoogle() async {
    setState(() => _loading = true);
    try {
      await FirebaseService.linkWithGoogle();
      _showSnack('已成功綁定 Google 帳號！資料已保留 🎉');
    } catch (e) {
      final msg = e.toString().contains('credential-already-in-use')
          ? '此 Google 帳號已被其他用戶使用'
          : '綁定失敗，請稍後再試';
      _showSnack(msg);
    }
    _load();
  }

  Future<void> _addFriend() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: const Text('加入好友', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('輸入好友的 6 位邀請碼',
                style: TextStyle(fontSize: 13, color: Color(0xFF8B5E3C))),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C0A), letterSpacing: 4),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFEDD9A3),
                counterText: '',
                hintText: 'XXXXXX',
                hintStyle: const TextStyle(color: Color(0xFFAA8866), letterSpacing: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B5E3C))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7B4F2E), width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Color(0xFFAA8866)))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().toUpperCase()),
            child: const Text('搜尋', style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (code == null || code.length != 6) return;
    if (code == _myCode) {
      _showSnack('不能加自己為好友 😅');
      return;
    }

    final user = await FirebaseService.findUserByCode(code);
    if (!mounted) return;
    if (user == null) {
      _showSnack('找不到此邀請碼，請確認後再試');
      return;
    }

    // 確認加入
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: const Text('確認加入好友？', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🪨 ', style: TextStyle(fontSize: 24)),
            Text(user['rockName'] ?? '無名石頭',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7B4F2E))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(color: Color(0xFFAA8866)))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('加入！', style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseService.addFriend(user['uid'] as String);
    _showSnack('已加入 ${user['rockName']} 為好友 🎉');
    _load();
  }

  Future<void> _viewFriendHistory(Map<String, dynamic> friend) async {
    final sessions = await FirebaseService.getFriendSessions(friend['uid'] as String);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5E6C8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FriendHistorySheet(
        friendName: friend['rockName'] ?? '無名石頭',
        sessions: sessions,
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF7B4F2E)));
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}時${m}分';
    return '${m}分鐘';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8),
      body: Stack(
        children: [
          // AppBar
          Positioned(
            top: 0, left: 0, right: 0,
            height: topPad + 56,
            child: Container(
              padding: EdgeInsets.only(top: topPad),
              decoration: const BoxDecoration(
                color: Color(0xFF7B4F2E),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text('好友石頭圈', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  IconButton(
                    onPressed: _addFriend,
                    icon: const Icon(Icons.person_add, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Positioned.fill(
            top: topPad + 56,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B4F2E)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 我的邀請碼卡片
                      _MyCodeCard(code: _myCode),
                      const SizedBox(height: 12),

                      // 匿名用戶：綁定 Google 提示
                      if (_isAnonymous)
                        GestureDetector(
                          onTap: _linkGoogle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDD9A3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFAA8866)),
                            ),
                            child: const Row(
                              children: [
                                Text('G', style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4285F4))),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('綁定 Google 帳號',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
                                      Text('換裝置也能保留所有紀錄與好友',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF8B5E3C))),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Color(0xFFAA8866), size: 20),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // 好友清單
                      if (_friends.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Text('🪨', style: TextStyle(fontSize: 48)),
                                SizedBox(height: 12),
                                Text('還沒有好友\n點右上角加入好友吧！',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 15, color: Color(0xFF8B5E3C), height: 1.6)),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        const Text('好友清單',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C))),
                        const SizedBox(height: 8),
                        ..._friends.map((f) => _FriendCard(
                          friend: f,
                          onTap: () => _viewFriendHistory(f),
                          onRemove: () async {
                            await FirebaseService.removeFriend(f['uid'] as String);
                            _load();
                          },
                          formatDuration: _formatDuration,
                        )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── 我的邀請碼卡片 ──────────────────────────────────────
class _MyCodeCard extends StatelessWidget {
  final String code;
  const _MyCodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF7B4F2E),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          const Text('我的邀請碼', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(code,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.bold, letterSpacing: 6)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('邀請碼已複製！'), backgroundColor: Color(0xFF7B4F2E)),
                  );
                },
                child: const Icon(Icons.copy, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('分享給好友，讓他們輸入此碼加入你', style: TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── 好友卡片 ────────────────────────────────────────────
class _FriendCard extends StatelessWidget {
  final Map<String, dynamic> friend;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final String Function(int) formatDuration;

  const _FriendCard({
    required this.friend,
    required this.onTap,
    required this.onRemove,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDD9A3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8B5E3C), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const Text('🪨', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend['rockName'] ?? '無名石頭',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
                  Text('點擊查看讀書紀錄',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFAA8866))),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: const Color(0xFFF5E6C8),
                    title: const Text('移除好友？', style: TextStyle(color: Color(0xFF4A2C0A))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消', style: TextStyle(color: Color(0xFFAA8866)))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('移除', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) onRemove();
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 18, color: Color(0xFFAA8866)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 好友讀書紀錄底部彈出 ────────────────────────────────
class _FriendHistorySheet extends StatelessWidget {
  final String friendName;
  final List<Map<String, dynamic>> sessions;

  const _FriendHistorySheet({required this.friendName, required this.sessions});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}時${m}分';
    if (m > 0) return '${m}分${s}秒';
    return '${s}秒';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.brown.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        Text('$friendName 的讀書紀錄',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          const Expanded(child: Center(child: Text('還沒有紀錄', style: TextStyle(color: Color(0xFF8B5E3C)))))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) {
                final s = sessions[i];
                final failed = s['failed'] as bool? ?? false;
                final name = s['name'] as String? ?? '';
                final secs = s['duration'] as int? ?? 0;
                final date = (s['date'] as dynamic).toDate() as DateTime;
                final dateStr = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: failed ? const Color(0xFFF5D5D5) : const Color(0xFFEDD9A3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: failed ? const Color(0xFFB03030) : const Color(0xFF8B5E3C)),
                  ),
                  child: Row(
                    children: [
                      Text(failed ? '💀' : '📖', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (name.isNotEmpty)
                              Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                  color: failed ? const Color(0xFFB03030) : const Color(0xFF4A2C0A))),
                            Text(dateStr, style: TextStyle(fontSize: 11,
                                color: failed ? const Color(0xFFB03030) : const Color(0xFF8B5E3C))),
                          ],
                        ),
                      ),
                      Text(_formatDuration(secs),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                              color: failed ? const Color(0xFFB03030) : const Color(0xFF4A2C0A))),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
