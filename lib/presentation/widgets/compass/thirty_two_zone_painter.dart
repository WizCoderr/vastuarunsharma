import 'dart:math' as math;
import 'package:flutter/material.dart';

class ThirtyTwoZonePainter extends CustomPainter {
  final double heading;
  final bool isMapMode;

  ThirtyTwoZonePainter({required this.heading, this.isMapMode = false});

  // 32 Zones Data
  // Starting from North (0 degrees) and going Clockwise?
  // Vastu zones are usually N1 to N8, E1 to E8, etc.
  // Standard Vastu Purush Mandala sequence clockwise from NE / N.
  // We will map 0 degrees to North (Soma/Bhallat area).
  // Each zone is 11.25 degrees.
  static final List<VastuZone> zones = [
    // North (N4, N5 is center North). 
    // Let's start from 0 degrees (North) which is usually the border of N4/N5 or center of N.
    // Assuming 0 is North center.
    // N4 (Bhallat) and N5 (Soma) share North.
    // 0 degrees is between N4 and N5? Or center of a generic "N"?
    // Let's use the sequence starting from 11.25/2 (offset) or just standard listing.
    
    // N1 to N8: North Quadrant
    // NE: Shikhi (approx 45 deg)
    // Let's list clockwise from Real North (0 deg).
    // Zones are 11.25 deg each.
    // 1. Soma (N5) - North
    // 2. Bhujag/Sarpa (N6) 
    // 3. Aditi (N7)
    // 4. Diti (N8)
    // 5. Shikhi (NE1) - NE
    // 6. Parjanya (NE2)
    // 7. Jayant (E1)
    // 8. Mahendra/Indra (E2)
    // 9. Surya (E3) - East
    // 10. Satya (E4)
    // 11. Bhrisha (E5)
    // 12. Antariksha (SE1)
    // 13. Anil (SE2)
    // 14. Pusha (SE3)
    // 15. Vitatha (S1)
    // 16. Grihakshta (S2)
    // 17. Yama (S3) - South
    // 18. Gandharva (S4)
    // 19. Bhringraj (S5)
    // 20. Mriga (S6)
    // 21. Pitra (SW1) - SW
    // 22. Dauvarik (SW2)
    // 23. Sugriva (W1)
    // 24. Pushpadanta (W2)
    // 25. Varuna (W3) - West
    // 26. Asura (W4)
    // 27. Shosha (W5)
    // 28. Papyakshma (NW1)
    // 29. Roga (NW2)
    // 30. Naga (NW3)
    // 31. Mukhya (N1)
    // 32. Bhallata (N2/N4?) - Wait, the counting is tricky.
    
    // Normalized list based on angles (Center of zone):
    // 0 deg: North.
    VastuZone("Soma", Colors.blue, 0),        // N5
    VastuZone("Bhujag", Colors.blue, 11.25),  // N6
    VastuZone("Aditi", Colors.blue, 22.5),    // N7
    VastuZone("Diti", Colors.blue, 33.75),    // N8
    VastuZone("Shikhi", Colors.orange, 45),   // NE1
    VastuZone("Parjanya", Colors.orange, 56.25), // NE2
    VastuZone("Jayant", Colors.green, 67.5),  // E1
    VastuZone("Indra", Colors.green, 78.75),  // E2
    VastuZone("Surya", Colors.green, 90),     // E3 (East)
    VastuZone("Satya", Colors.green, 101.25), // E4
    VastuZone("Bhrisha", Colors.green, 112.5), // E5
    VastuZone("Akash", Colors.redAccent, 123.75), // SE1
    VastuZone("Anil", Colors.red, 135),       // SE2
    VastuZone("Pusha", Colors.red, 146.25),   // SE3
    VastuZone("Vitatha", Colors.red, 157.5),  // S1
    VastuZone("Grihakst", Colors.red, 168.75), // S2 (Shortened from Grihakshta)
    VastuZone("Yama", Colors.redAccent, 180), // S3 (South)
    VastuZone("Gandhrv", Colors.redAccent, 191.25), // S4 (Shortened from Gandharva)
    VastuZone("Bhringrj", Colors.yellow, 202.5), // S5 (Shortened from Bhringraj)
    VastuZone("Mriga", Colors.yellow, 213.75), // S6
    VastuZone("Pitra", Colors.yellow, 225),   // SW1
    VastuZone("Dauvarik", Colors.yellow, 236.25), // SW2
    VastuZone("Sugriva", Colors.grey, 247.5), // W1
    VastuZone("Pushpdnt", Colors.grey, 258.75), // W2 (Pushpadanta shortened)
    VastuZone("Varuna", Colors.white, 270),   // W3 (West)
    VastuZone("Asura", Colors.white, 281.25), // W4
    VastuZone("Shosha", Colors.white, 292.5), // W5
    VastuZone("Yakshma", Colors.white, 303.75), // NW1 (Papyakshma)
    VastuZone("Roga", Colors.white, 315),     // NW2
    VastuZone("Naga", Colors.blueAccent, 326.25), // NW3
    VastuZone("Mukhya", Colors.blue, 337.5),  // N1
    VastuZone("Bhallata", Colors.blue, 348.75), // N2
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;
    
    // Save rotation
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * (math.pi / 180));

    // Draw Zones
    final double zoneToRad = (360 / 32) * (math.pi / 180); // 11.25 degrees in radians
    
    for (int i = 0; i < zones.length; i++) {
      final zone = zones[i];
      
      // Calculate start angle. 
      // zone.angle is the center. Start is center - half width.
      final double startAngle = (zone.angle - 5.625) * (math.pi / 180) - (math.pi / 2); // -90 to rotate 0 to Top (North)
      
      // Paint Slice
      paint.color = zone.color.withOpacity(isMapMode ? 0.6 : 1.0);
      final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      canvas.drawArc(rect, startAngle, zoneToRad, true, paint);

      // Draw Text with Staggered Radius
      // Stagger odd/even to avoid overlap in 11.25 degree slices
      final double textRadius = (i % 2 == 0) ? radius * 0.92 : radius * 0.78;
      
      _drawText(canvas, zone.name, zone.angle, textRadius);
    }
    
    // Inner Circle (Brahmasthan) - Reduce size slightly to accommodate inner text ring
    paint.color = Colors.white.withOpacity(isMapMode ? 0.8 : 1.0);
    canvas.drawCircle(Offset.zero, radius * 0.30, paint);
    
    // Center Text
    _drawCenterText(canvas, "Brahma\nSthan");

    canvas.restore();
  }
  
  void _drawText(Canvas canvas, String text, double angleDeg, double r) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    // Adjust angle to match canvas rotation (-90 offset for North at top)
    final double angleRad = (angleDeg - 90) * (math.pi / 180);
    
    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black.withOpacity(isMapMode ? 0.7 : 1.0),
        fontSize: 9, // Slightly smaller font
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    
    final x = r * math.cos(angleRad);
    final y = r * math.sin(angleRad);
    
    canvas.save();
    canvas.translate(x, y);
    // Rotate text to align with the slice ray
    canvas.rotate(angleRad + math.pi / 2);
    
    textPainter.paint(
      canvas, 
      Offset(-textPainter.width / 2, -textPainter.height / 2)
    );
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
        color: Colors.red.shade900,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(-textPainter.width / 2, -textPainter.height / 2)
    );
  }

  @override
  bool shouldRepaint(covariant ThirtyTwoZonePainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.isMapMode != isMapMode;
  }
}

class VastuZone {
  final String name;
  final Color color;
  final double angle; // Center angle in degrees (0 = North)

  VastuZone(this.name, this.color, this.angle);
}
