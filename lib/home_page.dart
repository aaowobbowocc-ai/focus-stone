import 'dart:async';
import 'dart:math';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quotes.dart';
import 'messages.dart';
import 'study_history.dart';
import 'history_page.dart';
import 'friends_page.dart';
import 'shop_page.dart';
import 'changelog_page.dart';
import 'firebase_service.dart';
import 'stone_avatar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── 動畫 ──
  late AnimationController _bubbleController;
  late Animation<double> _bubbleFade;
  late Animation<Offset> _bubbleSlide;
  late AnimationController _rockController;
  late Animation<double> _rockScale;

  // ── 讀書動畫 ──
  late AnimationController _swayController;
  late Animation<double> _swayAnim;
  late AnimationController _jumpController;
  late Animation<double> _jumpAnim;
  Timer? _graceTimer;

  // ── 台詞 ──
  String _currentQuote = '點我看看會發生什麼事。';
  final Random _random = Random();

  // ── 石頭名字 & 頭像 & 連續天數 & 金幣 ──
  String _rockName = '';
  int _avatarId = 0;
  int _streak = 0;
  int _coins = 0;
  List<int> _ownedAvatars = List.generate(StoneAvatar.count, (i) => i);

  // ── 讀書計時 ──
  bool _isStudying = false;
  int _studySeconds = 0;
  String _sessionName = '';
  int _goalMinutes = 0;
  bool _goalReached = false;  // 本次是否已達成目標
  Timer? _studyTimer;
  Timer? _bubbleTimer;
  Timer? _midStudyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bubbleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _bubbleFade =
        CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut);
    _bubbleSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut));

    _rockController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _rockScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.07), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _rockController, curve: Curves.easeInOut));

    _swayController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _swayAnim = Tween<double>(begin: -0.04, end: 0.04).animate(
        CurvedAnimation(parent: _swayController, curve: Curves.easeInOut));

    _jumpController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _jumpAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -38), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -38, end: 6), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 25),
    ]).animate(CurvedAnimation(parent: _jumpController, curve: Curves.easeOut));

    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studyTimer?.cancel();
    _bubbleTimer?.cancel();
    _graceTimer?.cancel();
    _midStudyTimer?.cancel();
    _bubbleController.dispose();
    _rockController.dispose();
    _swayController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt('last_opened');
    await prefs.setInt('last_opened', DateTime.now().millisecondsSinceEpoch);
    final savedName = prefs.getString('rock_name') ?? '';
    final savedAvatar = prefs.getInt('avatar_id') ?? 0;
    final savedCoins = prefs.getInt('total_coins') ?? 0;
    final ownedStr = prefs.getStringList('owned_avatars');
    final savedOwned = ownedStr != null
        ? ownedStr.map(int.parse).toList()
        : List<int>.generate(StoneAvatar.count, (i) => i);
    if (!mounted) return;

    setState(() {
      _rockName = savedName;
      _avatarId = savedAvatar;
      _coins = savedCoins;
      _ownedAvatars = savedOwned;
    });

    // 計算連續讀書天數
    final allSessions = await StudyHistory.load();
    if (mounted) setState(() => _streak = calculateStreak(allSessions));

    // 初始化雲端用戶資料
    await FirebaseService.initUser(rockName: _rockName);

    // 從 Firestore 同步金幣與已購頭像（雲端值優先）
    final userData = await FirebaseService.getUserData();
    final cloudCoins = (userData?['coins'] as int?) ?? 0;
    final cloudOwnedRaw = userData?['ownedAvatars'] as List<dynamic>?;
    final cloudOwned = cloudOwnedRaw?.map((e) => e as int).toList();
    final prefs2 = await SharedPreferences.getInstance();
    if (cloudCoins > savedCoins) {
      await prefs2.setInt('total_coins', cloudCoins);
      if (mounted) setState(() => _coins = cloudCoins);
    }
    if (cloudOwned != null && cloudOwned.length > savedOwned.length) {
      await prefs2.setStringList('owned_avatars', cloudOwned.map((e) => e.toString()).toList());
      if (mounted) setState(() => _ownedAvatars = cloudOwned);
    }

    final now = DateTime.now();
    final lateNight = now.hour >= 0 && now.hour < 5;
    final longAbsence = lastMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)).inHours > 24;

    setState(() => _currentQuote = getOpeningQuote(
          longAbsence: longAbsence,
          lateNight: lateNight,
          hour: now.hour,
        ));
    _showBubble();

    // 偵測 iOS PWA 版本更新：若剛剛 reload 過，顯示右上角通知
    final flag = html.window.localStorage['focus_stone_just_updated'];
    if (flag == '1') {
      html.window.localStorage.remove('focus_stone_just_updated');
      WidgetsBinding.instance.addPostFrameCallback((_) => _showUpdateBadge());
    }
  }

  void _showUpdateBadge() {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => ChangelogPage.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B4F2E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Text('✨ 小石頭已悄悄進化，點我查看', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  // 從商店/其他頁面返回時，只更新金幣和已擁有造型，不重新問名字
  Future<void> _refreshShopData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCoins = prefs.getInt('total_coins') ?? 0;
    final ownedStr = prefs.getStringList('owned_avatars');
    final savedOwned = ownedStr != null
        ? ownedStr.map(int.parse).toList()
        : List<int>.generate(StoneAvatar.count, (i) => i);
    if (!mounted) return;
    setState(() {
      _coins = savedCoins;
      _ownedAvatars = savedOwned;
    });
  }

  Future<void> _renameRock({bool isFirstTime = false}) async {
    final ctrl = TextEditingController(text: _rockName);
    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: Text(
          isFirstTime ? '幫你的石頭取個名字吧 🪨' : '改個名字？',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A)),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 12,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFEDD9A3),
            counterStyle: const TextStyle(color: Color(0xFFAA8866)),
            hintText: '例：小石、阿岩、Rocky...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAA8866)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B5E3C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7B4F2E), width: 2),
            ),
          ),
          style: const TextStyle(color: Color(0xFF4A2C0A)),
        ),
        actions: [
          if (!isFirstTime)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Color(0xFFAA8866))),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('確定', style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rock_name', newName);
    if (mounted) setState(() => _rockName = newName);
    await FirebaseService.updateRockName(newName);
  }

  Future<void> _pickAvatar() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: const Text('選擇頭像', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        content: SizedBox(
          width: 280,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: _ownedAvatars.map((i) {
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StoneAvatar(id: i, size: 64, selected: _avatarId == i),
                    const SizedBox(height: 4),
                    Text(StoneAvatar.allLabels[i],
                        style: TextStyle(
                          fontSize: 11,
                          color: _avatarId == i ? const Color(0xFF7B4F2E) : const Color(0xFF8B5E3C),
                          fontWeight: _avatarId == i ? FontWeight.bold : FontWeight.normal,
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);   
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()))
                  .then((_) => _refreshShopData());
            },
            child: const Text('前往商店 🛒', style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Color(0xFFAA8866)))),
        ],
      ),
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('avatar_id', picked);
    if (mounted) setState(() => _avatarId = picked);
    await FirebaseService.updateAvatar(picked);
  }

  Future<int> _earnCoins(int studySeconds) async {
    final earned = studySeconds ~/ 60;
    if (earned <= 0) return 0;
    final prefs = await SharedPreferences.getInstance();
    final newTotal = (_coins + earned);
    await prefs.setInt('total_coins', newTotal);
    if (mounted) setState(() => _coins = newTotal);
    FirebaseService.updateCoins(newTotal);
    return earned;
  }

  void _scheduleMidStudyMessage() {
    _midStudyTimer?.cancel();
    // 5 ~ 8 分鐘後顯示一次碎碎念
    _midStudyTimer =
        Timer(Duration(seconds: 300 + _random.nextInt(180)), () {
      if (!_isStudying || !mounted) return;
      setState(() => _currentQuote = getStudyRandomQuote());
      _showBubble();
      _scheduleMidStudyMessage();
    });
  }

  void _startReadingAnimations() {
    _swayController.repeat(reverse: true);
    _scheduleMidStudyMessage();
  }

  void _stopReadingAnimations() {
    _swayController.stop();
    _swayController.reset();
    _midStudyTimer?.cancel();
  }

  void _showBubble({bool autoFade = true}) {
    _bubbleController.forward(from: 0);
    _bubbleTimer?.cancel();
    if (autoFade) {
      _bubbleTimer = Timer(const Duration(seconds: 5), () {
        _bubbleController.reverse();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isStudying) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _graceTimer ??= Timer(const Duration(minutes: 90), () {
        if (_isStudying && mounted) _failStudy();
      });
    }
    if (state == AppLifecycleState.resumed) {
      if (_graceTimer != null && mounted) {
        setState(() => _currentQuote = getPenaltyQuote());
        _showBubble();
      }
      _graceTimer?.cancel();
      _graceTimer = null;
    }
  }

  void _onRockTap() {
    if (_isStudying) {
      setState(() => _currentQuote = getStudyRandomQuote());
      _showBubble();
      return;
    }
    final cat = categories[_random.nextInt(categories.length)];
    final quote = quotes[cat]![_random.nextInt(quotes[cat]!.length)];
    setState(() => _currentQuote = quote);
    _showBubble();
    _rockController.forward(from: 0);
    _jumpController.forward(from: 0);
  }

  Future<void> _startStudy() async {
    final nameCtrl = TextEditingController();
    final goalCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final fieldDeco = InputDecoration(
          filled: true,
          fillColor: const Color(0xFFEDD9A3),
          counterStyle: const TextStyle(color: Color(0xFFAA8866)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B5E3C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7B4F2E), width: 2),
          ),
        );
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFF5E6C8),
          title: const Text('準備讀書 📚',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C0A))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('這次讀什麼？',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B5E3C),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                maxLength: 20,
                decoration: fieldDeco.copyWith(
                    hintText: '例：解剖學第三章（可留空）',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFFAA8866))),
                style: const TextStyle(color: Color(0xFF4A2C0A)),
              ),
              const SizedBox(height: 4),
              const Text('目標時間',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8B5E3C),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: goalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: fieldDeco.copyWith(
                          hintText: '0',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: Color(0xFFAA8866))),
                      style: const TextStyle(color: Color(0xFF4A2C0A)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('分鐘',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B5E3C),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消',
                  style: TextStyle(color: Color(0xFFAA8866))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('開始！',
                  style: TextStyle(
                      color: Color(0xFF7B4F2E),
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final name = nameCtrl.text.trim();
    final goal = int.tryParse(goalCtrl.text.trim()) ?? 0;

    setState(() {
      _isStudying = true;
      _studySeconds = 0;
      _sessionName = name;
      _goalMinutes = goal > 0 ? goal : 0;
      _goalReached = false;
      _currentQuote = getStudyStartQuote(name);
    });
    _showBubble(autoFade: false);
    _startReadingAnimations();
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _studySeconds++);
      if (_goalMinutes > 0 &&
          !_goalReached &&
          _studySeconds == _goalMinutes * 60) {
        _onGoalReached();
      }
    });
  }

  void _onGoalReached() {
    setState(() {
      _goalReached = true;
      _currentQuote = getGoalReachedQuote(_goalMinutes);
    });
    _showBubble(autoFade: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: const Text('🏆 目標達成！',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/flower.png', height: 80),
            const SizedBox(height: 12),
            Text(
              '已讀 $_goalMinutes 分鐘',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B4F2E)),
            ),
            const SizedBox(height: 6),
            const Text('要繼續讀，還是先休息？',
                style: TextStyle(color: Color(0xFF8B5E3C), fontSize: 14)),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _stopStudy();
                },
                child: const Text('結束讀書',
                    style: TextStyle(color: Color(0xFFAA8866))),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _goalMinutes = 0; // 不再觸發目標提示
                    _currentQuote = '繼續加油！突觸正在瘋狂連結中！';
                  });
                  _showBubble(autoFade: false);
                },
                child: const Text('繼續讀書 💪',
                    style: TextStyle(
                        color: Color(0xFF7B4F2E),
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _stopStudy() async {
    _studyTimer?.cancel();
    _stopReadingAnimations();
    final secs = _studySeconds;
    final goalNotReached = _goalMinutes > 0 && !_goalReached && secs < _goalMinutes * 60;
    final now = DateTime.now();
    StudyHistory.save(StudySession(date: now, durationSeconds: secs, name: _sessionName));
    FirebaseService.syncSession(date: now, durationSeconds: secs, failed: false, name: _sessionName);
    final earned = await _earnCoins(secs);
    final endQuote = getStudyEndQuote(seconds: secs, goalNotReached: goalNotReached);
    if (!mounted) return;
    setState(() {
      _isStudying = false;
      _currentQuote = endQuote;
    });
    _showBubble();

    final m = secs ~/ 60;
    final s = secs % 60;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            goalNotReached ? '😅 沒撐到！' : '📚 讀書結束！',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B4F2E)),
            ),
            Text(
              goalNotReached ? '目標 $_goalMinutes 分鐘未達成' : '讀書時長',
              style: const TextStyle(color: Colors.grey),
            ),
            if (earned > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Text('🪙 獲得 $earned 金幣！',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFFE65100),
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: goalNotReached ? Colors.orange.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: goalNotReached
                        ? Colors.orange.shade200
                        : Colors.blue.shade200),
              ),
              child: Text(
                goalNotReached
                    ? '⚡ 下次一定要撐到終點！'
                    : '✅ 辛苦了，非常棒！',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: goalNotReached
                        ? Colors.orange.shade800
                        : Colors.blue.shade700,
                    fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(goalNotReached ? '知道了...' : '太好了！',
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _failStudy() async {
    _studyTimer?.cancel();
    _stopReadingAnimations();
    final secs = _studySeconds;
    final now = DateTime.now();
    StudyHistory.save(StudySession(date: now, durationSeconds: secs, failed: true, name: _sessionName));
    FirebaseService.syncSession(date: now, durationSeconds: secs, failed: true, name: _sessionName);
    await _earnCoins(secs);
    if (!mounted) return;
    setState(() {
      _isStudying = false;
      _currentQuote = getPenaltyQuote();
    });
    _showBubble();

    final m = secs ~/ 60;
    final s = secs % 60;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('💀 讀書失敗！', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B4F2E)),
            ),
            const Text('撐到這裡就跑了', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                '❌ 中途離開，直接失敗！\n下次要更專心哦！',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了...', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String get _timerDisplay {
    final m = _studySeconds ~/ 60;
    final s = _studySeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // 背景圖原始尺寸 512×896，BoxFit.contain 置中
  static const double _bgW = 512, _bgH = 896;
  static double _imgScale(Size s) =>
      (s.width / _bgW) < (s.height / _bgH) ? s.width / _bgW : s.height / _bgH;
  static double _imgLeft(Size s) => (s.width - _bgW * _imgScale(s)) / 2;
  static double _imgTop(Size s) => (s.height - _bgH * _imgScale(s)) / 2;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    // 石頭坐在地毯上（背景圖地毯約在 h*0.80）
    final rockD = (size.width * 0.42).clamp(120.0, 170.0);
    final rockR = rockD / 2;
    final rockCX = size.width * 0.60; // 地毯右側
    final rockCY = size.height * 0.80 - rockR * 0.2; // 地毯下方

    // 氣泡：底部（含尾巴 16px）緊接石頭頂部上方 12px
    final bubbleBottomY = rockCY - rockR + 22;
    final bubbleMaxH = (bubbleBottomY - topPad - 54).clamp(80.0, 200.0);
    final bubbleTopY = bubbleBottomY - bubbleMaxH;

    return Scaffold(
      body: Stack(
        children: [
          // ── 背景圖 ──
          Positioned.fill(
            child: Container(
              color: const Color(0xFF7A3B1E),
              child: Image.asset(
                'assets/background.jpg',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),

          // ── 石頭（讀書中顯示抱書版） ──
          Positioned(
            left: rockCX - rockR,
            top: rockCY - rockR - (_isStudying ? 20 : 0),
            width: rockD,
            height: _isStudying ? rockD * 1.2 + 20 : rockD,
            child: GestureDetector(
              onTap: _onRockTap,
              child: _isStudying
                  ? AnimatedBuilder(
                      animation: _swayController,
                      builder: (ctx, child) => Transform.rotate(
                        angle: _swayAnim.value,
                        child: child,
                      ),
                      child: Image.asset(
                          _goalReached ? 'assets/flower.png' : 'assets/read.png',
                          width: rockD, height: rockD * 1.2, fit: BoxFit.contain),
                    )
                  : AnimatedBuilder(
                      animation: _jumpController,
                      builder: (ctx, child) => Transform.translate(
                        offset: Offset(0, _jumpAnim.value),
                        child: ScaleTransition(scale: _rockScale, child: child),
                      ),
                      child: Image.asset('assets/stone.png',
                          width: rockD, height: rockD, fit: BoxFit.contain),
                    ),
            ),
          ),

          // ── 牛皮紙氣泡（在石頭正上方） ──
          Positioned(
            left: (rockCX - 150).clamp(12.0, size.width - 312),
            width: 300,
            bottom: size.height - bubbleBottomY,
            child: FadeTransition(
              opacity: _bubbleFade,
              child: SlideTransition(
                position: _bubbleSlide,
                child: _KraftBubble(text: _currentQuote),
              ),
            ),
          ),

          // ── 左上角：頭像 + 石頭名 + 日曆/好友按鈕 ──
          Positioned(
            top: _imgTop(size) + 14,
            left: _imgLeft(size) + 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 頭像 + 名字橫排
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: StoneAvatar(id: _avatarId, size: 52, selected: true),
                        ),
                        if (_streak > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('🔥 $_streak天',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _renameRock(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDD9A3).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8B5E3C), width: 1.5),
                        ),
                        child: Text(
                          _rockName.isEmpty ? '我的小石頭' : _rockName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A2C0A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _TopButton(
                      icon: Icons.calendar_month,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
                    ),
                    const SizedBox(width: 8),
                    _TopButton(
                      icon: Icons.people,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage())),
                    ),
                    const SizedBox(width: 8),
                    _TopButton(
                      icon: Icons.new_releases_outlined,
                      onTap: () => ChangelogPage.show(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 右上角：金幣 + 商店 ──
          Positioned(
            top: _imgTop(size) + 14,
            right: _imgLeft(size) + 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 金幣
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDD9A3).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4A056), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text('$_coins',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7B4F2E))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 商店按鈕
                _TopButton(
                  icon: Icons.storefront,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()))
                      .then((_) => _refreshShopData()),
                ),
              ],
            ),
          ),

          // ── 底部讀書區 ──
          Positioned(
            bottom: botPad + 20,
            left: 24,
            right: 24,
            child: _isStudying
                ? _StudyActiveBar(timerDisplay: _timerDisplay, onStop: _stopStudy)
                : _StudyStartButton(onStart: _startStudy),
          ),

        ],
      ),
    );
  }
}

