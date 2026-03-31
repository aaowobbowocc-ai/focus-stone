import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'stone_avatar.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _coins = 0;
  List<int> _owned = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = prefs.getInt('total_coins') ?? 0;
    final ownedStr = prefs.getStringList('owned_avatars');
    final owned = ownedStr != null
        ? ownedStr.map(int.parse).toList()
        : List<int>.generate(StoneAvatar.count, (i) => i);
    if (mounted) {
      setState(() {
        _coins = coins;
        _owned = owned;
        _loading = false;
      });
    }
  }

  Future<void> _buy(int id) async {
    final price = StoneAvatar.prices[id];
    if (_owned.contains(id)) return;

    if (_coins < price) {
      _showSnack('金幣不夠呢。還差 ${price - _coins} 枚');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: const Text('要買這個嗎', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoneAvatar(id: id, size: 72),
            const SizedBox(height: 12),
            Text(StoneAvatar.allLabels[id],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙 ', style: TextStyle(fontSize: 16)),
                Text('$price 金幣',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7B4F2E))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(color: Color(0xFFAA8866)))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('購買', style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final newCoins = _coins - price;
    final newOwned = [..._owned, id]..sort();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_coins', newCoins);
    await prefs.setStringList('owned_avatars', newOwned.map((e) => e.toString()).toList());
    FirebaseService.updateCoins(newCoins);
    FirebaseService.updateOwnedAvatars(newOwned);

    if (mounted) {
      setState(() {
        _coins = newCoins;
        _owned = newOwned;
      });
      _showSnack('${StoneAvatar.allLabels[id]} 現身了呢');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF7B4F2E)));
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
                    child: Text('石頭的小家', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  // 金幣顯示
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text('$_coins',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid
          Positioned.fill(
            top: topPad + 56,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B4F2E)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 免費款標題
                      _SectionHeader(title: '初始石頭', subtitle: '帳號建立即擁有'),
                      const SizedBox(height: 10),
                      _buildGrid(0, StoneAvatar.count),
                      const SizedBox(height: 20),
                      // 商店款標題
                      _SectionHeader(title: '特別的石頭', subtitle: '用金幣解鎖'),
                      const SizedBox(height: 10),
                      _buildGrid(StoneAvatar.count, StoneAvatar.totalCount),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(int start, int end) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.80,
      children: List.generate(end - start, (i) {
        final id = start + i;
        return _AvatarCard(
          id: id,
          isOwned: _owned.contains(id),
          coins: _coins,
          onBuy: () => _buy(id),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        const SizedBox(width: 8),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFFAA8866))),
      ],
    );
  }
}

class _AvatarCard extends StatelessWidget {
  final int id;
  final bool isOwned;
  final int coins;
  final VoidCallback onBuy;

  const _AvatarCard({required this.id, required this.isOwned, required this.coins, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final price = StoneAvatar.prices[id];
    final isFree = price == 0;
    final canAfford = coins >= price;

    return Container(
      decoration: BoxDecoration(
        color: isOwned ? const Color(0xFFEDD9A3) : const Color(0xFFF5E6C8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwned ? const Color(0xFF7B4F2E) : const Color(0xFFCCAA88),
          width: isOwned ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.brown.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                StoneAvatar(id: id, size: 60, selected: isOwned),
                if (isOwned)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B4F2E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 11),
                  ),
              ],
            ),
            Text(StoneAvatar.allLabels[id],
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
            // 狀態/價格按鈕
            if (isOwned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B4F2E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('你的石頭', style: TextStyle(fontSize: 11, color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
              )
            else if (isFree)
              const Text('獲得', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold))
            else
              GestureDetector(
                onTap: onBuy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: canAfford ? const Color(0xFF7B4F2E) : const Color(0xFFCCAA88),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 3),
                      Text('$price',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
