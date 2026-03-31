import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── 11 款 Q 版石頭頭像（全部 AI 生成圖片）──────────────
// 免費 (0-5): 灰色 開心 愛睏 帥氣 小花 閃星
// 商店 (6-10): 彩色 憤怒 哭泣 發呆 王者

class StoneAvatar extends StatelessWidget {
  final int id;
  final double size;
  final bool selected;

  const StoneAvatar({super.key, required this.id, this.size = 48, this.selected = false});

  static const int count = 6;        // 免費款數量
  static const int totalCount = 11;  // 全部款數量

  static const List<int> prices = [0, 0, 0, 0, 0, 0, 20, 30, 40, 50, 80];

  static const List<String> allLabels = [
    '灰石', '開心', '愛睏', '帥氣', '小花', '閃星',
    '彩色', '憤怒', '哭泣', '發呆', '王者',
  ];
  static List<String> get labels => allLabels.sublist(0, count);

  static const List<String?> imagePaths = [
    'assets/stone_normal.png',
    'assets/stone_happy.png',
    'assets/stone_sleepy.png',
    'assets/stone_cool.png',
    'assets/stone_flower.png',
    'assets/stone_star.png',
    'assets/stone_color.png',
    'assets/stone_angry.png',
    'assets/stone_cry.png',
    'assets/stone_blank.png',
    'assets/stone_king.png',
  ];

  @override
  Widget build(BuildContext context) {
    final safeId = id.clamp(0, totalCount - 1);
    final imgPath = imagePaths[safeId];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF7B4F2E) : const Color(0xFFCCAA88),
          width: selected ? 3 : 1.5,
        ),
        boxShadow: selected
            ? [BoxShadow(color: const Color(0xFF7B4F2E).withOpacity(0.4), blurRadius: 8)]
            : [],
      ),
      child: ClipOval(
        child: Image.asset(
          imgPath ?? 'assets/stone_normal.png',
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(size: Size(size, size), painter: _StonePainter(safeId)),
        ),
      ),
    );
  }
}

class _StonePainter extends CustomPainter {
  final int id;
  const _StonePainter(this.id);

  static const List<Color> bodyColors = [
    Color(0xFF9A8265), // 0 開心
    Color(0xFF7A8295), // 1 帥氣
    Color(0xFF9E9278), // 2 愛睏
    Color(0xFF8A7A9E), // 3 閃亮
    Color(0xFF9E7A7A), // 4 害羞
    Color(0xFFAD5A3A), // 5 憤怒
    Color(0xFF4A9A7A), // 6 酷炫
    Color(0xFF6A85B0), // 7 哭泣
    Color(0xFF9A80B5), // 8 發呆
    Color(0xFFBE9A2A), // 9 王者
  ];

