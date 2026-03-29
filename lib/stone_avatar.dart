import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── 5 款 Q 版石頭頭像 ──────────────────────────────────
// 0: 開心  1: 墨鏡帥  2: 睡眠  3: 閃亮  4: 害羞

class StoneAvatar extends StatelessWidget {
  final int id;
  final double size;
  final bool selected;

  const StoneAvatar({super.key, required this.id, this.size = 48, this.selected = false});

  static const int count = 5;

  static const List<String> labels = ['開心', '帥氣', '愛睏', '閃亮', '害羞'];

  @override
  Widget build(BuildContext context) {
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
        child: CustomPaint(
          size: Size(size, size),
          painter: _StonePainter(id),
        ),
      ),
    );
  }
}

class _StonePainter extends CustomPainter {
  final int id;
  const _StonePainter(this.id);

  // 石頭本體顏色
  static const List<Color> bodyColors = [
    Color(0xFF9A8265), // 開心 - 暖棕
    Color(0xFF7A8295), // 帥氣 - 藍灰
    Color(0xFF9E9278), // 愛睏 - 米棕
    Color(0xFF8A7A9E), // 閃亮 - 紫灰
    Color(0xFF9E7A7A), // 害羞 - 粉棕
  ];

  static const List<Color> shadowColors = [
    Color(0xFF7A6245),
    Color(0xFF5A6275),
    Color(0xFF7E7258),
    Color(0xFF6A5A7E),
    Color(0xFF7E5A5A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final bodyColor = bodyColors[id];
    final shadowColor = shadowColors[id];

    // ── 背景 ──
    canvas.drawCircle(Offset(cx, cy), w / 2, Paint()..color = const Color(0xFFF5E6C8));

    // ── 石頭本體（不規則圓） ──
    final bodyPaint = Paint()..color = bodyColor;
    final shadowPaint = Paint()..color = shadowColor;

    final bodyR = w * 0.38;
    final bodyCenter = Offset(cx, cy + h * 0.04);

    // 陰影
    canvas.drawOval(
      Rect.fromCenter(center: bodyCenter + Offset(w * 0.02, h * 0.03), width: bodyR * 2.1, height: bodyR * 1.95),
      shadowPaint,
    );
    // 本體
    canvas.drawOval(
      Rect.fromCenter(center: bodyCenter, width: bodyR * 2.1, height: bodyR * 1.95),
      bodyPaint,
    );

    // 高光
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyCenter + Offset(-w * 0.08, -h * 0.08),
        width: bodyR * 0.55,
        height: bodyR * 0.38,
      ),
      Paint()..color = Colors.white.withOpacity(0.25),
    );

