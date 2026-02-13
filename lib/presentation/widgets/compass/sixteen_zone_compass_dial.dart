import 'dart:math' as math;
import 'package:flutter/material.dart';

class SixteenZoneCompassDial extends StatelessWidget {
  final double heading;
  final bool isMapMode;

  const SixteenZoneCompassDial({
    super.key,
    required this.heading,
    this.isMapMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: CustomPaint(
        painter: SixteenZoneCompassPainter(heading: heading, isMapMode: isMapMode),
        child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}

class SixteenZoneCompassPainter extends CustomPainter {
  final double heading;
  final bool isMapMode;

  SixteenZoneCompassPainter({required this.heading, this.isMapMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = isMapMode ? 0.6 : 1.0;

    // Save canvas to rotate the entire dial based on heading
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * (math.pi / 180));

    // 16 Zones - 22.5 degrees each
    final double sectorAngle = 22.5 * (math.pi / 180);
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    // List of zones: Label, Color (approximate from screenshot/Vastu)
    // Starting from North (0 degrees is typically up, but Arc starts at 0 = East (3 o'clock))
    // We need to shift drawing so North is at -90 degrees (-pi/2)
    
    // Vastu 16 Zones order from North clockwise:
    // N, NNE, NE, ENE, E, ESE, SE, SSE, S, SSW, SW, WSW, W, WNW, NW, NNW
    
    final List<Map<String, dynamic>> zones = [
      {'label': 'N',   'color': const Color(0xFF2196F3)}, // Blue
      {'label': 'NNE', 'color': const Color(0xFF42A5F5)}, // Light Blue
      {'label': 'NE',  'color': const Color(0xFF64B5F6)}, // Lighter Blue
      {'label': 'ENE', 'color': const Color(0xFF43A047)}, // Green
      {'label': 'E',   'color': const Color(0xFF4CAF50)}, // Green
      {'label': 'ESE', 'color': const Color(0xFF66BB6A)}, // Light Green
      {'label': 'SE',  'color': const Color(0xFFE53935)}, // Red
      {'label': 'SSE', 'color': const Color(0xFFEF5350)}, // Light Red
      {'label': 'S',   'color': const Color(0xFFD32F2F)}, // Red/Orange
      {'label': 'SSW', 'color': const Color(0xFFFFB300)}, // Amber
      {'label': 'SW',  'color': const Color(0xFFFFC107)}, // Amber/Yellow
      {'label': 'WSW', 'color': const Color(0xFFFFD54F)}, // Yellow
      {'label': 'W',   'color': const Color(0xFFEEEEEE)}, // White/Grey
      {'label': 'WNW', 'color': const Color(0xFFE0E0E0)}, // Grey
      {'label': 'NW',  'color': const Color(0xFFBDBDBD)}, // Grey
      {'label': 'NNW', 'color': const Color(0xFF90CAF9)}, // Pale Blue/Water-Air mix
    ];

    // Angle offset to center North at top (-pi/2)
    // The first sector N should be centered at -pi/2. 
    // So it starts at -pi/2 - sectorAngle/2
    double startAngle = -math.pi / 2 - (sectorAngle / 2);

    for (var i = 0; i < zones.length; i++) {
        paint.color = (zones[i]['color'] as Color).withOpacity(opacity);
        canvas.drawArc(rect, startAngle, sectorAngle, true, paint);
        
        // Draw Border for sector
        final borderPaint = Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawArc(rect, startAngle, sectorAngle, true, borderPaint);

        startAngle += sectorAngle;
    }

    // Inner white circle to create the ring effect (donut shape)
    paint.color = Colors.white.withOpacity(isMapMode ? 0.8 : 1.0);
    canvas.drawCircle(Offset.zero, radius * 0.60, paint);
    
    // Draw Text Labels centered in each sector
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    double labelAngle = -math.pi / 2; // Start at North
    final labelRadius = radius * 0.85; // Position text

    for (var i = 0; i < zones.length; i++) {
        final label = zones[i]['label'] as String;
        
        textPainter.text = TextSpan(
            text: label,
            style: TextStyle(
                color: Colors.black.withOpacity(opacity),
                fontSize: 10,
                fontWeight: FontWeight.bold,
            ),
        );
        textPainter.layout();

        final x = labelRadius * math.cos(labelAngle);
        final y = labelRadius * math.sin(labelAngle);

        canvas.save();
        canvas.translate(x, y);
        // Rotate text to align with radius? Or keep upright? 
        // Screenshot shows text aligned with radius
        canvas.rotate(labelAngle + math.pi/2); 
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();

        labelAngle += sectorAngle;
    }
    
    // Restore canvas (stop rotating the dial)
    canvas.restore();

    // Draw Static Needle (Red line pointing Up) - If needed.
    // In the screenshot, there is a red line from center to top.
    // This indicates the device's heading relative to the dial.
    // Since the dial rotates to match North, the "Top" of the phone is the heading.
    // So we draw a static line at the top.
    
    final needlePaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
      
    // Line from center to almost top
    canvas.drawLine(Offset(center.dx, center.dy), Offset(center.dx, 20), needlePaint);
    
    // Also a small triangle at the top?
    // Let's just keep the line for now.
  }

  @override
  bool shouldRepaint(covariant SixteenZoneCompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.isMapMode != isMapMode;
  }
}
