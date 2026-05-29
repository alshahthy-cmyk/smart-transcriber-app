import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../providers/processing_provider.dart';
import '../../core/models/audio_chunk.dart';
import '../screens/results_screen.dart';

class FileInfoCard extends ConsumerWidget {
  const FileInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFile = ref.watch(selectedFileProvider);
    final fileSize = ref.watch(fileSizeProvider);
    final fileType = ref.watch(fileTypeProvider);
    
    final isExtracting = ref.watch(isExtractingAudioProvider);
    final extractProgress = ref.watch(extractionProgressProvider);
    
    final isSplitting = ref.watch(isSplittingProvider);
    final isUploading = ref.watch(isUploadingProvider);
    final uploadProgress = ref.watch(overallProgressProvider);
    final isPaused = ref.watch(isPausedProvider);
    final audioChunks = ref.watch(audioChunksProvider);
    
    final isProcessing = isUploading;
    
    String fileName = selectedFile?.path.split('/').last ?? 'لم يتم اختيار ملف';
    String formattedSize = fileSize > 0 ? '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB' : '-- MB';
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('معلومات الملف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_outlined, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Groq API', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow('اسم الملف', fileName, Icons.insert_drive_file_outlined),
                const SizedBox(height: 12),
                _buildDetailRow('النوع', fileType.isEmpty ? '--' : fileType, Icons.category_outlined),
                const SizedBox(height: 12),
                _buildDetailRow('الحجم', formattedSize, Icons.data_usage),
              ],
            ),
          ),
          
          // Progress Section
          if (isProcessing || isExtracting || isSplitting) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isExtracting ? 'معالجة وتحسين الصوت (FFmpeg)...' 
                        : (isSplitting ? 'تقسيم الملف الطويل...' : (isPaused ? 'جاري الإيقاف المؤقت...' : 'جاري الرفع والمعالجة...')), 
                        style: TextStyle(
                          color: isExtracting ? Colors.purple : (isSplitting ? Colors.orange : (isPaused ? Colors.grey : Theme.of(context).colorScheme.primary)), 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Text(
                        isExtracting ? '${(extractProgress * 100).toInt()}%' : '${(uploadProgress * 100).toInt()}%', 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: isExtracting ? (extractProgress > 0 ? extractProgress : null) : (uploadProgress > 0 ? uploadProgress : null),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                    color: isExtracting ? Colors.purple : (isSplitting ? Colors.orange : Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],

          // Chunks visualization
          if (audioChunks.isNotEmpty) ...[
             const Divider(height: 1),
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('الأجزاء المقسمة (A5)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                   const SizedBox(height: 8),
                   ...audioChunks.map((chunk) => _buildChunkItem(chunk)),
                 ],
               ),
             )
          ],
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (!isProcessing && !isExtracting && !isSplitting && (!audioChunks.isNotEmpty || !audioChunks.every((c) => c.state == ChunkUploadState.completed)))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedFile == null ? null : () async {
                        // Phase A5 & A6 sequence
                        await ref.read(audioChunksProvider.notifier).prepareAndSplit(selectedFile);
                        await ref.read(audioChunksProvider.notifier).startUploadQueue();
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('البدء بالتفريغ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (!isProcessing && audioChunks.isNotEmpty && audioChunks.every((c) => c.state == ChunkUploadState.completed))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                         final text = audioChunks.map((c) => c.transcribedText ?? '').join('\n\n');
                         Navigator.of(context).push(MaterialPageRoute(
                           builder: (context) => ResultsScreen(text: text),
                         ));
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('عرض النتائج النهائية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                if (isProcessing || isExtracting || isSplitting) ...[
                  if (!isExtracting && !isSplitting) ...[
                     Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (isPaused) {
                               ref.read(audioChunksProvider.notifier).resumeUpload();
                            } else {
                               ref.read(audioChunksProvider.notifier).pauseUpload();
                            }
                          },
                          icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                          label: Text(isPaused ? 'استئناف' : 'إيقاف مؤقت', style: const TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (isExtracting || isSplitting) return; 
                        ref.read(audioChunksProvider.notifier).stopUpload();
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('إلغاء العملية', style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: (isExtracting || isSplitting) ? Colors.grey : Colors.red,
                        side: BorderSide(color: (isExtracting || isSplitting) ? Colors.grey : Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChunkItem(AudioChunk chunk) {
    Color statusColor;
    String statusText;
    switch (chunk.state) {
      case ChunkUploadState.completed:
        statusColor = Colors.green;
        statusText = 'مكتمل';
        break;
      case ChunkUploadState.uploading:
        statusColor = Colors.blue;
        statusText = 'جاري...';
        break;
      case ChunkUploadState.failed:
        statusColor = Colors.red;
        statusText = 'فشل';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'انتظار';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الجزء ${chunk.index + 1}', style: const TextStyle(fontSize: 12)),
              Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: chunk.progress,
            minHeight: 4,
            color: statusColor,
            backgroundColor: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          if (chunk.errorMessage != null)
             Text(chunk.errorMessage!, style: const TextStyle(fontSize: 10, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const Spacer(),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), dir: TextDirection.ltr, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
