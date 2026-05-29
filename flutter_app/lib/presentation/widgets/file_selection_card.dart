import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class FileSelectionCard extends ConsumerWidget {
  const FileSelectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileNotifier = ref.read(fileNotifierProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: _buildButton(
            context,
            icon: Icons.audio_file_outlined,
            title: 'ملف صوتي',
            color: Colors.blue,
            onTap: () {
              fileNotifier.pickAudio();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildButton(
            context,
            icon: Icons.video_file_outlined,
            title: 'ملف فيديو',
            color: Colors.purple,
            onTap: () {
              fileNotifier.pickVideo();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