// ────────────────────────────────────────
// 頂部圓角按鈕
// ────────────────────────────────────────
class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFEDD9A3).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5E3C), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF7B4F2E), size: 30),
      ),
    );
  }
}

// ────────────────────────────────────────
// 牛皮紙圓角氣泡
// ────────────────────────────────────────
class _KraftBubble extends StatelessWidget {
  final String text;
  const _KraftBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEDD9A3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8B5E3C), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4A2C0A),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(18, 10),
          painter: _KraftTailPainter(),
        ),
      ],
    );
  }
}

class _KraftTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFEDD9A3);
    final border = Paint()
      ..color = const Color(0xFF8B5E3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawLine(Offset(0, 0), Offset(size.width / 2, size.height), border);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width / 2, size.height), border);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ────────────────────────────────────────
// 底部讀書按鈕
// ────────────────────────────────────────
class _StudyStartButton extends StatelessWidget {
  final VoidCallback onStart;
  const _StudyStartButton({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF7B4F2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.brown.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📚', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('開始讀書',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _StudyActiveBar extends StatelessWidget {
  final String timerDisplay;
  final VoidCallback onStop;
  const _StudyActiveBar({required this.timerDisplay, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5D3720),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.brown.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Text('📖', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              timerDisplay,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          GestureDetector(
            onTap: onStop,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('結束',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
