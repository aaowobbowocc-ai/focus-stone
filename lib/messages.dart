import 'dart:math';

final _rng = Random();

// ── 開啟問候 ──────────────────────────────────────────────────────────
String getOpeningQuote({
  required bool longAbsence,
  required bool lateNight,
  required int hour,
}) {
  if (lateNight) {
    return '凌晨${hour}點？看來你的褪黑激素已經徹底戰敗了。既然都要熬夜，那就讓我們把這章看完，別讓你的肝白白犧牲。';
  }
  if (longAbsence) {
    return '你終於回來了。我以為你已經因為前額葉皮質失能，徹底被短影音給併吞了。需要我幫你預約精神科導師嗎？';
  }
  const greetings = [
    '早安，主人。今天我們的海馬迴準備好要超載了嗎？我已經準備好穩如泰山地陪你背共筆了。',
    '今天也要讀書喔。我在這裡，哪裡都不去——只有你可以跑路。',
    '你來了。我已經把你今天的書單準備好了，現在你只差打開它。',
  ];
  return greetings[_rng.nextInt(greetings.length)];
}

// ── 讀書開始 ──────────────────────────────────────────────────────────
String getStudyStartQuote(String name) {
  const starts = [
    '專注模式啟動。現在開始，除了我的石英核心，你眼裡不該有其他東西——尤其是那個閃著通知的手機。',
    '計時器啟動，藉口倒數。準備好把你的灰質填滿了嗎？',
  ];
  final base = starts[_rng.nextInt(starts.length)];
  return name.isEmpty ? base : '「$name」，加油！\n$base';
}

// ── 讀書中隨機碎碎念 ──────────────────────────────────────────────────
String getStudyRandomQuote() {
  const msgs = [
    '你知道嗎？石頭不會累，但你的肌肉梭可能需要拉伸一下。坐正，脊椎側彎可不在國考考科裡。',
    '感覺到了嗎？這是知識流進腦袋的重量。再堅持 20 分鐘，你的突觸正在努力建立連結呢。',
    '我在這裡靜靜看著你，不批評不打擾——只要你別去滑手機。',
    '讀書很辛苦，但你已經撐過比這更難的事了——起碼比點我早。',
    '中場小提醒：喝水、拉伸、不要看手機，剩下的事交給我見證。',
  ];
  return msgs[_rng.nextInt(msgs.length)];
}

// ── 滑手機懲罰（離開後回來） ──────────────────────────────────────────
String getPenaltyQuote() {
  const msgs = [
    '主人，你在看別人的生活時，我的表面積正在縮小。你再滑下去，我就要風化成沙子了。快回來讀書！',
    '你的多巴胺路徑被劫持了嗎？看些短影音對你的國考一點幫助都沒有，除非你想考「如何正確刷流量」。',
    '如果你能像滑螢幕這麼勤勞地翻書，我們現在已經在看臨床醫學了。放下手機，否則我要啟動「石碎」特效了。',
    '回來了？希望你剛才只是去上廁所，而不是刷了二十條 Reels。',
  ];
  return msgs[_rng.nextInt(msgs.length)];
}

// ── 目標達成（讀書中途） ──────────────────────────────────────────────
String getGoalReachedQuote(int goalMins) {
  return '（石頭長出一朵小花）感覺到了嗎？這是知識流進腦袋的重量。目標 $goalMins 分鐘達成！要繼續還是休息呢？';
}

// ── 結束回饋 ──────────────────────────────────────────────────────────
/// [goalSeconds] 若為 0 代表無目標或目標已在讀書中途達成。
/// [goalNotReached] 設定了目標但直接結束卻沒達到。
String getStudyEndQuote({required int seconds, required bool goalNotReached}) {
  final mins = seconds ~/ 60;
  if (goalNotReached) {
    return '就這樣？你的耐心比不反應期還要短。下次請至少堅持到一個動作電位結束好嗎？（只讀了 $mins 分鐘）';
  }
  return '辛苦了！今天讀了 $mins 分鐘，這次的知識已經慢慢滲進去了。去休息吧。';
}
