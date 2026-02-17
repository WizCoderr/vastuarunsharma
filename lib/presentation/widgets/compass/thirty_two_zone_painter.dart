import 'dart:math' as math;
import 'package:flutter/material.dart';

class ThirtyTwoZonePainter extends CustomPainter {
  final double heading;
  final bool isMapMode;

  ThirtyTwoZonePainter({required this.heading, this.isMapMode = false});
  
  static final List<VastuZone> zones = [
    VastuZone("N5", "BHALLAT", "SOLUTIONS", const Color(0xFF42A5F5), 0), // Blue
    VastuZone("N6", "SOMA", "HEALTH & IMMUNITY", const Color(0xFF42A5F5), 11.25), // Blue
    VastuZone("N7", "BHUJAG", "IMMUNITY", const Color(0xFF42A5F5), 22.5), // Blue
    VastuZone("N8", "ADITI", "MIND CLARITY", const Color(0xFF42A5F5), 33.75), // Blue
    VastuZone("E1", "DITI", "VISION", const Color(0xFF42A5F5), 45), // Blue
    VastuZone("E2", "SHIKHI", "FOCUS", const Color(0xFF42A5F5), 56.25), // Blue
    VastuZone("E3", "PARJANYA", "FERTILITY", const Color(0xFF66BB6A), 67.5), // Green
    VastuZone("E4", "BHRISHA", "THINKING", const Color(0xFF66BB6A), 78.75), // Green
    VastuZone("E5", "AAKASH", "MANIFESTATION", const Color(0xFF66BB6A), 90), // Green
    VastuZone("E6", "ANIL", "UPLIFTMENT", const Color(0xFF66BB6A), 101.25), // Green
    VastuZone("E7", "PUSHA", "STRENGTH", const Color(0xFF66BB6A), 112.5), // Green
    VastuZone("E8", "VITATHA", "PRETENSE", const Color(0xFF66BB6A), 123.75), // Green
        VastuZone("S1", "GRIHAKSHAT", "BINDING", const Color(0xFF66BB6A), 135), // Green
    VastuZone("S2", "YAMA", "ORDER", const Color(0xFF66BB6A), 146.25), // Green
    VastuZone("S3", "GANDHARV", "MUSIC/ART", const Color(0xFFEF5350), 157.5), // Red
    VastuZone("S4", "BHRINGRAJ", "EXPENDITURE", const Color(0xFFEF5350), 168.75), // Red
    VastuZone("S5", "MRIGAH", "CURIOSITY", const Color(0xFFEF5350), 180), // Red
    VastuZone("S6", "PITRA", "ANCESTORS", const Color(0xFFFBC02D), 191.25), // Yellow
    VastuZone("S7", "DAUWARIKA", "KNOWLEDGE", const Color(0xFFFBC02D), 202.5), // Yellow
    VastuZone("S8", "SUGREEV", "VIDYA", const Color(0xFFFBC02D), 213.75), // Yellow
    VastuZone("W1", "PUSHPADANT", "ASSISTANCE", const Color(0xFFFBC02D), 225), // Yellow
    VastuZone("W2", "VARUN", "OBLIVION", const Color(0xFFFBC02D), 236.25), // Yellow
    VastuZone("W3", "ASUR", "ILLUSION", const Color(0xFFECEFF1), 247.5), // Light Grey
    VastuZone("W4", "SOSHA", "GRIEF", const Color(0xFFECEFF1), 258.75), // Light Grey
    VastuZone("W5", "PAPAYAKSHMA", "DISEASE", const Color(0xFFECEFF1), 270), // Light Grey
    VastuZone("W6", "ROGA", "SUPPORT", const Color(0xFFECEFF1), 281.25), // Light Grey
    VastuZone("W7", "NAGA", "CRAVING", const Color(0xFFECEFF1), 292.5), // Light Grey
    VastuZone("W8", "MUKHYA", "CARE", const Color(0xFFECEFF1), 303.75), // Light Grey
    
    // North End (N1, N2 also Space/Water transition)
    VastuZone("N1", "BHALLAT", "ABUNDANCE", const Color(0xFFECEFF1), 315), // Light Grey (Space)
    VastuZone("N2", "SOMA", "TREASURE", const Color(0xFFECEFF1), 326.25), // Light Grey (Space)
    
    // N3, N4: Water (Blue)
    VastuZone("N3", "BHUJAG", "MEDICINE", const Color(0xFF42A5F5), 337.5), // Blue
    VastuZone("N4", "ADITI", "PROTECTION", const Color(0xFF42A5F5), 348.75), // Blue
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    // Anti-alias for smooth edges
    final paint = Paint()..isAntiAlias = true..style = PaintingStyle.fill;
    
    // Canvas rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * (math.pi / 180));

    // 1. Draw Background White
    paint.color = Colors.white;
    canvas.drawCircle(Offset.zero, radius, paint);

    final double zoneToRad = (360 / 32) * (math.pi / 180);
    final Rect fullRect = Rect.fromCircle(center: Offset.zero, radius: radius);

    // 2. Draw Colored Pie Slices (The main colors)
    for (int i = 0; i < zones.length; i++) {
      final zone = zones[i];
      final double startAngle = (zone.angle - 5.625) * (math.pi / 180) - (math.pi / 2);
      
      // Use solid opaque color to ensure visibility
      paint.color = zone.color; 
      canvas.drawArc(fullRect, startAngle, zoneToRad, true, paint);
    }
    
    // 3. Draw Overlay Circles to create Rings (Masking)
    
    // A. Outer White Ring (For Attributes)
    // Mask the outer edge to be white
    // Don't mask, just draw a white annulus?? No, that's hard.
    // Instead, draw a White Circle that covers everything, but that's wrong (we want inner to show).
    // Better: Draw the pie slices as they are (full).
    // THEN draw a Semi-Transparent White circle over the Outer part?
    // OR just draw distinct rings.
    
    // Let's use concentric circles to overwrite the centers for the "Ring" look.
    
    // Radii
    double rAttribute = radius * 0.85; 
    double rCode = radius * 0.70;
    // double rDeity = radius * 0.55; 
    double rCenter = radius * 0.25;
    
    // 3.1 Mask for Code Ring (Paint it transparent white/tint over the pie slices?)
    // Actually, the user wants:
    // Outer Ring: White (Attributes)
    // Middle Ring: Tinted (Codes)
    // Inner Ring: Full Color (Deities)
    
    // So:
    // a) Draw White Circle covering everything from rAttribute outwards?
    //    No, we want the pie slices to potentially show through or just be white.
    //    Let's Overwrite Outer Ring with White.
    
    // Draw Donut: White Ring from rAttribute to Edge
    // We can do this by drawing a thick stroke circle?
    // Center at radius * 0.925, width radius * 0.15
    final Paint whiteRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius - rAttribute);
      
