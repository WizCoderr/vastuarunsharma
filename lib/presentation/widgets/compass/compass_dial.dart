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
                          heading: heading, isMapMode: isMapMode),
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
          Positioned(
            top: 135,
            child: Text(
              "Ether",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isMapMode ? Colors.black.withOpacity(0.6) : Colors.black,
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

    // Draw Sections (Approximate colors from image)
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    // North (Water - Blue)
    paint.color = const Color(0xFF0077BE).withOpacity(opacity);
    canvas.drawArc(rect, -math.pi / 4, math.pi / 2, true, paint);

    // East (Fire - Red)
    paint.color = const Color(0xFFE53935).withOpacity(opacity);
    canvas.drawArc(rect, math.pi / 4, math.pi / 2, true, paint);

    // South (Earth - Yellow)
    paint.color = const Color(0xFFFFEB3B).withOpacity(opacity);
    canvas.drawArc(rect, 3 * math.pi / 4, math.pi / 2, true, paint);

    // West (Air - Grey/White)
    paint.color = const Color(0xFFB0BEC5).withOpacity(opacity);
    canvas.drawArc(rect, 5 * math.pi / 4, math.pi / 2, true, paint);

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
    void drawElement(String text, double angle) {
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

    drawDirection("N", -math.pi / 2); // North
    drawDirection("E", 0); // East
    drawDirection("S", math.pi / 2); // South
    drawDirection("W", math.pi); // West

    // Draw Elements on Ring
    // North = Water
    drawElement("Water", -math.pi / 4);
    // East = Fire
    drawElement("Fire", math.pi / 4);
    // South = Earth
    drawElement("Earth", 3 * math.pi / 4);
    // West = Air
    drawElement("Air", 5 * math.pi / 4);

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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.isMapMode != isMapMode;
  }
}
