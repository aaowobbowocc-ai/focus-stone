import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 手繪風溫馨木質房間背景（純 Flutter 繪製，不依賴圖片）
class RoomBackground extends StatelessWidget {
  const RoomBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoomPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _RoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 牆壁（暖米色）──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.72),
      Paint()..color = const Color(0xFFE8C99A),
    );

    // ── 木地板 ──
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
      Paint()..color = const Color(0xFFA0673A),
    );
    // 地板木紋線
    final floorLine = Paint()
      ..color = const Color(0xFF8B5A2B).withOpacity(0.4)
      ..strokeWidth = 1;
    for (double y = h * 0.73; y < h; y += h * 0.04) {
      canvas.drawLine(Offset(0, y), Offset(w, y), floorLine);
    }

    // ── 木牆板條 ──
    final wallBoard = Paint()
      ..color = const Color(0xFFD4A96A).withOpacity(0.3)
      ..strokeWidth = 1.5;
    for (double y = h * 0.05; y < h * 0.72; y += h * 0.07) {
      canvas.drawLine(Offset(0, y), Offset(w, y), wallBoard);
    }

    // ── 窗戶（右上） ──
    final winLeft = w * 0.52;
    final winTop = h * 0.06;
    final winW = w * 0.42;
    final winH = h * 0.30;

    // 窗框外
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(winLeft, winTop, winW, winH),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF8B6343),
    );
    // 窗玻璃（天空漸層）
    final skyRect = Rect.fromLTWH(
        winLeft + 5, winTop + 5, winW - 10, winH - 10);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFADD8F7),
            const Color(0xFFFFE4A0),
          ],
        ).createShader(skyRect),
    );
    // 窗格（十字）
    final winGrid = Paint()
      ..color = const Color(0xFF8B6343)
      ..strokeWidth = 2.5;
    canvas.drawLine(
        Offset(winLeft + winW / 2, winTop + 5),
        Offset(winLeft + winW / 2, winTop + winH - 5),
        winGrid);
    canvas.drawLine(
        Offset(winLeft + 5, winTop + winH / 2),
        Offset(winLeft + winW - 5, winTop + winH / 2),
        winGrid);

    // 陽光斜射
    final sunPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final sunPath = Path()
      ..moveTo(winLeft + winW * 0.3, winTop + winH)
      ..lineTo(winLeft - w * 0.1, h * 0.75)
      ..lineTo(winLeft + w * 0.3, h * 0.75)
      ..lineTo(winLeft + winW * 0.9, winTop + winH)
      ..close();
    canvas.drawPath(sunPath, sunPaint);

    // ── 書架（左側） ──
    final shelfX = w * 0.03;
    final shelfY = h * 0.08;
    final shelfW = w * 0.34;
    final shelfH = h * 0.45;
    // 書架本體
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(shelfX, shelfY, shelfW, shelfH),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8B5E3C),
    );
    // 書架隔板
    final shelfBoard = Paint()
      ..color = const Color(0xFF6B4423)
      ..strokeWidth = 4;
    for (int i = 1; i <= 3; i++) {
      final y = shelfY + shelfH * i / 4;
      canvas.drawLine(
          Offset(shelfX + 3, y), Offset(shelfX + shelfW - 3, y), shelfBoard);
    }
    // 書本（各層）
    final bookColors = [
      const Color(0xFFE74C3C),
      const Color(0xFF3498DB),
      const Color(0xFF2ECC71),
      const Color(0xFFF39C12),
      const Color(0xFF9B59B6),
      const Color(0xFFE67E22),
      const Color(0xFF1ABC9C),
      const Color(0xFFE91E63),
    ];
    for (int row = 0; row < 3; row++) {
      double bx = shelfX + 5;
      final by = shelfY + shelfH * row / 4 + 4;
      final bh = shelfH / 4 - 8;
      for (int j = 0; j < 5; j++) {
        final bw = shelfW / 6.5;
        canvas.drawRect(
          Rect.fromLTWH(bx, by, bw - 2, bh),
          Paint()..color = bookColors[(row * 5 + j) % bookColors.length],
        );
        bx += bw;
      }
    }
    // 小擺飾（最頂層）
    _drawMushroom(canvas, Offset(shelfX + shelfW * 0.3, shelfY + shelfH * 0.22), 10);
    _drawStar(canvas, Offset(shelfX + shelfW * 0.7, shelfY + shelfH * 0.18), 8,
        const Color(0xFFFFD700));

    // ── 書桌 ──
    final deskTop = h * 0.64;
    final deskH = h * 0.11;
    // 桌面
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, deskTop, w * 0.84, deskH * 0.25),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF7B4F2E),
    );
    // 桌腳（兩腳）
    final legPaint = Paint()..color = const Color(0xFF6B3D1E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, deskTop + deskH * 0.25, w * 0.07, deskH * 0.75),
        const Radius.circular(3),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.81, deskTop + deskH * 0.25, w * 0.07, deskH * 0.75),
        const Radius.circular(3),
      ),
      legPaint,
    );

    // ── 桌上：小植物（右側） ──
    _drawPlant(canvas, Offset(w * 0.82, deskTop - 2));

    // ── 桌上：台燈（左側） ──
    _drawLamp(canvas, Offset(w * 0.22, deskTop));

    // ── 地毯 ──
    final carpetPaint = Paint()
      ..color = const Color(0xFFD4956A).withOpacity(0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.85),
        width: w * 0.7,
        height: h * 0.08,
      ),
      carpetPaint,
    );
    // 地毯花紋
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.85),
        width: w * 0.5,
        height: h * 0.055,
      ),
      Paint()
        ..color = const Color(0xFFBF7D4E).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawMushroom(Canvas canvas, Offset pos, double r) {
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: r * 2, height: r * 1.4),
      Paint()..color = const Color(0xFFE74C3C),
    );
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + r * 0.8),
          width: r * 0.8,
          height: r * 1.0),
      Paint()..color = const Color(0xFFF5DEB3),
    );
  }

  void _drawStar(Canvas canvas, Offset pos, double r, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final x = pos.dx + r * 0.9 * math.cos(angle);
      final y = pos.dy + r * 0.9 * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPlant(Canvas canvas, Offset base) {
    // 花盆
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 12, base.dy - 22, 24, 22),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFCD7F32),
    );
    // 葉子
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(base.dx - 6, base.dy - 32), width: 16, height: 22),
        leafPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(base.dx + 6, base.dy - 34), width: 16, height: 22),
        leafPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(base.dx, base.dy - 38), width: 14, height: 20),
        leafPaint);
  }

  void _drawLamp(Canvas canvas, Offset base) {
    // 燈桿
    canvas.drawLine(
      Offset(base.dx, base.dy),
      Offset(base.dx, base.dy - 36),
      Paint()
        ..color = const Color(0xFF8B6343)
        ..strokeWidth = 3,
    );
    // 燈罩
    final lampPath = Path()
      ..moveTo(base.dx - 18, base.dy - 36)
      ..lineTo(base.dx + 18, base.dy - 36)
      ..lineTo(base.dx + 10, base.dy - 52)
      ..lineTo(base.dx - 10, base.dy - 52)
      ..close();
    canvas.drawPath(lampPath, Paint()..color = const Color(0xFFFFD54F));
    // 燈光光暈
    canvas.drawCircle(
      Offset(base.dx, base.dy - 36),
      28,
      Paint()..color = const Color(0xFFFFFF99).withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
