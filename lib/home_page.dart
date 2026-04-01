import 'dart:async';
import 'dart:math';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'push_service.dart';
import 'help_page.dart';
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
import 'achievements_page.dart';

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
  // ── 台詞 ──
  String _currentQuote = '點我看看會發生什麼事。';
  final Random _random = Random();

  // ── 石頭名字 & 頭像 & 連續天數 & 金幣 ──
  String _rockName = '';
  int _avatarId = 0;
  int _streak = 0;
  int _coins = 0;
  List<int> _ownedAvatars = List.generate(StoneAvatar.count, (i) => i);

  // ── 選單 ──
  bool _menuOpen = false;

  // ── 讀書計時 ──
  bool _isStudying = false;
  int _studySeconds = 0;
  DateTime? _studyStartTime;
  String _sessionName = '';
  int _goalMinutes = 0;
  bool _goalReached = false;  // 本次是否已達成目標
  Timer? _studyTimer;
  Timer? _bubbleTimer;
  Timer? _midStudyTimer;

  // ── 明信片 ──
  final GlobalKey _postcardKey = GlobalKey();

  // ── 番茄鐘 ──
  bool _pomodoroMode = false;
  bool _inPomodoroBreak = false;
  int _pomodoroRound = 0;
  int _breakSecondsLeft = 300;
  Timer? _breakTimer;

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
    _midStudyTimer?.cancel();
    _breakTimer?.cancel();
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
          isFirstTime ? '石頭想要個名字' : '改個名字？',
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
        title: const Text('選一個喜歡的吧', textAlign: TextAlign.center,
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
    if (state == AppLifecycleState.resumed && _studyStartTime != null) {
      // 用真實時間差更新秒數，修正背景節流造成的誤差
      final elapsed = DateTime.now().difference(_studyStartTime!).inSeconds;
      if (mounted) setState(() => _studySeconds = elapsed);
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

    bool pomodoroEnabled = false;
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
        return StatefulBuilder(builder: (ctx, setSB) => AlertDialog(
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
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: pomodoroEnabled
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                secondChild: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF8C00)),
                  ),
                  child: const Row(
                    children: [
                      Text('🍅', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('25 分讀書 + 5 分休息',
                          style: TextStyle(fontSize: 13, color: Color(0xFF4A2C0A), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setSB(() => pomodoroEnabled = !pomodoroEnabled),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: pomodoroEnabled
                        ? const Color(0xFF7B4F2E).withOpacity(0.1)
                        : const Color(0xFFEDD9A3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pomodoroEnabled
                          ? const Color(0xFF7B4F2E)
                          : const Color(0xFF8B5E3C),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🍅', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('開啟番茄鐘模式',
                            style: TextStyle(fontSize: 13, color: Color(0xFF4A2C0A))),
                      ),
                      Icon(
                        pomodoroEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                        color: const Color(0xFF7B4F2E),
                        size: 20,
                      ),
                    ],
                  ),
                ),
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
        ));
      },
    );
    if (confirmed != true) return;

    final name = nameCtrl.text.trim();
    final goal = pomodoroEnabled ? 25 : (int.tryParse(goalCtrl.text.trim()) ?? 0);

    _studyStartTime = DateTime.now();
    setState(() {
      _isStudying = true;
      _studySeconds = 0;
      _sessionName = name;
      _goalMinutes = goal > 0 ? goal : 0;
      _goalReached = false;
      _pomodoroMode = pomodoroEnabled;
      _inPomodoroBreak = false;
      _pomodoroRound = pomodoroEnabled ? 1 : 0;
      _currentQuote = pomodoroEnabled
          ? '🍅 番茄鐘第一輪開始！專心 25 分鐘！'
          : getStudyStartQuote(name);
    });
    _showBubble(autoFade: false);
    _startReadingAnimations();
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_studyStartTime!).inSeconds;
      setState(() => _studySeconds = elapsed);
      if (_goalMinutes > 0 &&
          !_goalReached &&
          _studySeconds >= _goalMinutes * 60) {
        _onGoalReached();
      }
    });
  }

  void _startPomodoroBreak() {
    _studyTimer?.cancel();
    setState(() {
      _inPomodoroBreak = true;
      _breakSecondsLeft = 300;
      _currentQuote = '☕ 休息一下！5 分鐘後繼續加油！';
    });
    _showBubble(autoFade: false);
    _stopReadingAnimations();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _breakSecondsLeft--);
      if (_breakSecondsLeft <= 0) {
        _breakTimer?.cancel();
        _onBreakFinished();
      }
    });
  }

  void _onBreakFinished() {
    setState(() {
      _inPomodoroBreak = false;
      _pomodoroRound++;
      _goalMinutes = 25;
      _goalReached = false;
      _currentQuote = '🍅 第 $_pomodoroRound 輪開始！繼續衝！';
    });
    _showBubble(autoFade: false);
    _startReadingAnimations();
    _studyStartTime = DateTime.now();
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_studyStartTime!).inSeconds;
      setState(() => _studySeconds += 1);
      if (!_goalReached && _studySeconds >= _goalMinutes * 60) {
        _onGoalReached();
      }
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: Text('🍅 第 $_pomodoroRound 輪開始！',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        content: const Text('休息結束！繼續 25 分鐘！',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8B5E3C))),
        actions: [
          Center(child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('衝！💪', style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
          )),
        ],
      ),
    );
  }

  void _onGoalReached() {
    setState(() {
      _goalReached = true;
      _currentQuote = _pomodoroMode ? '🍅 這輪完成！準備休息囉～' : getGoalReachedQuote(_goalMinutes);
    });
    _showBubble(autoFade: false);
    if (_pomodoroMode) {
      _startPomodoroBreak();
      return;
    }

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
    _breakTimer?.cancel();
    _stopReadingAnimations();
    setState(() { _inPomodoroBreak = false; _pomodoroMode = false; });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(goalNotReached ? '知道了...' : '太好了！',
                    style: const TextStyle(fontSize: 16)),
              ),
              if (!goalNotReached)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showPostcard(secs, _sessionName);
                  },
                  child: const Text('存明信片 🌸',
                      style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPostcard(int secs, String sessionName) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6C8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _postcardKey,
              child: _PostcardWidget(
                avatarId: _avatarId,
                secs: secs,
                sessionName: sessionName,
                date: DateTime.now(),
                rockName: _rockName,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('關閉', style: TextStyle(color: Color(0xFFAA8866))),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4F2E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('儲存'),
                  onPressed: () async {
                    try {
                      final boundary = _postcardKey.currentContext!
                          .findRenderObject() as RenderRepaintBoundary;
                      final image = await boundary.toImage(pixelRatio: 3.0);
                      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                      final bytes = byteData!.buffer.asUint8List();
                      final blob = html.Blob([bytes]);
                      final url = html.Url.createObjectUrlFromBlob(blob);
                      html.AnchorElement(href: url)
                        ..setAttribute('download', 'focus_stone_${DateTime.now().millisecondsSinceEpoch}.png')
                        ..click();
                      html.Url.revokeObjectUrl(url);
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _failStudy() async {
    _studyTimer?.cancel();
    _breakTimer?.cancel();
    _stopReadingAnimations();
    setState(() { _inPomodoroBreak = false; _pomodoroMode = false; });
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

  // ── 季節色調疊層 ──
  static Color _seasonOverlay() {
    final now = DateTime.now();
    final month = now.month;
    final hour = now.hour;
    // 時段疊層（優先）
    if (hour >= 5 && hour < 7) return const Color(0x18FFD580);  // 清晨：淡金
    if (hour >= 17 && hour < 20) return const Color(0x1AFF7043); // 黃昏：橙紅
    if (hour >= 20 || hour < 5)  return const Color(0x12536DFE); // 夜晚：靛藍
    // 季節疊層
    if (month >= 3 && month <= 5)  return const Color(0x14FFB7C5); // 春：粉櫻
    if (month >= 6 && month <= 8)  return const Color(0x12FFD600); // 夏：金陽
    if (month >= 9 && month <= 11) return const Color(0x14FF8C42); // 秋：楓橙
    return const Color(0x14ADE8F4);                                 // 冬：冰藍
  }

  // 背景圖原始尺寸 512×896，BoxFit.contain 置中
  static const double _bgW = 512, _bgH = 896;
  static double _imgScale(Size s) =>
      (s.width / _bgW) < (s.height / _bgH) ? s.width / _bgW : s.height / _bgH;
  static double _imgLeft(Size s) => (s.width - _bgW * _imgScale(s)) / 2;
  static double _imgTop(Size s) => (s.height - _bgH * _imgScale(s)) / 2;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isLandscape) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          } else {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          }
        });
        if (isLandscape) return _buildLandscape(context);

        final size = MediaQuery.of(context).size;
        final topPad = MediaQuery.of(context).padding.top;
        final botPad = MediaQuery.of(context).padding.bottom;

    // 石頭坐在地毯上（背景圖地毯約在 h*0.80）
    final rockD = (size.width * 0.34).clamp(100.0, 150.0);
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
          // ── 背景圖（低飽和治癒色調）──
          Positioned.fill(
            child: Container(
              color: const Color(0xFF7A3B1E),
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.7638, 0.2146, 0.0217, 0, 8,
                  0.0638, 0.9146, 0.0217, 0, 0,
                  0.0638, 0.2146, 0.7217, 0, -5,
                  0,      0,      0,      1, 0,
                ]),
                child: Image.asset(
                  'assets/background.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),

          // ── 季節色調疊層 ──
          Positioned.fill(child: IgnorePointer(child: Container(color: _seasonOverlay()))),

          // ── 石頭（讀書中顯示抱書版） ──
          Positioned(
            left: rockCX - rockR,
            top: rockCY - rockR - (_isStudying ? 20 : 0),
            width: rockD,
            height: rockD,
            child: GestureDetector(
              onTap: _onRockTap,
              onLongPress: () => PushService.requestPermission(context),
              child: _isStudying
                  ? _inPomodoroBreak
                      ? _ReadingOverlay(avatarId: _avatarId, rockD: rockD, swayController: _swayController, swayAnim: _swayAnim, badge: '😴')
                      : _ReadingOverlay(avatarId: _avatarId, rockD: rockD, swayController: _swayController, swayAnim: _swayAnim, badge: _goalReached ? '🌸' : '📖')
                  : AnimatedBuilder(
                      animation: _jumpController,
                      builder: (ctx, child) => Transform.translate(
                        offset: Offset(0, _jumpAnim.value),
                        child: ScaleTransition(scale: _rockScale, child: child),
                      ),
                      child: Image.asset(
                          StoneAvatar.imagePaths[_avatarId] ?? 'assets/stone.png',
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

          // ── 頂部列：頭像+名字+選單鍵  左；金幣  右 ──
          Positioned(
            top: _imgTop(size) + 14,
            left: _imgLeft(size) + 14,
            right: _imgLeft(size) + 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 頭像
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          StoneAvatar(id: _avatarId, size: 44, selected: true),
                          if (_streak > 0)
                            Positioned(
                              bottom: -6, left: 0, right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8C00),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('🔥$_streak',
                                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 石頭名字
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 選單切換按鈕
                    GestureDetector(
                      onTap: () => setState(() => _menuOpen = !_menuOpen),
                      child: AnimatedRotation(
                        turns: _menuOpen ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _menuOpen
                                ? const Color(0xFF7B4F2E).withOpacity(0.85)
                                : const Color(0xFFEDD9A3).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF8B5E3C), width: 1.2),
                          ),
                          child: Icon(Icons.menu,
                              size: 18,
                              color: _menuOpen ? Colors.white : const Color(0xFF4A2C0A)),
                        ),
                      ),
                    ),
                    const Spacer(),
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
                          const Text('🪙', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 4),
                          Text('$_coins',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7B4F2E))),
                        ],
                      ),
                    ),
                  ],
                ),
                // ── 隱藏選單列 ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: _menuOpen
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              _TopButton(icon: Icons.calendar_month,
                                  onTap: () { setState(() => _menuOpen = false);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())); }),
                              const SizedBox(width: 8),
                              _TopButton(icon: Icons.people,
                                  onTap: () { setState(() => _menuOpen = false);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsPage())); }),
                              const SizedBox(width: 8),
                              _TopButton(icon: Icons.storefront,
                                  onTap: () { setState(() => _menuOpen = false);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopPage()))
                                        .then((_) => _refreshShopData()); }),
                              const SizedBox(width: 8),
                              _TopButton(icon: Icons.new_releases_outlined,
                                  onTap: () { setState(() => _menuOpen = false);
                                    ChangelogPage.show(context); }),
                              const SizedBox(width: 8),
                              _TopButton(icon: Icons.emoji_events_outlined,
                                  onTap: () { setState(() => _menuOpen = false);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsPage())); }),
                              const SizedBox(width: 8),
                              _TopButton(icon: Icons.help_outline,
                                  onTap: () { setState(() => _menuOpen = false);
                                    HelpPage.show(context); }),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
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
                ? _StudyActiveBar(
                    timerDisplay: _timerDisplay,
                    onStop: _stopStudy,
                    inBreak: _inPomodoroBreak,
                    breakSecondsLeft: _breakSecondsLeft,
                    pomodoroRound: _pomodoroRound,
                  )
                : _StudyStartButton(onStart: _startStudy),
          ),

        ],
      ),
    );
      },
    );
  }

  Widget _buildLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rockD = (size.height * 0.35).clamp(80.0, 140.0);

    // 計算 BoxFit.cover 後石頭實際螢幕座標
    // 背景圖 1024×576，地毯中心約在圖片 (540, 478)
    const bgW = 1024.0, bgH = 576.0;
    const stoneImgX = 540.0, stoneImgY = 515.0;
    final scaleW = size.width / bgW;
    final scaleH = size.height / bgH;
    final scale = scaleW > scaleH ? scaleW : scaleH;
    final imgLeft = (size.width  - bgW * scale) / 2;
    final imgTop  = (size.height - bgH * scale) / 2;
    final stoneCX = imgLeft + stoneImgX * scale;
    final stoneCY = imgTop  + stoneImgY * scale;

    return Scaffold(
      backgroundColor: const Color(0xFF3B2010),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景 — 鋪滿橫屏，低飽和治癒色調
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.7638, 0.2146, 0.0217, 0, 8,
              0.0638, 0.9146, 0.0217, 0, 0,
              0.0638, 0.2146, 0.7217, 0, -5,
              0,      0,      0,      1, 0,
            ]),
            child: Image.asset(
              'assets/background_landscape.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // 季節色調疊層
          IgnorePointer(child: Container(color: _seasonOverlay())),
          // 四角暈影，增加沉浸感
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  const Color(0xFF3B2010).withOpacity(0.35),
                ],
              ),
            ),
          ),
          // 石頭坐在地毯上（位置根據 BoxFit.cover 實際圖片座標計算）
          Positioned(
            left: stoneCX - rockD / 2,
            top:  stoneCY - rockD,
            child: Center(
              child: GestureDetector(
                onTap: _onRockTap,
                onLongPress: () => PushService.requestPermission(context),
                child: _isStudying
                    ? _ReadingOverlay(avatarId: _avatarId, rockD: rockD, swayController: _swayController, swayAnim: _swayAnim, badge: _inPomodoroBreak ? '😴' : (_goalReached ? '🌸' : '📖'))
                    : AnimatedBuilder(
                        animation: _jumpController,
                        builder: (ctx, child) => Transform.translate(
                          offset: Offset(0, _jumpAnim.value),
                          child: ScaleTransition(scale: _rockScale, child: child),
                        ),
                        child: Image.asset(
                          StoneAvatar.imagePaths[_avatarId] ?? 'assets/stone.png',
                          width: rockD, height: rockD, fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),
          // 計時器 — 書本頁碼風格，低調放底部
          if (_isStudying)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _timerDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    color: const Color(0xFFEDD9A3).withOpacity(0.55),
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
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

// ────────────────────────────────────────
// 讀書疊層：當前頭像 + 書本/花朵 badge
// ────────────────────────────────────────
class _ReadingOverlay extends StatelessWidget {
  final int avatarId;
  final double rockD;
  final AnimationController swayController;
  final Animation<double> swayAnim;
  final String badge; // '📖' | '🌸' | '😴'

  const _ReadingOverlay({
    required this.avatarId,
    required this.rockD,
    required this.swayController,
    required this.swayAnim,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: swayController,
      builder: (_, child) => Transform.rotate(angle: swayAnim.value, child: child),
      child: SizedBox(
        width: rockD,
        height: rockD,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              StoneAvatar.imagePaths[avatarId.clamp(0, StoneAvatar.imagePaths.length - 1)] ?? 'assets/stone.png',
              width: rockD, height: rockD, fit: BoxFit.contain,
            ),
            Positioned(
              bottom: -rockD * 0.08,
              right: -rockD * 0.08,
              child: Text(badge, style: TextStyle(fontSize: rockD * 0.32)),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────
// 讀書明信片
// ────────────────────────────────────────
class _PostcardWidget extends StatelessWidget {
  final int avatarId;
  final int secs;
  final String sessionName;
  final DateTime date;
  final String rockName;
  const _PostcardWidget({
    required this.avatarId,
    required this.secs,
    required this.sessionName,
    required this.date,
    required this.rockName,
  });

  @override
  Widget build(BuildContext context) {
    final m = secs ~/ 60;
    final s = secs % 60;
    final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6C8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5E3C), width: 2),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FocusStone 📬', style: TextStyle(fontSize: 11, color: Color(0xFFAA8866))),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFFAA8866))),
            ],
          ),
          const SizedBox(height: 12),
          Image.asset(
            StoneAvatar.imagePaths[avatarId.clamp(0, StoneAvatar.imagePaths.length - 1)] ?? 'assets/stone.png',
            width: 80, height: 80, fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            rockName.isEmpty ? '我的小石頭' : rockName,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8B5E3C), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDD9A3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8B5E3C)),
            ),
            child: Text(
              timeStr,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF7B4F2E)),
            ),
          ),
          const SizedBox(height: 6),
          const Text('讀書時長', style: TextStyle(fontSize: 12, color: Color(0xFF8B5E3C))),
          if (sessionName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              sessionName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4A2C0A), fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 10),
          const Text('今日也努力讀書了 🌸', style: TextStyle(fontSize: 12, color: Color(0xFF8B5E3C))),
        ],
      ),
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
  final bool inBreak;
  final int breakSecondsLeft;
  final int pomodoroRound;
  const _StudyActiveBar({
    required this.timerDisplay,
    required this.onStop,
    this.inBreak = false,
    this.breakSecondsLeft = 300,
    this.pomodoroRound = 0,
  });

  String get _breakDisplay {
    final m = breakSecondsLeft ~/ 60;
    final s = breakSecondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: inBreak ? const Color(0xFF3D6B4F) : const Color(0xFF5D3720),
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
          Text(inBreak ? '☕' : '📖', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pomodoroRound > 0)
                  Text(
                    inBreak ? '休息時間' : '🍅 第 $pomodoroRound 輪',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                  ),
                Text(
                  inBreak ? _breakDisplay : timerDisplay,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ],
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
