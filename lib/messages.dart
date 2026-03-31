import 'dart:math';

final _rng = Random();

// ── 開啟問候 ──────────────────────────────────────────────────────────
String getOpeningQuote({
  required bool longAbsence,
  required bool lateNight,
  required int hour,
}) {
  if (lateNight) {
    return '凌晨${hour}點呢。睡眠很重要，但如果你想讀書，我也在。';
  }
  if (longAbsence) {
    return '你回來了。有點想你呢。';
  }
  const greetings = [
    '你來了。我一直在這裡呢。',
    '今天也一起讀書吧。慢慢來就好。',
    '早安呢。準備好了嗎。',
    '歡迎回來。今天想讀多久都好。',
  ];
  return greetings[_rng.nextInt(greetings.length)];
}

// ── 讀書開始 ──────────────────────────────────────────────────────────
String getStudyStartQuote(String name) {
  const starts = [
    '一起專注吧。現在只有讀書和我。',
    '計時開始了。慢慢讀，我陪著呢。',
    '開始了呢。不用急，穩穩的。',
  ];
  final base = starts[_rng.nextInt(starts.length)];
  return name.isEmpty ? base : '「$name」呢。$base';
}

// ── 讀書中隨機碎碎念 ──────────────────────────────────────────────────
String getStudyRandomQuote() {
  const msgs = [
    '坐正了呢。脊椎會感謝你的。',
    '知識慢慢流進去了。再堅持一下吧。',
    '我靜靜看著你呢。專注的樣子很好看。',
    '讀書很辛苦，你很棒呢。',
    '喝水了嗎。休息一下也沒關係呢。',
    '窗外的風景可以等，書頁先翻一頁吧。',
  ];
  return msgs[_rng.nextInt(msgs.length)];
}

// ── 滑手機懲罰（離開後回來） ──────────────────────────────────────────
String getPenaltyQuote() {
  const msgs = [
    '你走開了呢。沒關係，回來就好。',
    '短影音看完了嗎。我在這等著呢。',
    '放下手機吧。一起讀書呢。',
    '你回來了。沒有責備，只是高興呢。',
    '去哪裡了呢。書還開著等你。',
  ];
  return msgs[_rng.nextInt(msgs.length)];
}

// ── 目標達成（讀書中途） ──────────────────────────────────────────────
String getGoalReachedQuote(int goalMins) {
  return '（小花開了）$goalMins 分鐘達成了呢。要繼續，還是休息一下。';
}

// ── 結束回饋 ──────────────────────────────────────────────────────────
String getStudyEndQuote({required int seconds, required bool goalNotReached}) {
  final mins = seconds ~/ 60;
  if (goalNotReached) {
    return '今天讀了 $mins 分鐘呢。沒完成也沒關係，明天再來。';
  }
  return '讀了 $mins 分鐘呢。辛苦了。去休息吧。';
}
