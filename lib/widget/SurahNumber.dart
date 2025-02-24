import 'package:flutter/material.dart';
import 'dart:math';

class SurahNumberIcon extends StatelessWidget {
  final int number;

  const SurahNumberIcon({Key? key, required this.number}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SurahNumberPainter(), // Menggunakan Custom Painter
      child: SizedBox(
        width: 40, // Pastikan ukuran cukup untuk outline
        height: 40,
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class SurahNumberPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paintBorder = Paint()
      ..color = Color(0xFF7C6844)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    Paint paintFill = Paint()
      ..color = Color(0xFFffecdc)
      ..style = PaintingStyle.fill;

    Path path = Path();
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double outerRadius = min(size.width, size.height) / 2;  // Lingkaran luar
    double innerRadius = outerRadius * 0.75;  // Lingkaran dalam (cekungan)

    int points = 8; // Ubah angka ini untuk menambah/kurangi gerigi
    double angleStep = pi / points;

    for (int i = 0; i < points * 2; i++) {
      double radius = (i.isEven) ? outerRadius : innerRadius;
      double angle = angleStep * i;

      double x = centerX + cos(angle) * radius;
      double y = centerY + sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
