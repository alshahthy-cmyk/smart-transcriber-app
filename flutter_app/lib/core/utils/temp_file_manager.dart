import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TempFileManager {
  static Future<void> clearOldTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;

      final files = tempDir.listSync();
      final now = DateTime.now();

      for (var file in files) {
        if (file is File) {
          // Identify cache files (audio chunks, transcodes, pdf text exports)
          final path = file.path.toLowerCase();
          if (path.contains('.mp4') || path.contains('.mp3') || path.contains('.wav') ||
              path.contains('.pdf') || path.contains('.txt') || path.contains('chunk')) {
            try {
              final stat = file.statSync();
              // Delete files older than 6 hours to save storage & improve RAM/Device performance mapping
              if (now.difference(stat.modified).inHours > 6) {
                file.deleteSync();
              }
            } catch (e) {
               // ignore locked files
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  static Future<void> cleanupChunks(List<File> chunks) async {
    for (var chunk in chunks) {
      try {
        if (chunk.existsSync()) {
          chunk.deleteSync();
        }
      } catch (e) {
        // ignore
      }
    }
  }

  // Phase A11: Data Optimization - Cache final transcript
  static Future<void> cacheTranscript(String fileName, String text) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cache_$fileName.txt');
      await file.writeAsString(text);
    } catch(e) {
      // ignore
    }
  }

  static Future<String?> getCachedTranscript(String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cache_$fileName.txt');
      if (file.existsSync()) {
        return await file.readAsString();
      }
    } catch(e) {
      // ignore
    }
    return null;
  }
}

