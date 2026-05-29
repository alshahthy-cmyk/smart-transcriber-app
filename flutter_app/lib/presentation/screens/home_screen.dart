import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/file_selection_card.dart';
import '../widgets/file_info_card.dart';
import '../widgets/history_section.dart';
import 'settings_screen.dart';
import '../../providers/settings_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('تفريغ الصوت الذكي', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (settings.isDemoMode && settings.apiKey.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                         color: Colors.orange.shade50,
                         border: Border.all(color: Colors.orange.shade200),
                         borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'أنت تستخدم التطبيق في الوضع التجريبي المجاني. التفريغ قد يكون محدوداً بملفات قصيرة ومعدل منخفض. أدخل مفتاح API في الإعدادات للحصول على تجربة كاملة وغير محدودة.',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    'اختر ملفاً لتبدأ التفريغ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const FileSelectionCard(),
                  const SizedBox(height: 24),
                  const FileInfoCard(),
                  const SizedBox(height: 32),
                  const HistorySection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
