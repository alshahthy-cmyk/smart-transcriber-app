import 'dart:io';

enum ChunkUploadState {
  pending,
  uploading,
  completed,
  failed,
}

class AudioChunk {
  final String id;
  final File file;
  final int index;
  final ChunkUploadState state;
  final double progress;
  final String? transcribedText;
  final String? errorMessage;

  AudioChunk({
    required this.id,
    required this.file,
    required this.index,
    this.state = ChunkUploadState.pending,
    this.progress = 0.0,
    this.transcribedText,
    this.errorMessage,
  });

  AudioChunk copyWith({
    String? id,
    File? file,
    int? index,
    ChunkUploadState? state,
    double? progress,
    String? transcribedText,
    String? errorMessage,
  }) {
    return AudioChunk(
      id: id ?? this.id,
      file: file ?? this.file,
      index: index ?? this.index,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      transcribedText: transcribedText ?? this.transcribedText,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
