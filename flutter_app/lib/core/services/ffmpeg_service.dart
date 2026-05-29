import 'dart:io';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/return_code.dart';
import 'package:path_provider/path_provider.dart';

class FFmpegService {

  Future<int> _getDurationMs(String path) async {
    try {
      final info = await FFprobeKit.getMediaInformation(path);
      final mediaInfo = info.getMediaInformation();
      if (mediaInfo != null && mediaInfo.getDuration() != null) {
        return (double.parse(mediaInfo.getDuration()!) * 1000).toInt();
      }
    } catch (e) {
      // Ignored
    }
    return 0;
  }

  /// Processes audio/video for AI Transcription
  /// - Extracts audio if it's video (-vn)
  /// - Converts to WAV (-acodec pcm_s16le)
  /// - 16kHz sample rate (-ar 16000)
  /// - Mono channel (-ac 1)
  /// - Enhances Arabic speech by applying noise reduction and normalization filters
  Future<File?> preprocessMedia(File inputFile, {required bool isVideo, Function(double)? onProgress}) async {
    try {
      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPath = '${directory.path}/processed_$timestamp.wav';

      int durationMs = await _getDurationMs(inputFile.path);

      // Filters for Arabic speech enhancement & noise reduction:
      // 1. highpass/lowpass: Removes low rumble and high hiss not present in human voice
      // 2. dynaudnorm: Dynamic Audio Normalizer to level out volume variations
      final String audioFilters = "highpass=f=200,lowpass=f=3000,dynaudnorm";

      final String command = '-i "${inputFile.path}" -vn -acodec pcm_s16le -ar 16000 -ac 1 -af "$audioFilters" "$outputPath"';

      final session = await FFmpegKit.executeAsync(
        command,
        (session) async {
          // Completed execution callback
        },
        (log) {
          // Log callback
        },
        (statistics) {
          if (durationMs > 0 && onProgress != null) {
            double progress = (statistics.getTime() / durationMs).clamp(0.0, 1.0);
            onProgress(progress * 100);
          }
        },
      );

      await session.getReturnCode();
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return File(outputPath);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<File>> splitAudioFile(File audioFile, {int segmentDurationSeconds = 600}) async {
    try {
      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String outputPattern = '${directory.path}/chunk_${timestamp}_%03d.wav';

      // Splitting the audio using segment format
      final String command = '-i "${audioFile.path}" -f segment -segment_time $segmentDurationSeconds -c copy "$outputPattern"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Collect output files
        List<File> chunks = [];
        int index = 0;
        while (true) {
          final String chunkPath = '${directory.path}/chunk_${timestamp}_${index.toString().padLeft(3, '0')}.wav';
          final File chunkFile = File(chunkPath);
          if (await chunkFile.exists()) {
            chunks.add(chunkFile);
            index++;
          } else {
            break; // No more chunks
          }
        }
        return chunks;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
