import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompassDial extends StatelessWidget {
  final double heading;
  final bool isMapMode;
  final String? imagePath;

  const CompassDial({
    super.key,
    required this.heading,
    this.isMapMode = false,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The Compass Visual
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imagePath != null
                  ? Transform.rotate(
                      angle: -heading * (math.pi / 180),
                      child: Image.asset(
                        imagePath!,
                        fit: BoxFit.contain,
                        opacity: isMapMode
                            ? const AlwaysStoppedAnimation(0.6)
                            : const AlwaysStoppedAnimation(1.0),
                      ),
                    )
                  : CustomPaint(
                      painter: CompassPainter(
                        heading: heading,
                        isMapMode: isMapMode,
                      ),
                    ),
              // Red Indicator Needle (Lubber Line) for Image Mode
              if (imagePath != null)
                Center(
                  child: Container(
                    width: 2,
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.red,
                          Colors.red.withOpacity(0.5),
                          Colors.red,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Center Book Icon (Overlay) - Keep this for both modes?
        // The 32-zone compass screenshot shows a different center (AppliedVastu logo).
        // But for likely consistency or if the image doesn't have a center, we might want to keep it or make it optional.
        // Looking at the screenshot, the center has "AppliedVastu.com" text/logo which rotates with the dial.
        // So we should probably NOT show the static center icon if using an image, OR the image has it built-in.
        // The user request says "make this screen edit", creating a new screen.
        // The screenshot shows a needle (red line).
        // I should probably add a needle overlay if using an image, or assumes the image rotates.
        // Wait, if the image rotates, we need a static marker at the top to indicate "North" relative to the phone,
        // OR the image rotates so North matches magnetic North.
        // In the screenshot, there is a "355 Degree" text at the top and a small triangle pointing down.
        // The dial itself seems to be the image.
        // The red line in the screenshot seems to be part of the UI overlay (static) or part of the rotating image?
        // Actually, in a compass app, usually the dial rotates so that "N" on the dial points to actual North.
        // The needle is usually fixed pointing UP (phone heading) or the needle rotates.
        // In `CompassDial`, we are rotating the dial `-heading`. This means the dial matches the real world.
        // So checking the screenshot: The red line goes from top to bottom. It looks like a static needle indicator.
        // The current `CompassDial` has a "Center Book Icon" and "Ether" text.
        // I will hide the default center overlays if `imagePath` is provided, assuming the image contains necessary details or we add specific overlays for it later.
        if (imagePath == null) ...[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isMapMode ? Colors.white.withOpacity(0.6) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isMapMode ? 0.1 : 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.location_on,
                size: 32,
                color: isMapMode ? Colors.red.withOpacity(0.7) : Colors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CompassPainter extends CustomPainter {
  final double heading;
  final bool isMapMode;

  CompassPainter({required this.heading, this.isMapMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = isMapMode ? 0.6 : 1.0;

    // Save canvas to rotate
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * (math.pi / 180));

    // Draw Sections (Vastu Elements)
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    double toRad(double deg) => deg * (math.pi / 180);
    // Convert azimuth to canvas angle (subtract 90 degrees)
    double startAngle(double azimuth) => toRad(azimuth - 90);
    double sweepAngle(double degrees) => toRad(degrees);

    // 1. Water (326.25 to 56.25) - Blue
    // Span: 360-326.25 = 33.75. 33.75 + 56.25 = 90 degrees.
    paint.color = const Color(0xFF2196F3).withOpacity(opacity); // Material Blue
    canvas.drawArc(rect, startAngle(326.25), sweepAngle(90), true, paint);

    // 2. Air (56.25 to 123.75) - Green
    // Span: 123.75 - 56.25 = 67.5 degrees
    paint.color = const Color(0xFF4CAF50).withOpacity(opacity); // Material Green
    canvas.drawArc(rect, startAngle(56.25), sweepAngle(67.5), true, paint);

    // 3. Fire (123.75 to 191.25) - Red
    // Span: 191.25 - 123.75 = 67.5 degrees
    paint.color = const Color(0xFFF44336).withOpacity(opacity); // Material Red
    canvas.drawArc(rect, startAngle(123.75), sweepAngle(67.5), true, paint);

    // 4. Earth (191.25 to 236.25) - Yellow
    // Span: 236.25 - 191.25 = 45 degrees
    paint.color = const Color(0xFFFFEB3B).withOpacity(opacity); // Material Yellow
    canvas.drawArc(rect, startAngle(191.25), sweepAngle(45), true, paint);

    // 5. Space (236.25 to 326.25) - Grey/White
    // Span: 326.25 - 236.25 = 90 degrees
    paint.color = const Color(0xFF9E9E9E).withOpacity(opacity); // Material Grey
    canvas.drawArc(rect, startAngle(236.25), sweepAngle(90), true, paint);

    // Inner white circle to create the ring effect
    paint.color = Colors.white.withOpacity(isMapMode ? 0.4 : 1.0);
    canvas.drawCircle(Offset.zero, radius * 0.75, paint);

    // Draw Directions Text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    void drawDirection(String text, double angle) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black.withOpacity(opacity),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final r = radius * 0.85; // text radius
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + math.pi / 2); // Text follows curve
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    // Draw Element Labels
    void drawElement(String text, double azimuthOfCenter) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black.withOpacity(opacity),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final angle = startAngle(azimuthOfCenter);
      final r = radius * 0.60; // Inner label radius
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);

      canvas.save();
      canvas.translate(x, y);
      // Align text with radius
      canvas.rotate(angle + math.pi / 2); 
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    drawDirection("N", -math.pi / 2); 
    drawDirection("E", 0); 
    drawDirection("S", math.pi / 2); 
    drawDirection("W", math.pi); 

    // Draw Elements on Ring using Azimuth Centers
    // Water (326.25 to 56.25). 326.25 is -33.75. Center = 11.25
    drawElement("Water", 11.25);
    // Air (56.25 to 123.75). Center = 90
    drawElement("Air", 90);
    // Fire (123.75 to 191.25). Center = 157.5
    drawElement("Fire", 157.5);
    // Earth (191.25 to 236.25). Center = 213.75
    drawElement("Earth", 213.75);
    // Space (236.25 to 326.25). Center = 281.25
    drawElement("Space", 281.25);

    // Draw Needle (The Star/Cross shape)
    final needlePaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final needleLen = radius * 0.7;
    final needleWidth = 15.0;

    // North Needle (Red/Dark Red)
    needlePaint.color = const Color(0xFF8B0000).withOpacity(opacity);
    Path northPath = Path();
    northPath.moveTo(0, -needleLen);
    northPath.lineTo(needleWidth, 0);
    northPath.lineTo(-needleWidth, 0);
    northPath.close();
    canvas.drawPath(northPath, needlePaint);

    // South Needle (Dark Blue)
    needlePaint.color = const Color(0xFF0D1B2A).withOpacity(opacity);
    Path southPath = Path();
    southPath.moveTo(0, needleLen);
    southPath.lineTo(needleWidth, 0);
    southPath.lineTo(-needleWidth, 0);
    southPath.close();
    canvas.drawPath(southPath, needlePaint);

    // East Needle (Dark Blue)
    needlePaint.color = const Color(0xFF0D1B2A).withOpacity(opacity);
    Path eastPath = Path();
    eastPath.moveTo(needleLen, 0);
    eastPath.lineTo(0, -needleWidth);
    eastPath.lineTo(0, needleWidth);
    eastPath.close();
    canvas.drawPath(eastPath, needlePaint);

    // West Needle (Dark Blue)
    needlePaint.color = const Color(0xFF0D1B2A).withOpacity(opacity);
    Path westPath = Path();
    westPath.moveTo(-needleLen, 0);
    westPath.lineTo(0, -needleWidth);
    westPath.lineTo(0, needleWidth);
    westPath.close();
    canvas.drawPath(westPath, needlePaint);

    // Center "Ether" Circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset.zero, 25, paint); // White background
    
    // "Ether" Text
    textPainter.text = TextSpan(
      text: "Ether",
      style: TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    // Small Red Triangle/Pointer at center for aesthetics
     paint.color = Colors.red;
     Path centerPointer = Path();
     centerPointer.moveTo(0, 15);
     centerPointer.lineTo(8, 25);
     centerPointer.lineTo(-8, 25);
     centerPointer.close();
     canvas.drawPath(centerPointer, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.isMapMode != isMapMode;
  }
}
