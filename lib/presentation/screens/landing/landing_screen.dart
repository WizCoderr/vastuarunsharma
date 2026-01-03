import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart'; // your theme file

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<String> images = [
    'assets/images/slide1.png',
    'assets/images/slide2.png',
    'assets/images/slide3.png',
  ];

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_controller.positions.isEmpty) return;
      _index = (_index + 1) % images.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Image Slider Section
            // Image Slider Section
            SizedBox(
              height: 400,
              width: MediaQuery.of(context).size.width,
              child: PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  return Center(
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width *
                          0.80, // responsive width
                      height:
                          MediaQuery.of(context).size.height *
                          0.32, // enough room for 1:1 fitting
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          18.0,
                        ), // spacing inside so image isn't stuck
                        child: Center(
                          child: AspectRatio(
                            aspectRatio:
                                1, // ensures perfect scaling for 1000x1000 images
                            child: Image.asset(
                              images[i],
                              fit: BoxFit.fill, // prevents crop, clean fit
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 10,
                  width: _index == i ? 14 : 10,
                  decoration: BoxDecoration(
                    color: _index == i ? Colors.black : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // Text Section
            Text(
              "Take Vastu Courses",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "From cooking to coding and\neverything in between",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),

            const Spacer(),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => context.push(RouteConstants.courses),
                    child: const Text(
                      "Browse Courses",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go(RouteConstants.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
