import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _downloadPdf() async {
    // Request storage permission
    // For Android 13+ (SDK 33+), READ_EXTERNAL_STORAGE is deprecated for media, but for documents we might rely on SAF or just public directories.
    // However, managing_external_storage is too broad.
    // Let's try basic getExternalStorageDirectory (which is app-specific and doesn't need runtime permission usually)
    // OR Request permission for public downloads.

    // Simplest approach for now: App Document Directory or External App Storage (Android ~ /Android/data/com.app/files)
    // If the user wants "Downloads" folder public visibility, it requires more complex permission handling on Android 10+.
    // Let's stick to Application Documents for now to ensure it works reliable without complex permissions first,
    // BUT user usually expects "Downloads".
    // Let's try getting the "Downloads" directory.

    if (Platform.isAndroid) {
      /*
       // Android 13+ doesn't explicitly need permission to write to public Download folder via MediaStore or SAF, 
       // but direct styling via File API might be restricted. 
       // We'll try the safe "External Storage" permission flow for older androids.
       */
      final status = await Permission.storage.request();
      if (!status.isGranted &&
          !await Permission.manageExternalStorage.isGranted) {
        // Try to proceed anyway if it's strictly about app-specific storage or if status is just confusing on newer Android
        // checking specific Android 13 permissions might be needed: Permission.photos, etc. but this is PDF.
        // Let's just try to download to temporary folder first if permission fails, or just show error.

        // On Android 13, storage permission is often always "denied" for generic storage.
        // Let's skip permission check for now to rely on scoped storage or just try/catch the write.
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          "${widget.title.replaceAll(RegExp(r'[^\w\s]+'), '')}.pdf";
      final savePath = "${dir?.path ?? ''}/$fileName";

      await Dio().download(
        widget.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloaded to $savePath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isDownloading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: _downloadProgress,
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
            ),
        ],
      ),
      body: const PDF().cachedFromUrl(
        widget.url,
        placeholder: (progress) => Center(child: Text('$progress %')),
        errorWidget: (error) => Center(child: Text(error.toString())),
      ),
    );
  }
}
