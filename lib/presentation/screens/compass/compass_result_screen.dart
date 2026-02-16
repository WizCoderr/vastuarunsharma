import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/glass_container.dart';

class CompassResultScreen extends StatelessWidget {
  final String imagePath;

  const CompassResultScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 16),
          label: const Text(
            "Back",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassContainer(
                borderRadius: 16,
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imagePath.isNotEmpty
                      ? Image.file(File(imagePath), fit: BoxFit.contain)
                      : const Center(child: Text("No image captured")),
                ),
              ),
            ),
          ),

          // Warning/Promo Section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    children: [
                      const TextSpan(text: "Shared the captured diagram with "),
                      TextSpan(
                        text: "Arun Sharma",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Get 100% accurate Vastu Analysis Report",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.keyboard_arrow_down, color: Colors.amber),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildGoldenActionButton(
                  context,
                  label: "SHARE",
                  icon: Icons.share_outlined,
                  onTap: () {
                    if (imagePath.isNotEmpty) {
                      Share.shareXFiles([
                        XFile(imagePath),
                      ], text: 'Check out my Vastu Compass Capture!');
                    }
                  },
                ),
                const SizedBox(width: 12),
                _buildGoldenActionButton(
                  context,
                  label: "CLICK\nHERE",
                  icon: Icons.touch_app_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildGoldenActionButton(
                  context,
                  label: "DOWNLOAD",
                  icon: Icons.download_outlined,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Image saved to gallery")),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bottom Link
          GestureDetector(
            onTap: () {
              // Navigate to report or relevant action
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Get 100% accurate Vastu Analysis Report",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Icon(Icons.keyboard_arrow_down, color: Colors.amber),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGoldenActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          height: 100, // Fixed height for square look
          borderRadius: 16,
          // Use a custom gradient that mimics the gold color but with glass transparency
          gradient: LinearGradient(
            colors: [
              const Color(0xFFD7A417).withOpacity(0.9),
              const Color(0xFFD7A417).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
