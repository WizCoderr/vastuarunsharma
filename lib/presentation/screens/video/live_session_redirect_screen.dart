import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/live_class.dart';

class LiveSessionRedirectScreen extends StatelessWidget {
  final LiveClass liveClass;

  const LiveSessionRedirectScreen({super.key, required this.liveClass});

  @override
  Widget build(BuildContext context) {
    final isLive = liveClass.status == 'LIVE';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Live Session',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLive ? Icons.sensors : Icons.event,
              size: 80,
              color: isLive ? Colors.red : Colors.white70,
            ),
            const SizedBox(height: 32),
            Text(
              isLive ? 'Live Class is in Progress!' : 'Upcoming Live Class',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              liveClass.title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat(
                'EEEE, MMM d, y • h:mm a',
              ).format(liveClass.scheduledAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (liveClass.description.isNotEmpty)
              Text(
                liveClass.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            const SizedBox(height: 48),
            if (liveClass.meetingUrl != null &&
                liveClass.meetingUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(liveClass.meetingUrl!);
                    try {
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not launch ${liveClass.meetingUrl}',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Error launching URL: $e');
                    }
                  },
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join Live Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLive ? Colors.red : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (liveClass.meetingUrl == null || liveClass.meetingUrl!.isEmpty)
              const Text(
                'Meeting link is not available yet.',
                style: TextStyle(color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }
}
