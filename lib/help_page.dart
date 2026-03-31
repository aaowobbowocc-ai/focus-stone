// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';

class HelpPage {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5E6C8),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _HelpSheet(),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          const Text('小石頭使用指南',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A2C0A))),
          const SizedBox(height: 4),
          Text('慢慢看，不用急呢',
              style: TextStyle(fontSize: 12, color: const Color(0xFF8B5E3C).withOpacity(0.8))),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // ── 功能說明 ──────────────────────────
                _TipCard(
                  emoji: '🪨',
                  title: '點石頭',
                  desc: '石頭會說一些小話。心情不好的時候也可以來找牠聊聊呢。',
                ),
                _TipCard(
                  emoji: '📚',
                  title: '開始讀書',
                  desc: '按下底部按鈕開始計時。讀完會賺金幣，用來換石頭的新造型。',
                ),
                _TipCard(
                  emoji: '🪙',
                  title: '金幣 & 商店',
                  desc: '每讀 1 分鐘得 1 枚金幣。右上角可以逛石頭的小家，解鎖新造型。',
                ),
                _TipCard(
                  emoji: '👥',
                  title: '好友',
                  desc: '把邀請碼分享給朋友，可以互相看到對方今天讀了多久呢。',
                ),
                _TipCard(
                  emoji: '📅',
                  title: '讀書紀錄',
                  desc: '查看歷史紀錄與折線圖。連續讀書的天數也在這裡追蹤。',
                ),
                _TipCard(
                  emoji: '📱',
                  title: '橫轉手機',
                  desc: '手機轉橫向，進入沉浸模式。只有石頭陪著你，沒有其他干擾呢。',
                ),
                _TipCard(
                  emoji: '🔔',
                  title: '長按石頭',
                  desc: '長按石頭可以開啟推播提醒，讓石頭在你忘記讀書的時候叫你一聲。',
                ),
                _TipCard(
                  emoji: '✨',
                  title: '更新日誌',
                  desc: '石頭偷偷進化了嗎？點左上角的星星圖示查看最近的更新內容。',
                ),

                const SizedBox(height: 20),

                // ── 意見回饋 ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B4F2E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF8B5E3C).withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('💌', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('給開發者留言',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A2C0A))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '有任何建議、bug 回報，或只是想說聲謝謝，都歡迎傳訊息過來呢。',
                        style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF6B4423).withOpacity(0.85),
                            height: 1.55),
                      ),
                      const SizedBox(height: 14),
                      _FeedbackButton(
                        icon: Icons.mail_outline,
                        label: '寫信給開發者',
                        onTap: () {
                          html.window.open(
                              'mailto:dev@focusstone.app?subject=讀書石頭意見回饋',
                              '_blank');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 功能卡片 ──────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _TipCard({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDD9A3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5E3C).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A2C0A))),
                const SizedBox(height: 3),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B4423),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 回饋按鈕 ──────────────────────────────────────────────
class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeedbackButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF7B4F2E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