    // ── 根據 id 畫不同表情 ──
    switch (id) {
      case 0: _drawHappy(canvas, size, bodyCenter);    break;
      case 1: _drawCool(canvas, size, bodyCenter);     break;
      case 2: _drawSleepy(canvas, size, bodyCenter);   break;
      case 3: _drawStarEyes(canvas, size, bodyCenter); break;
      case 4: _drawShy(canvas, size, bodyCenter);      break;
    }
  }

  // ── 眼睛工具 ──
  void _drawEye(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF2A1A0A));
    canvas.drawCircle(center + Offset(r * 0.3, -r * 0.35), r * 0.28, Paint()..color = Colors.white.withOpacity(0.85));
  }

  // ── 腮紅 ──
  void _drawCheeks(Canvas canvas, Offset bodyCenter, double w, {double opacity = 0.45}) {
    final blush = Paint()..color = const Color(0xFFFF9999).withOpacity(opacity);
    canvas.drawOval(Rect.fromCenter(center: bodyCenter + Offset(-w * 0.16, w * 0.06), width: w * 0.18, height: w * 0.10), blush);
    canvas.drawOval(Rect.fromCenter(center: bodyCenter + Offset(w * 0.16, w * 0.06), width: w * 0.18, height: w * 0.10), blush);
  }

  // ── 0 開心 ──
  void _drawHappy(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawEye(canvas, bc + Offset(-w * 0.12, -w * 0.05), w * 0.065);
    _drawEye(canvas, bc + Offset(w * 0.12, -w * 0.05), w * 0.065);
    _drawCheeks(canvas, bc, w);
    // 大笑嘴巴
    final mouthPath = Path();
    final mouthL = bc + Offset(-w * 0.14, w * 0.10);
    final mouthR = bc + Offset(w * 0.14, w * 0.10);
    mouthPath.moveTo(mouthL.dx, mouthL.dy);
    mouthPath.cubicTo(
      mouthL.dx + w * 0.04, mouthL.dy + w * 0.12,
      mouthR.dx - w * 0.04, mouthR.dy + w * 0.12,
      mouthR.dx, mouthR.dy,
    );
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
  }

  // ── 1 帥氣（墨鏡） ──
  void _drawCool(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.25);
    // 墨鏡框
    final glassPaint = Paint()..color = const Color(0xFF1A1A2E);
    final rimPaint = Paint()..color = const Color(0xFF333355)..style = PaintingStyle.stroke..strokeWidth = w * 0.025;
    // 左鏡片
    final lRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bc + Offset(-w * 0.13, -w * 0.05), width: w * 0.22, height: w * 0.15),
      Radius.circular(w * 0.04),
    );
    // 右鏡片
    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bc + Offset(w * 0.13, -w * 0.05), width: w * 0.22, height: w * 0.15),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(lRect, glassPaint);
    canvas.drawRRect(rRect, glassPaint);
    canvas.drawRRect(lRect, rimPaint);
    canvas.drawRRect(rRect, rimPaint);
    // 鼻橋
    canvas.drawLine(bc + Offset(-w * 0.02, -w * 0.05), bc + Offset(w * 0.02, -w * 0.05), rimPaint);
    // 鏡框鏡腿
    canvas.drawLine(bc + Offset(-w * 0.24, -w * 0.05), bc + Offset(-w * 0.38, -w * 0.04), rimPaint);
    canvas.drawLine(bc + Offset(w * 0.24, -w * 0.05), bc + Offset(w * 0.38, -w * 0.04), rimPaint);
    // 高光
    canvas.drawLine(bc + Offset(-w * 0.17, -w * 0.09), bc + Offset(-w * 0.10, -w * 0.09),
        Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = w * 0.018..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    // 微笑
    final mouthPath = Path();
    mouthPath.moveTo(bc.dx - w * 0.10, bc.dy + w * 0.11);
    mouthPath.cubicTo(bc.dx - w * 0.04, bc.dy + w * 0.16, bc.dx + w * 0.04, bc.dy + w * 0.16, bc.dx + w * 0.10, bc.dy + w * 0.11);
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.038..strokeCap = StrokeCap.round);
  }

  // ── 2 愛睏 ──
  void _drawSleepy(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.35);
    // 半閉眼（弧線）
    final eyePaint = Paint()..color = const Color(0xFF2A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.045..strokeCap = StrokeCap.round;
    final lEyeC = bc + Offset(-w * 0.12, -w * 0.04);
    final rEyeC = bc + Offset(w * 0.12, -w * 0.04);
    final eyeR = w * 0.065;
    for (final ec in [lEyeC, rEyeC]) {
      final p = Path();
      p.moveTo(ec.dx - eyeR, ec.dy);
      p.quadraticBezierTo(ec.dx, ec.dy - eyeR * 0.5, ec.dx + eyeR, ec.dy);
      canvas.drawPath(p, eyePaint);
    }
    // 小嘴
    canvas.drawCircle(bc + Offset(0, w * 0.12), w * 0.03, Paint()..color = const Color(0xFF3A1A0A));
    // Zzz
    final zzPaint = Paint()..color = const Color(0xFF7B6BAA)..style = PaintingStyle.stroke..strokeWidth = w * 0.03..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final zBase = bc + Offset(w * 0.22, -w * 0.18);
    final zs = w * 0.06;
    for (int i = 0; i < 2; i++) {
      final zo = Offset(i * w * 0.08, -i * w * 0.1);
      final zp = Path();
      zp.moveTo(zBase.dx + zo.dx, zBase.dy + zo.dy);
      zp.lineTo(zBase.dx + zs + zo.dx, zBase.dy + zo.dy);
      zp.lineTo(zBase.dx + zo.dx, zBase.dy + zs + zo.dy);
      zp.lineTo(zBase.dx + zs + zo.dx, zBase.dy + zs + zo.dy);
      canvas.drawPath(zp, zzPaint..strokeWidth = w * 0.025 - i * w * 0.005);
    }
  }

  // ── 3 閃亮（星星眼） ──
  void _drawStarEyes(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    _drawCheeks(canvas, bc, w, opacity: 0.50);
    // 星形眼
    for (final eyeC in [bc + Offset(-w * 0.12, -w * 0.05), bc + Offset(w * 0.12, -w * 0.05)]) {
      _drawStar(canvas, eyeC, w * 0.075, const Color(0xFFFFCC00));
      _drawStar(canvas, eyeC, w * 0.040, Colors.white);
    }
    // 大笑嘴
    final mouthPath = Path();
    mouthPath.moveTo(bc.dx - w * 0.14, bc.dy + w * 0.09);
    mouthPath.cubicTo(bc.dx - w * 0.06, bc.dy + w * 0.20, bc.dx + w * 0.06, bc.dy + w * 0.20, bc.dx + w * 0.14, bc.dy + w * 0.09);
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF3A1A0A)..style = PaintingStyle.stroke..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
    // 小星星裝飾
    _drawStar(canvas, bc + Offset(w * 0.32, -w * 0.22), w * 0.04, const Color(0xFFFFCC00).withOpacity(0.8));
    _drawStar(canvas, bc + Offset(-w * 0.28, -w * 0.26), w * 0.03, const Color(0xFFFFDD44).withOpacity(0.7));
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

  // ── 4 害羞 ──
  void _drawShy(Canvas canvas, Size size, Offset bc) {
    final w = size.width;
    // 深粉腮紅
    _drawCheeks(canvas, bc, w, opacity: 0.65);
    // 眼睛（往下看）
    _drawEye(canvas, bc + Offset(-w * 0.11, -w * 0.03), w * 0.060);
    _drawEye(canvas, bc + Offset(w * 0.11, -w * 0.03), w * 0.060);
    // 小嘴（抿嘴）
    canvas.drawLine(
      bc + Offset(-w * 0.07, w * 0.12),
      bc + Offset(w * 0.07, w * 0.12),
      Paint()..color = const Color(0xFF3A1A0A)..strokeWidth = w * 0.038..strokeCap = StrokeCap.round..style = PaintingStyle.stroke,
    );
    // 小愛心
    _drawHeart(canvas, bc + Offset(w * 0.28, -w * 0.20), w * 0.07, const Color(0xFFFF6699).withOpacity(0.85));
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(center.dx - size * 0.5, center.dy - size * 0.1, center.dx - size, center.dy + size * 0.15, center.dx, center.dy + size * 0.9);
    path.cubicTo(center.dx + size, center.dy + size * 0.15, center.dx + size * 0.5, center.dy - size * 0.1, center.dx, center.dy + size * 0.3);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StonePainter old) => old.id != id;
}
