import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'study_history.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<StudySession> _sessions = [];
  bool _loading = true;
  bool _showStats = false;
  String _chartPeriod = 'week'; // 'week' or 'month'

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
          Positioned.fill(
            child: Container(color: const Color(0xFFF5E6C8)),
          ),

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
                    child: Text('讀書紀錄', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  // 清單 / 統計 切換
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _showStats = !_showStats),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _showStats ? const Color(0xFFEDD9A3) : Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _showStats ? '清單' : '統計',
                          style: TextStyle(
                            color: _showStats ? const Color(0xFF7B4F2E) : Colors.white,
                            fontSize: 13, fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
                : _showStats
                    ? _buildStatsView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📚', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('還沒有讀書紀錄\n快去開始讀書吧！',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF7B4F2E), height: 1.6)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _SummaryCard(
            totalSessions: _sessions.length,
            totalSeconds: _totalSeconds,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: _sessions.length,
            itemBuilder: (ctx, i) {
              final s = _sessions[i];
              final d = s.date;
              final dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
              final timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
              return GestureDetector(
                onLongPress: () => _editName(i, s.name),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: s.failed ? const Color(0xFFF5D5D5) : const Color(0xFFEDD9A3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: s.failed ? const Color(0xFFB03030) : const Color(0xFF8B5E3C),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.brown.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(s.failed ? '💀' : '📖', style: const TextStyle(fontSize: 24)),
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
                                    color: s.failed ? const Color(0xFFB03030) : const Color(0xFF8B5E3C),
                                    fontWeight: FontWeight.w600)),
                            Text(timeStr,
                                style: const TextStyle(fontSize: 11, color: Color(0xFFAA8866))),
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
                                color: s.failed ? const Color(0xFFB03030) : const Color(0xFF4A2C0A)),
                          ),
                          if (s.failed)
                            const Text('中途離開',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB03030))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsView() {
    final streak = calculateStreak(_sessions);
    final longest = calculateLongestStreak(_sessions);
    final days = _chartPeriod == 'week' ? 7 : 30;
    final dailyData = getDailySeconds(_sessions, days);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 連續天數卡片
        Row(
          children: [
            Expanded(child: _StreakCard(icon: '🔥', label: '目前連續', value: '$streak 天')),
            const SizedBox(width: 12),
            Expanded(child: _StreakCard(icon: '🏆', label: '最長連續', value: '$longest 天')),
          ],
        ),
        const SizedBox(height: 16),
        // 折線圖
        _StudyChart(
          dailySeconds: dailyData,
          period: _chartPeriod,
          onPeriodChanged: (p) => setState(() => _chartPeriod = p),
        ),
        const SizedBox(height: 16),
        // 總覽卡片
        _SummaryCard(totalSessions: _sessions.length, totalSeconds: _totalSeconds),
      ],
    );
  }
}

// ── 統計摘要卡片 ────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int totalSessions;
  final int totalSeconds;

  const _SummaryCard({required this.totalSessions, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF7B4F2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.brown.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

// ── 連續天數卡片 ────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StreakCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF7B4F2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }
}

// ── 折線圖 ──────────────────────────────────────────────
class _StudyChart extends StatelessWidget {
  final List<int> dailySeconds;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  const _StudyChart({
    required this.dailySeconds,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < dailySeconds.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailySeconds[i] / 3600.0));
    }
    final maxY = spots.isEmpty ? 1.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3).clamp(0.5, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7B4F2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('讀書時長', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _PeriodBtn(label: '本週', selected: period == 'week', onTap: () => onPeriodChanged('week')),
                  const SizedBox(width: 6),
                  _PeriodBtn(label: '本月', selected: period == 'month', onTap: () => onPeriodChanged('month')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toStringAsFixed(0)}h',
                        style: const TextStyle(color: Colors.white54, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: period == 'week' ? 1 : 5,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        final total = dailySeconds.length;
                        final date = DateTime.now().subtract(Duration(days: total - 1 - idx));
                        if (period == 'week') {
                          const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
                          return Text(weekdays[date.weekday - 1],
                              style: const TextStyle(color: Colors.white54, fontSize: 9));
                        }
                        return Text('${date.day}',
                            style: const TextStyle(color: Colors.white54, fontSize: 9));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFEDD9A3),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: spot.y > 0 ? 3 : 2,
                        color: spot.y > 0 ? const Color(0xFFEDD9A3) : Colors.white24,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFEDD9A3).withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDD9A3) : Colors.white24,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? const Color(0xFF7B4F2E) : Colors.white70,
              fontSize: 12, fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}