    canvas.drawCircle(Offset.zero, rAttribute + (radius - rAttribute)/2, whiteRingPaint);
    final Paint lightOverlayPaint = Paint()
      ..color = Colors.white.withOpacity(0.7) // Lighten the color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (rAttribute - rCode);
      
    canvas.drawCircle(Offset.zero, rCode + (rAttribute - rCode)/2, lightOverlayPaint);
    
    // c) Deity Ring (rCenter to rCode)
    // Leave as full color (already drawn).
    
    // d) Center Hole (Yellow Brahma Sthan)
    paint.color = const Color(0xFFFFD600); // Bright Yellow
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, rCenter, paint);
    
    // 4. Draw Separator Lines (Black)
    final linePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    for (int i = 0; i < zones.length; i++) {
       final double startAngle = (zones[i].angle - 5.625) * (math.pi / 180) - (math.pi / 2);
       final lineX = radius * math.cos(startAngle);
       final lineY = radius * math.sin(startAngle);
       canvas.drawLine(Offset.zero, Offset(lineX, lineY), linePaint);
    }
    
    // 5. Draw Borders
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    canvas.drawCircle(Offset.zero, radius, borderPaint);
    canvas.drawCircle(Offset.zero, rAttribute, borderPaint);
    canvas.drawCircle(Offset.zero, rCode, borderPaint);
    canvas.drawCircle(Offset.zero, rCenter, borderPaint..strokeWidth=2.5); // Thicker center boundary
    
    // 6. Draw Texts
    for (int i = 0; i < zones.length; i++) {
       final zone = zones[i];
       final double startAngle = (zone.angle - 5.625) * (math.pi / 180) - (math.pi / 2);
       final double centerAngle = startAngle + zoneToRad / 2;
              _drawRotatedText(canvas, zone.deity, centerAngle, (rCenter + rCode)/2, 
           fontSize: 7, fontWeight: FontWeight.bold);
           
       _drawRotatedText(canvas, zone.code, centerAngle, (rCode + rAttribute)/2, 
           fontSize: 9, fontWeight: FontWeight.w900);
           
       
        if (zone.attribute.isNotEmpty) {
           _drawRotatedText(canvas, zone.attribute, centerAngle, (rAttribute + radius)/2, 
             fontSize: 6, fontWeight: FontWeight.w600, maxLines: 2);
        }
    }
    
    // 7. Center Text
    _drawCenterText(canvas, "BRAHMA\nSTHAN"); 
    
    // 8. Degree Scale & Directions
    _drawDegreeScale(canvas, radius);
    _drawDirections(canvas, radius * 0.92);

    canvas.restore();
    
    // Static Needle pointing UP (Red Triangle)
    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy - radius + 10);
    needlePath.lineTo(center.dx - 8, center.dy - radius - 15);
    needlePath.lineTo(center.dx + 8, center.dy - radius - 15);
    needlePath.close();
    
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
    canvas.drawPath(needlePath, paint);
  }

  void _drawRotatedText(Canvas canvas, String text, double angleRad, double r, {double fontSize = 10, FontWeight fontWeight = FontWeight.normal, Color color = Colors.black, int maxLines = 1}) {
    if (text.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: maxLines,
    );
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.0,
      ),
    );
    textPainter.layout(maxWidth: 55); 
    
    final x = r * math.cos(angleRad);
    final y = r * math.sin(angleRad);
    
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angleRad + math.pi / 2);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  void _drawCenterText(Canvas canvas, String text) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }

  void _drawDegreeScale(Canvas canvas, double radius) {
     final tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;
      
     // Basic Ticks
     for (int i=0; i<360; i+=10) {
        final angleRad = (i - 90) * (math.pi / 180);
        final p1 = Offset(radius * math.cos(angleRad), radius * math.sin(angleRad));
        final p2 = Offset((radius + 5) * math.cos(angleRad), (radius + 5) * math.sin(angleRad));
        canvas.drawLine(p1, p2, tickPaint);
     }
  }

  void _drawDirections(Canvas canvas, double radius) {
    final List<String> directions = [
      "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"
    ];
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    for (int i = 0; i < directions.length; i++) {
        final double angleDeg = i * 22.5;
        final double angleRad = (angleDeg - 90) * (math.pi / 180);
        
        textPainter.text = TextSpan(
            text: directions[i],
            style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
            )
        );
        textPainter.layout();
        
        // Place on the Directions Ring
        final x = radius * math.cos(angleRad);
        final y = radius * math.sin(angleRad);
        
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angleRad + math.pi/2);
        
        // Background capsule to make it readable over lines? 
        // Or just text.
        textPainter.paint(canvas, Offset(-textPainter.width/2, -textPainter.height/2));
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ThirtyTwoZonePainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.isMapMode != isMapMode;
  }
}

class VastuZone {
  final String code;
  final String deity;
  final String attribute;
  final Color color;
  final double angle;

  VastuZone(this.code, this.deity, this.attribute, this.color, this.angle);
}
