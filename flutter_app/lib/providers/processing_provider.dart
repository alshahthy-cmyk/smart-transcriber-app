import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/audio_chunk.dart';
import '../core/services/ffmpeg_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../core/services/groq_api_service.dart';
import '../core/utils/arabic_text_processor.dart';
import '../core/utils/temp_file_manager.dart';
import 'file_provider.dart';
import 'settings_provider.dart';

final groqApiServiceProvider = Provider((ref) => GroqApiService());

final audioChunksProvider = StateNotifierProvider<AudioChunksNotifier, List<AudioChunk>>((ref) {
  return AudioChunksNotifier(ref);
});

final isSplittingProvider = StateProvider<bool>((ref) => false);
final isUploadingProvider = StateProvider<bool>((ref) => false);
final isPausedProvider = StateProvider<bool>((ref) => false);
final overallProgressProvider = StateProvider<double>((ref) => 0.0);

class AudioChunksNotifier extends StateNotifier<List<AudioChunk>> {
  final Ref ref;
  bool _cancelRequested = false;

  AudioChunksNotifier(this.ref) : super([]);

  Future<void> prepareAndSplit(File readyFile) async {
    ref.read(isSplittingProvider.notifier).state = true;
    
    int sizeBytes = readyFile.lengthSync();
    bool needsSplitting = sizeBytes > 24 * 1024 * 1024;
    
    if (needsSplitting) {
      final ffmpeg = ref.read(ffmpegServiceProvider);
      // A11: Data Optimization - Reduce max chunk to 300s (5m) instead of 10m to save RAM and Network Data in case of failure
      final chunksFiles = await ffmpeg.splitAudioFile(readyFile, segmentDurationSeconds: 300);
      
      final chunks = chunksFiles.asMap().entries.map((entry) {
        return AudioChunk(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + entry.key.toString(),
          file: entry.value,
          index: entry.key,
        );
      }).toList();
      
      state = chunks;
    } else {
      state = [
        AudioChunk(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          file: readyFile,
          index: 0,
        )
      ];
    }
    
    ref.read(isSplittingProvider.notifier).state = false;
  }

  Future<void> startUploadQueue() async {
    final settings = ref.read(settingsProvider);
    final apiKey = settings.apiKey;
    final isDemo = settings.isDemoMode;

    if (apiKey.isEmpty && !isDemo) {
      // Handle error gracefully in UI
      throw Exception('يرجى إدخال مفتاح API أو استخدام الوضع التجريبي');
    }

    _cancelRequested = false;
    ref.read(isUploadingProvider.notifier).state = true;
    ref.read(isPausedProvider.notifier).state = false;
    final apiService = ref.read(groqApiServiceProvider);
    
    final service = FlutterBackgroundService();
    service.startService();

    for (int i = 0; i < state.length; i++) {
      if (_cancelRequested) break;
      
      // Wait if paused
      while (ref.read(isPausedProvider)) {
        if (_cancelRequested) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (_cancelRequested) break;

      final chunk = state[i];
      if (chunk.state == ChunkUploadState.completed) continue;

      updateChunkState(chunk.id, ChunkUploadState.uploading, progress: 0);
      
      service.invoke('update', {
        'progress': ref.read(overallProgressProvider),
        'status': 'جاري الرفع الجزء ${i + 1}'
      });

      try {
        final text = await apiService.transcribeAudio(
          audioFile: chunk.file,
          apiKey: apiKey,
          isDemoMode: isDemo,
          onProgress: (p) {
             if (_cancelRequested || ref.read(isPausedProvider)) return; // Dio cancel token would be better, but we mock it simply here
             updateChunkState(chunk.id, ChunkUploadState.uploading, progress: p);
             _calculateOverallProgress();
             
             service.invoke('update', {
               'progress': ref.read(overallProgressProvider),
               'status': 'جاري الرفع الجزء ${i + 1}'
             });
          },
        );

        if (_cancelRequested) break;

        final enhancedText = ArabicTextProcessor.enhanceText(text);

        updateChunkState(chunk.id, ChunkUploadState.completed, progress: 1.0, text: enhancedText);
        _calculateOverallProgress();
        
        // Wait a bit to respect rate limits if there are more chunks
        if (i < state.length - 1) {
          await Future.delayed(const Duration(seconds: 2));
        }

      } catch (e) {
        if (_cancelRequested) break;
        updateChunkState(chunk.id, ChunkUploadState.failed, error: e.toString());
        ref.read(isUploadingProvider.notifier).state = false; // Stop queue on hard failure
        service.invoke('stopService');
        break;
      }
    }
    
    // Check if fully complete
    if (state.every((c) => c.state == ChunkUploadState.completed)) {
      ref.read(isUploadingProvider.notifier).state = false;
      service.invoke('complete');
      
      // Cleanup temp chunks from disk after success
      try {
        final chunksToClean = state.map((c) => c.file).toList();
        await TempFileManager.cleanupChunks(chunksToClean);
        
        // Cache the final results
        final originalFile = ref.read(selectedFileProvider);
        if (originalFile != null) {
           final fullText = state.map((c) => c.transcribedText ?? '').join('\n\n');
           final fileName = originalFile.path.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
           await TempFileManager.cacheTranscript(fileName, fullText);
        }
      } catch (e) {
        // ignore cleanup errors
      }
    } else if (_cancelRequested) {
      service.invoke('stopService');
    }
  }

  void pauseUpload() {
    ref.read(isPausedProvider.notifier).state = true;
  }

  void resumeUpload() {
    ref.read(isPausedProvider.notifier).state = false;
  }

  void stopUpload() {
     _cancelRequested = true;
     ref.read(isUploadingProvider.notifier).state = false;
     ref.read(isPausedProvider.notifier).state = false;
     
     final service = FlutterBackgroundService();
     service.invoke('stopService');
  }

  void _calculateOverallProgress() {
    if (state.isEmpty) {
      ref.read(overallProgressProvider.notifier).state = 0.0;
      return;
    }
    double totalProgress = 0;
    for (var chunk in state) {
      totalProgress += chunk.progress;
    }
    ref.read(overallProgressProvider.notifier).state = totalProgress / state.length;
  }

  void updateChunkState(String id, ChunkUploadState newState, {double? progress, String? text, String? error}) {
    state = state.map((chunk) {
      if (chunk.id == id) {
        return chunk.copyWith(
          state: newState,
          progress: progress ?? chunk.progress, // Preserve progress if null
          transcribedText: text,
          errorMessage: error,
        );
      }
      return chunk;
    }).toList();
  }

  void clear() {
    state = [];
    ref.read(overallProgressProvider.notifier).state = 0.0;
  }
}
