import 'package:flutter/material.dart';
import 'study_history.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<StudySession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await StudyHistory.load();
    if (mounted) setState(() { _sessions = sessions; _loading = false; });
  }

  Future<void> _editName(int displayIndex, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5E6C8),
        title: const Text('編輯名稱',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A2C0A))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFEDD9A3),
            counterStyle: const TextStyle(color: Color(0xFFAA8866)),
            hintText: '例：解剖學第三章',
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Color(0xFFAA8866))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('儲存', style: TextStyle(color: Color(0xFF7B4F2E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (newName == null) return;
    await StudyHistory.updateName(displayIndex, newName);
    _load();
  }

  int get _totalSeconds =>
      _sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6C8),
      body: Stack(
        children: [
          // 木質暖色背景
          Positioned.fill(
            child: Container(color: const Color(0xFFF5E6C8)),
          ),

          // 頂部 AppBar 區
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      '讀書紀錄',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // 內容
          Positioned.fill(
            top: topPad + 56,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7B4F2E)))
                : _sessions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('📚', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text(
                              '還沒有讀書紀錄\n快去開始讀書吧！',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFF7B4F2E), height: 1.6),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // 統計卡片
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: _SummaryCard(
                              totalSessions: _sessions.length,
                              totalSeconds: _totalSeconds,
                            ),
                          ),
                          // 清單
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: _sessions.length,
                              itemBuilder: (ctx, i) {
                                final s = _sessions[i];
                                final d = s.date;
                                final dateStr =
                                    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                                final timeStr =
                                    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                                return GestureDetector(
                                  onLongPress: () => _editName(i, s.name),
                                  child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: s.failed
                                        ? const Color(0xFFF5D5D5)
                                        : const Color(0xFFEDD9A3),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: s.failed
                                            ? const Color(0xFFB03030)
                                            : const Color(0xFF8B5E3C),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.brown.withOpacity(0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(s.failed ? '💀' : '📖',
                                          style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    s.name.isNotEmpty ? s.name : '（未命名）',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: s.name.isNotEmpty
                                                            ? (s.failed ? const Color(0xFFB03030) : const Color(0xFF4A2C0A))
                                                            : const Color(0xFFAA8866),
                                                        fontWeight: s.name.isNotEmpty ? FontWeight.bold : FontWeight.normal),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => _editName(i, s.name),
                                                  child: const Padding(
                                                    padding: EdgeInsets.only(left: 4),
                                                    child: Icon(Icons.edit, size: 14, color: Color(0xFFAA8866)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(dateStr,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: s.failed
                                                        ? const Color(0xFFB03030)
                                                        : const Color(0xFF8B5E3C),
                                                    fontWeight: FontWeight.w600)),
                                            Text(timeStr,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFAA8866))),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formatStudyDuration(s.durationSeconds),
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: s.failed
                                                    ? const Color(0xFFB03030)
                                                    : const Color(0xFF4A2C0A)),
                                          ),
                                          if (s.failed)
                                            const Text('中途離開',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFB03030))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ));
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalSessions;
  final int totalSeconds;

  const _SummaryCard({
    required this.totalSessions,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF7B4F2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.brown.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(label: '讀書次數', value: '$totalSessions 次'),
          Container(width: 1, height: 36, color: Colors.white30),
          _Stat(label: '累計時長', value: formatStudyDuration(totalSeconds)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}