  static const List<Color> shadowColors = [
    Color(0xFF7A6245),
    Color(0xFF5A6275),
    Color(0xFF7E7258),
    Color(0xFF6A5A7E),
    Color(0xFF7E5A5A),
    Color(0xFF8A3A1A), // 5
    Color(0xFF2A7A5A), // 6
    Color(0xFF4A6590), // 7
    Color(0xFF7A60A5), // 8
    Color(0xFF9E7A0A), // 9
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final bodyColor = bodyColors[id];
    final shadowColor = shadowColors[id];

    // 背景
    canvas.drawCircle(Offset(cx, cy), w / 2, Paint()..color = const Color(0xFFF5E6C8));

    final bodyR = w * 0.38;
    final bodyCenter = Offset(cx, cy + h * 0.04);

    // 陰影（有機石頭形狀）
    canvas.drawPath(
      _roughOval(bodyCenter + Offset(w * 0.022, h * 0.032), bodyR * 1.05, bodyR * 0.975, id),
      Paint()..color = shadowColor,
    );
    // 本體（有機石頭形狀）
    canvas.drawPath(
      _roughOval(bodyCenter, bodyR * 1.05, bodyR * 0.975, id),
      Paint()..color = bodyColor,
    );
    // 紙張顆粒感
    _grain(canvas, bodyCenter, bodyR, id);
    // 鉛筆輪廓線
    _pencilOutline(canvas, bodyCenter, bodyR * 1.055, bodyR * 0.98, shadowColor, id);
    // 高光
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyCenter + Offset(-w * 0.08, -h * 0.08),
        width: bodyR * 0.55,
        height: bodyR * 0.38,
      ),
      Paint()..color = Colors.white.withOpacity(0.22),
    );

    switch (id) {
      case 0: _drawHappy(canvas, size, bodyCenter);   break;
      case 1: _drawCool(canvas, size, bodyCenter);    break;
      case 2: _drawSleepy(canvas, size, bodyCenter);  break;
      case 3: _drawStarEyes(canvas, size, bodyCenter);break;
      case 4: _drawShy(canvas, size, bodyCenter);     break;
      case 5: _drawAngry(canvas, size, bodyCenter);   break;
      case 6: _drawDazzle(canvas, size, bodyCenter);  break;
      case 7: _drawCrying(canvas, size, bodyCenter);  break;
      case 8: _drawDazed(canvas, size, bodyCenter);   break;
      case 9: _drawKing(canvas, size, bodyCenter);    break;
    }
  }

  // ── 工具 ──────────────────────────────────────────────
  void _drawEye(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF2A1A0A));
    canvas.drawCircle(center + Offset(r * 0.3, -r * 0.35), r * 0.28, Paint()..color = Colors.white.withOpacity(0.85));
  }

  void _drawCheeks(Canvas canvas, Offset bc, double w, {double opacity = 0.45}) {
    final p = Paint()..color = const Color(0xFFFF9999).withOpacity(opacity);
    canvas.drawOval(Rect.fromCenter(center: bc + Offset(-w * 0.16, w * 0.06), width: w * 0.18, height: w * 0.10), p);
    canvas.drawOval(Rect.fromCenter(center: bc + Offset(w * 0.16, w * 0.06), width: w * 0.18, height: w * 0.10), p);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final radius = i.isEven ? r : r * 0.42;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(center.dx - size * 0.5, center.dy - size * 0.1, center.dx - size, center.dy + size * 0.15, center.dx, center.dy + size * 0.9);
    path.cubicTo(center.dx + size, center.dy + size * 0.15, center.dx + size * 0.5, center.dy - size * 0.1, center.dx, center.dy + size * 0.3);
    canvas.drawPath(path, Paint()..color = color);
  }

  // ── 0 開心 ────────────────────────────────────────────
  void _drawHappy(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawEye(canvas, bc + Offset(-w * 0.12, -w * 0.05), w * 0.065);
    _drawEye(canvas, bc + Offset(w * 0.12, -w * 0.05), w * 0.065);
    _drawCheeks(canvas, bc, w);
    final p = Path();
    p.moveTo(bc.dx - w * 0.14, bc.dy + w * 0.10);
    p.cubicTo(bc.dx - w * 0.10 + w * 0.04, bc.dy + w * 0.22, bc.dx + w * 0.10 - w * 0.04, bc.dy + w * 0.22, bc.dx + w * 0.14, bc.dy + w * 0.10);
    canvas.drawPath(p, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
  }

  // ── 1 帥氣（墨鏡） ────────────────────────────────────
  void _drawCool(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.25);
    final glassPaint = Paint()..color = const Color(0xFF1A1A2E);
    final rimPaint = Paint()..color = const Color(0xFF333355)..style = PaintingStyle.stroke..strokeWidth = w * 0.025;
    final lRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bc + Offset(-w * 0.13, -w * 0.05), width: w * 0.22, height: w * 0.15),
      Radius.circular(w * 0.04),
    );
    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bc + Offset(w * 0.13, -w * 0.05), width: w * 0.22, height: w * 0.15),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(lRect, glassPaint);
    canvas.drawRRect(rRect, glassPaint);
    canvas.drawRRect(lRect, rimPaint);
    canvas.drawRRect(rRect, rimPaint);
    canvas.drawLine(bc + Offset(-w * 0.02, -w * 0.05), bc + Offset(w * 0.02, -w * 0.05), rimPaint);
    canvas.drawLine(bc + Offset(-w * 0.24, -w * 0.05), bc + Offset(-w * 0.38, -w * 0.04), rimPaint);
    canvas.drawLine(bc + Offset(w * 0.24, -w * 0.05), bc + Offset(w * 0.38, -w * 0.04), rimPaint);
    canvas.drawLine(bc + Offset(-w * 0.17, -w * 0.09), bc + Offset(-w * 0.10, -w * 0.09),
        Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = w * 0.018..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    final mp = Path();
    mp.moveTo(bc.dx - w * 0.10, bc.dy + w * 0.11);
    mp.cubicTo(bc.dx - w * 0.04, bc.dy + w * 0.16, bc.dx + w * 0.04, bc.dy + w * 0.16, bc.dx + w * 0.10, bc.dy + w * 0.11);
    canvas.drawPath(mp, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.038..strokeCap = StrokeCap.round);
  }

  // ── 2 愛睏 ────────────────────────────────────────────
  void _drawSleepy(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.35);
    final eyePaint = Paint()..color = const Color(0xFF2A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.045..strokeCap = StrokeCap.round;
    final eyeR = w * 0.065;
    for (final ec in [bc + Offset(-w * 0.12, -w * 0.04), bc + Offset(w * 0.12, -w * 0.04)]) {
      final p = Path();
      p.moveTo(ec.dx - eyeR, ec.dy);
      p.quadraticBezierTo(ec.dx, ec.dy - eyeR * 0.5, ec.dx + eyeR, ec.dy);
      canvas.drawPath(p, eyePaint);
    }
    canvas.drawCircle(bc + Offset(0, w * 0.12), w * 0.03, Paint()..color = const Color(0xFF3A1A0A));
    final zzPaint = Paint()..color = const Color(0xFF7B6BAA)..style = PaintingStyle.stroke..strokeWidth = w * 0.03..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final zBase = bc + Offset(w * 0.22, -w * 0.18);
    final zs = w * 0.06;
    for (int i = 0; i < 2; i++) {
      final zo = Offset(i * w * 0.08, -i * w * 0.10);
      final zp = Path();
      zp.moveTo(zBase.dx + zo.dx, zBase.dy + zo.dy);
      zp.lineTo(zBase.dx + zs + zo.dx, zBase.dy + zo.dy);
      zp.lineTo(zBase.dx + zo.dx, zBase.dy + zs + zo.dy);
      zp.lineTo(zBase.dx + zs + zo.dx, zBase.dy + zs + zo.dy);
      canvas.drawPath(zp, zzPaint..strokeWidth = w * 0.025 - i * w * 0.005);
    }
  }

  // ── 3 閃亮（星星眼） ──────────────────────────────────
  void _drawStarEyes(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.50);
    for (final eyeC in [bc + Offset(-w * 0.12, -w * 0.05), bc + Offset(w * 0.12, -w * 0.05)]) {
      _drawStar(canvas, eyeC, w * 0.075, const Color(0xFFFFCC00));
      _drawStar(canvas, eyeC, w * 0.040, Colors.white);
    }
    final mp = Path();
    mp.moveTo(bc.dx - w * 0.14, bc.dy + w * 0.09);
    mp.cubicTo(bc.dx - w * 0.06, bc.dy + w * 0.20, bc.dx + w * 0.06, bc.dy + w * 0.20, bc.dx + w * 0.14, bc.dy + w * 0.09);
    canvas.drawPath(mp, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
    _drawStar(canvas, bc + Offset(w * 0.32, -w * 0.22), w * 0.04, const Color(0xFFFFCC00).withOpacity(0.8));
    _drawStar(canvas, bc + Offset(-w * 0.28, -w * 0.26), w * 0.03, const Color(0xFFFFDD44).withOpacity(0.7));
  }

  // ── 4 害羞 ────────────────────────────────────────────
  void _drawShy(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.65);
    _drawEye(canvas, bc + Offset(-w * 0.11, -w * 0.03), w * 0.060);
    _drawEye(canvas, bc + Offset(w * 0.11, -w * 0.03), w * 0.060);
    canvas.drawLine(
      bc + Offset(-w * 0.07, w * 0.12),
      bc + Offset(w * 0.07, w * 0.12),
      Paint()..color = const Color(0xFF3A1A0A)..strokeWidth = w * 0.038..strokeCap = StrokeCap.round..style = PaintingStyle.stroke,
    );
    _drawHeart(canvas, bc + Offset(w * 0.28, -w * 0.20), w * 0.07, const Color(0xFFFF6699).withOpacity(0.85));
  }

  // ── 5 憤怒 ────────────────────────────────────────────
  void _drawAngry(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    final browPaint = Paint()..color = const Color(0xFF2A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.05..strokeCap = StrokeCap.round;
    // V形眉毛
    canvas.drawLine(bc + Offset(-w * 0.18, -w * 0.13), bc + Offset(-w * 0.06, -w * 0.07), browPaint);
    canvas.drawLine(bc + Offset(w * 0.06, -w * 0.07), bc + Offset(w * 0.18, -w * 0.13), browPaint);
    _drawEye(canvas, bc + Offset(-w * 0.12, -w * 0.01), w * 0.058);
    _drawEye(canvas, bc + Offset(w * 0.12, -w * 0.01), w * 0.058);
    // 皺眉
    final fp = Path()
      ..moveTo(bc.dx - w * 0.12, bc.dy + w * 0.15)
      ..cubicTo(bc.dx - w * 0.04, bc.dy + w * 0.09, bc.dx + w * 0.04, bc.dy + w * 0.09, bc.dx + w * 0.12, bc.dy + w * 0.15);
    canvas.drawPath(fp, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
    // 蒸氣
    final sp = Paint()..color = const Color(0xFFDD5533).withOpacity(0.75)..style = PaintingStyle.stroke..strokeWidth = w * 0.022..strokeCap = StrokeCap.round;
    for (int i = 0; i < 2; i++) {
      final x = bc.dx + (i == 0 ? -w * 0.12 : w * 0.08);
      final y = bc.dy - w * 0.30;
      final steam = Path()
        ..moveTo(x, y + w * 0.10)
        ..quadraticBezierTo(x + w * 0.025, y + w * 0.05, x, y);
      canvas.drawPath(steam, sp);
    }
  }

  // ── 6 酷炫（愛心眼） ──────────────────────────────────
  void _drawDazzle(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.30);
    // 愛心眼
    _drawHeart(canvas, bc + Offset(-w * 0.12, -w * 0.09), w * 0.07, const Color(0xFFFF4488));
    _drawHeart(canvas, bc + Offset(w * 0.12, -w * 0.09), w * 0.07, const Color(0xFFFF4488));
    // 大笑嘴（露牙）
    final mouthPath = Path()
      ..moveTo(bc.dx - w * 0.14, bc.dy + w * 0.08)
      ..cubicTo(bc.dx - w * 0.10, bc.dy + w * 0.18, bc.dx + w * 0.10, bc.dy + w * 0.18, bc.dx + w * 0.14, bc.dy + w * 0.08)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF3A1A0A));
    final teethPath = Path()
      ..moveTo(bc.dx - w * 0.12, bc.dy + w * 0.095)
      ..cubicTo(bc.dx - w * 0.08, bc.dy + w * 0.135, bc.dx + w * 0.08, bc.dy + w * 0.135, bc.dx + w * 0.12, bc.dy + w * 0.095);
    canvas.drawPath(teethPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = w * 0.055..strokeCap = StrokeCap.round);
    // 閃光
    final sparkPaint = Paint()..color = const Color(0xFFFFCC00)..style = PaintingStyle.stroke..strokeWidth = w * 0.022..strokeCap = StrokeCap.round;
    for (final pos in [bc + Offset(-w * 0.32, -w * 0.20), bc + Offset(w * 0.30, -w * 0.24)]) {
      canvas.drawLine(pos + Offset(-w * 0.025, 0), pos + Offset(w * 0.025, 0), sparkPaint);
      canvas.drawLine(pos + Offset(0, -w * 0.025), pos + Offset(0, w * 0.025), sparkPaint);
    }
  }

  // ── 7 哭泣 ────────────────────────────────────────────
  void _drawCrying(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    final browPaint = Paint()..color = const Color(0xFF2A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round;
    // 悲傷眉
    canvas.drawLine(bc + Offset(-w * 0.18, -w * 0.09), bc + Offset(-w * 0.07, -w * 0.14), browPaint);
    canvas.drawLine(bc + Offset(w * 0.07, -w * 0.14), bc + Offset(w * 0.18, -w * 0.09), browPaint);
    _drawEye(canvas, bc + Offset(-w * 0.12, -w * 0.02), w * 0.060);
    _drawEye(canvas, bc + Offset(w * 0.12, -w * 0.02), w * 0.060);
    // 淚滴
    final tearPaint = Paint()..color = const Color(0xFF5599EE).withOpacity(0.90);
    for (final tPos in [bc + Offset(-w * 0.12, w * 0.05), bc + Offset(w * 0.12, w * 0.07)]) {
      final tp = Path()
        ..moveTo(tPos.dx, tPos.dy)
        ..cubicTo(tPos.dx + w * 0.04, tPos.dy + w * 0.04, tPos.dx + w * 0.04, tPos.dy + w * 0.10, tPos.dx, tPos.dy + w * 0.12)
        ..cubicTo(tPos.dx - w * 0.04, tPos.dy + w * 0.10, tPos.dx - w * 0.04, tPos.dy + w * 0.04, tPos.dx, tPos.dy);
      canvas.drawPath(tp, tearPaint);
    }
    // 難過嘴
    final sadPath = Path()
      ..moveTo(bc.dx - w * 0.12, bc.dy + w * 0.16)
      ..cubicTo(bc.dx - w * 0.04, bc.dy + w * 0.11, bc.dx + w * 0.04, bc.dy + w * 0.11, bc.dx + w * 0.12, bc.dy + w * 0.16);
    canvas.drawPath(sadPath, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
  }

  // ── 8 發呆（迴圈眼） ──────────────────────────────────
  void _drawDazed(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.18);
    // 靶心眼
    for (final eyeC in [bc + Offset(-w * 0.12, -w * 0.04), bc + Offset(w * 0.12, -w * 0.04)]) {
      final r = w * 0.072;
      canvas.drawCircle(eyeC, r, Paint()..color = const Color(0xFF2A1A0A));
      canvas.drawCircle(eyeC, r * 0.65, Paint()..color = bodyColors[8]);
      canvas.drawCircle(eyeC, r * 0.35, Paint()..color = const Color(0xFF2A1A0A));
      canvas.drawCircle(eyeC, r * 0.13, Paint()..color = Colors.white.withOpacity(0.7));
    }
    // 小O嘴
    canvas.drawCircle(bc + Offset(0, w * 0.13), w * 0.038, Paint()..color = const Color(0xFF3A1A0A));
    canvas.drawCircle(bc + Offset(0, w * 0.13), w * 0.020, Paint()..color = bodyColors[8]);
    // 波浪裝飾線
    final wavePaint = Paint()..color = const Color(0xFF7A5A95).withOpacity(0.65)..style = PaintingStyle.stroke..strokeWidth = w * 0.020..strokeCap = StrokeCap.round;
    final waveStart = bc + Offset(w * 0.22, -w * 0.24);
    final wp = Path()
      ..moveTo(waveStart.dx, waveStart.dy)
      ..quadraticBezierTo(waveStart.dx + w * 0.04, waveStart.dy - w * 0.03, waveStart.dx + w * 0.08, waveStart.dy)
      ..quadraticBezierTo(waveStart.dx + w * 0.12, waveStart.dy + w * 0.03, waveStart.dx + w * 0.16, waveStart.dy);
    canvas.drawPath(wp, wavePaint);
  }

  // ── 9 王者（王冠） ────────────────────────────────────
  void _drawKing(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    // 王冠
    final crownBase = bc + Offset(0, -w * 0.24);
    final cw = w * 0.26;
    final ch = w * 0.13;
    final goldPaint = Paint()..color = const Color(0xFFFFCC00);
    final crownPath = Path()
      ..moveTo(crownBase.dx - cw / 2, crownBase.dy + ch)
      ..lineTo(crownBase.dx - cw / 2, crownBase.dy + ch * 0.35)
      ..lineTo(crownBase.dx - cw / 4, crownBase.dy + ch)
      ..lineTo(crownBase.dx, crownBase.dy - ch * 0.25)
      ..lineTo(crownBase.dx + cw / 4, crownBase.dy + ch)
      ..lineTo(crownBase.dx + cw / 2, crownBase.dy + ch * 0.35)
      ..lineTo(crownBase.dx + cw / 2, crownBase.dy + ch)
      ..close();
    canvas.drawPath(crownPath, goldPaint);
    canvas.drawPath(crownPath, Paint()..color = const Color(0xFFAA8800)..style = PaintingStyle.stroke..strokeWidth = w * 0.016);
    // 寶石
    canvas.drawCircle(crownBase + Offset(0, ch * 0.55), w * 0.022, Paint()..color = const Color(0xFFFF3333));
    canvas.drawCircle(crownBase + Offset(-cw * 0.30, ch * 0.78), w * 0.015, Paint()..color = const Color(0xFF4488FF));
    canvas.drawCircle(crownBase + Offset(cw * 0.30, ch * 0.78), w * 0.015, Paint()..color = const Color(0xFF44CC44));
    // 自信閉眼（上彎弧線）
    final eyePaint = Paint()..color = const Color(0xFF2A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.048..strokeCap = StrokeCap.round;
    for (final eyeC in [bc + Offset(-w * 0.12, -w * 0.03), bc + Offset(w * 0.12, -w * 0.03)]) {
      final ep = Path()
        ..moveTo(eyeC.dx - w * 0.065, eyeC.dy)
        ..cubicTo(eyeC.dx - w * 0.02, eyeC.dy - w * 0.065, eyeC.dx + w * 0.02, eyeC.dy - w * 0.065, eyeC.dx + w * 0.065, eyeC.dy);
      canvas.drawPath(ep, eyePaint);
    }
    // 自信微笑
    final smilePath = Path()
      ..moveTo(bc.dx - w * 0.09, bc.dy + w * 0.10)
      ..cubicTo(bc.dx - w * 0.02, bc.dy + w * 0.16, bc.dx + w * 0.06, bc.dy + w * 0.16, bc.dx + w * 0.12, bc.dy + w * 0.11);
    canvas.drawPath(smilePath, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
  }

  // ── 有機橢圓（仿手繪石頭輪廓）────────────────────────────
  // 用 Catmull-Rom 插值 + 以 id 為 seed 的微擾，讓每顆石頭形狀略有不同
  Path _roughOval(Offset c, double rx, double ry, int seed) {
    const n = 10;
    final pts = List.generate(n, (i) {
      final a = i / n * math.pi * 2;
      final j = rx * 0.038 * math.sin(seed * 1.37 + i * 2.31);
      return Offset(
        c.dx + (rx + j) * math.cos(a),
        c.dy + (ry + j * 0.72) * math.sin(a),
      );
    });
    final path = Path();
    for (int i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      if (i == 0) path.moveTo(p1.dx, p1.dy);
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx, p2.dy,
      );
    }
    path.close();
    return path;
  }

  // ── 紙張顆粒感 ────────────────────────────────────────────
  void _grain(Canvas canvas, Offset c, double r, int seed) {
    final p = Paint()..color = const Color(0xFF000000).withOpacity(0.032);
    const count = 22;
    for (int i = 0; i < count; i++) {
      final a = i * 2.399 + seed * 0.87;
      final dist = r * 0.82 * math.sqrt((i + 0.5) / count);
      final dx = dist * math.cos(a);
      final dy = dist * math.sin(a) * 0.93;
      final dotR = 0.65 + 0.45 * math.sin(i * 1.5 + seed * 0.6);
      canvas.drawCircle(Offset(c.dx + dx, c.dy + dy), dotR, p);
    }
  }

  // ── 鉛筆感輪廓線 ──────────────────────────────────────────
  void _pencilOutline(Canvas canvas, Offset c, double rx, double ry, Color color, int seed) {
    for (int stroke = 0; stroke < 2; stroke++) {
      final off = Offset(stroke * 0.35, stroke * 0.25);
      final path = _roughOval(c + off, rx + stroke * 0.25, ry + stroke * 0.18, seed + stroke * 47);
      canvas.drawPath(path, Paint()
        ..color = color.withOpacity(0.32 - stroke * 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + stroke * 0.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(_StonePainter old) => old.id != id;
}
