import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../model/spending_trend_point.dart';

class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({super.key, required this.points});

  final List<SpendingTrendPoint> points;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _TrendPainter(points)),
          ),
          if (points.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMM d').format(points.first.date)),
                if (points.length > 1)
                  Text(DateFormat('MMM d').format(points.last.date)),
              ],
            ),
        ],
      );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.points);

  final List<SpendingTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const padding = 12.0;
    final chart = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE9DDFE)
      ..strokeWidth = 1;
    for (var line = 0; line <= 3; line++) {
      final y = chart.top + chart.height * line / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    final maximum = points.fold<double>(
      0,
      (value, point) => math.max(value, point.amount),
    );
    final denominator = maximum <= 0 ? 1 : maximum;
    final offsets = <Offset>[
      for (var index = 0; index < points.length; index++)
        Offset(
          points.length == 1
              ? chart.center.dx
              : chart.left + chart.width * index / (points.length - 1),
          chart.bottom - chart.height * points[index].amount / denominator,
        ),
    ];
    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final point in offsets.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    final fillPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, chart.bottom)
      ..lineTo(offsets.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x557C3AED), Color(0x057C3AED)],
        ).createShader(chart),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF7C3AED)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dotPaint = Paint()..color = const Color(0xFF281958);
    for (final point in offsets) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}
