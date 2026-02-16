import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final Color? color;
  final Gradient? gradient;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 56.0,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        width: width,
        height: height,
        borderRadius: 30,
        opacity: 0.9,
        gradient: gradient ??
            LinearGradient(
              colors: [
                (color ?? Theme.of(context).primaryColor).withOpacity(0.9),
                (color ?? Theme.of(context).primaryColor).withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
        child: Center(child: child),
      ),
    );
  }
}
