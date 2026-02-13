import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../domain/entities/live_class.dart';

class LiveClassBanner extends StatelessWidget {
  final LiveClass liveClass;

  const LiveClassBanner({super.key, required this.liveClass});

  @override
  Widget build(BuildContext context) {
    final isLive = liveClass.status == 'LIVE';

    return GestureDetector(
      onTap: () {
        context.push(RouteConstants.courseDetailsPath(liveClass.courseId));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isLive ? "LIVE NOW" : "TODAY",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (liveClass.startsIn > 0 && !isLive)
                  Text(
                    "Starts in ${liveClass.startsIn} min",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              liveClass.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              liveClass.courseName,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: liveClass.canJoin && liveClass.meetingUrl != null
                    ? () {
                        final uri = Uri.parse(liveClass.meetingUrl!);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white38,
                ),
                child: Text(
                  isLive
                      ? "Join Class"
                      : "Scheduled @ ${_formatTime(liveClass.scheduledAt)}",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour > 12
        ? localDt.hour - 12
        : (localDt.hour == 0 ? 12 : localDt.hour);
    final minute = localDt.minute.toString().padLeft(2, '0');
    final period = localDt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }
}
