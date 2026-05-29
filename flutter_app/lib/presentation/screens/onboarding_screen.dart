import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _apiKeyController = TextEditingController();

  final List<Map<String, String>> _pages = [
    {
      'title': 'التفريغ الصوتي الذكي',
      'body': 'حوّل تسجيلاتك ومحاضراتك إلى نصوص دقيقة بنقرة واحدة باستخدام أحدث تقنيات الذكاء الاصطناعي.',
      'icon': 'mic',
    },
    {
      'title': 'دعم الملفات الطويلة',
      'body': 'لا تقلق بشأن حجم الملف. تطبيقنا يقسم الملفات الطويلة تلقائياً ويعالجها في الخلفية لضمان أفضل نتيجة.',
      'icon': 'folder_special',
    },
    {
      'title': 'إعداد مفتاح API',
      'body': 'لكي يعمل التطبيق بكامل طاقته، ستحتاج إلى مفتاح Groq API مجاني. سيتم تخزينه محلياً وبشكل آمن على جهازك.',
      'icon': 'vpn_key',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _finishOnboarding(BuildContext context, bool isDemo) async {
    if (!isDemo && _apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مفتاح API أو الاستمرار في الوضع التجريبي')),
      );
      return;
    }

    if (!isDemo) {
      await ref.read(settingsProvider.notifier).saveKey(_apiKeyController.text.trim());
    } else {
      await ref.read(settingsProvider.notifier).setDemoMode(true);
    }
    
    await ref.read(settingsProvider.notifier).completeOnboarding();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final isLastPage = index == _pages.length - 1;
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          index == 0 ? Icons.mic : (index == 1 ? Icons.folder_special : Icons.vpn_key),
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _pages[index]['title']!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['body']!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        if (isLastPage) ...[
                          const SizedBox(height: 32),
                          TextField(
                            controller: _apiKeyController,
                            decoration: const InputDecoration(
                              labelText: 'مفتاح Groq API',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.key),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _finishOnboarding(context, false),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('حفظ والبدء'),
                          ),
                          TextButton(
                            onPressed: () => _finishOnboarding(context, true),
                            child: const Text('المتابعة في الوضع التجريبي (إمكانيات محدودة)'),
                          )
                        ]
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_currentPage < _pages.length - 1)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('تخطي'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('التالي'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
