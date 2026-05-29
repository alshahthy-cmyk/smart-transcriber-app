import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/file_picker_service.dart';
import '../core/services/ffmpeg_service.dart';

// Service Providers
final filePickerServiceProvider = Provider((ref) => FilePickerService());
final ffmpegServiceProvider = Provider((ref) => FFmpegService());

// State Providers
final selectedFileProvider = StateProvider<File?>((ref) => null);
final originalFileProvider = StateProvider<File?>((ref) => null);
final isExtractingAudioProvider = StateProvider<bool>((ref) => false);
final extractionProgressProvider = StateProvider<double>((ref) => 0.0);
final fileSizeProvider = StateProvider<int>((ref) => 0);
final fileTypeProvider = StateProvider<String>((ref) => '');

class FileStateNotifier extends StateNotifier<void> {
  final Ref ref;

  FileStateNotifier(this.ref) : super(null);

  Future<void> pickAudio() async {
    final picker = ref.read(filePickerServiceProvider);
    final file = await picker.pickAudioFile();
    if (file != null) {
      await _processPickedFile(file, isVideo: false);
    }
  }

  Future<void> pickVideo() async {
    final picker = ref.read(filePickerServiceProvider);
    final file = await picker.pickVideoFile();
    if (file != null) {
      await _processPickedFile(file, isVideo: true);
    }
  }

  Future<void> _processPickedFile(File file, {required bool isVideo}) async {
    ref.read(originalFileProvider.notifier).state = file;
    ref.read(selectedFileProvider.notifier).state = file;
    _updateMetadata(file, isVideo ? 'Video (Processing...)' : 'Audio (Enhancing...)');

    ref.read(isExtractingAudioProvider.notifier).state = true;
    ref.read(extractionProgressProvider.notifier).state = 0.0;
    
    final ffmpeg = ref.read(ffmpegServiceProvider);
    final processedFile = await ffmpeg.preprocessMedia(
      file,
      isVideo: isVideo,
      onProgress: (progress) {
        ref.read(extractionProgressProvider.notifier).state = progress / 100.0;
      },
    );
    
    if (processedFile != null) {
      ref.read(selectedFileProvider.notifier).state = processedFile;
      _updateMetadata(processedFile, 'Processed Audio (WAV, 16kHz, Mono)');
    } else {
      // Fallback
      _updateMetadata(file, isVideo ? 'Video (Processing Failed)' : 'Audio (Enhancement Failed)');
    }
    
    ref.read(isExtractingAudioProvider.notifier).state = false;
    ref.read(extractionProgressProvider.notifier).state = 1.0;
  }
  
  void _updateMetadata(File file, String type) {
    try {
      final size = file.lengthSync();
      ref.read(fileSizeProvider.notifier).state = size;
      ref.read(fileTypeProvider.notifier).state = type;
    } catch (e) {
      // Ignored
    }
  }
  
  void clear() {
    ref.read(originalFileProvider.notifier).state = null;
    ref.read(selectedFileProvider.notifier).state = null;
    ref.read(fileSizeProvider.notifier).state = 0;
    ref.read(fileTypeProvider.notifier).state = '';
  }
}

final fileNotifierProvider = StateNotifierProvider<FileStateNotifier, void>((ref) => FileStateNotifier(ref));
