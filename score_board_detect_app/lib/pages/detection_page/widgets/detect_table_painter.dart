import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class DetectTablePainter extends CustomPainter {
  final List<int> lines;
  final _paint = Paint()
    ..strokeWidth = 2.0
    ..color = Colors.red
    ..style = PaintingStyle.stroke;

  DetectTablePainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.length <= 5 || lines[3] < 7 || lines[4] < 1) return;

    double realWidth = size.width;
    double realHeight = size.height;
    int imgWidth = lines[1];
    int imgHeight = lines[2];
    double ratioHeight = realHeight / imgHeight;
    double ratioWidth = realWidth / imgWidth;

    for (int i = 5; i < lines.length; i += 4) {
      try {
        double x1 = lines[i] * ratioWidth;
        double y1 = lines[i + 1] * ratioHeight;
        double x2 = lines[i + 2] * ratioWidth;
        double y2 = lines[i + 3] * ratioHeight;
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _paint);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
  }

  @override
  bool shouldRepaint(DetectTablePainter oldDelegate) {
    return !const ListEquality().equals(lines, oldDelegate.lines);
  }
}
