import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/services/background_service.dart';
import 'core/utils/temp_file_manager.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  
  try {
    await BackgroundServiceHelper().initialize();
  } catch (e) {
    debugPrint("Background service init error: $e");
  }

  // Phase A11 & S7: Clear old temp files to optimize storage & performance
  try {
    await TempFileManager.clearOldTempFiles();
  } catch (e) {
    debugPrint("TempFileManager error: $e");
  }
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ArabicTranscriptionApp(),
    ),
  );
}

class ArabicTranscriptionApp extends ConsumerWidget {
  const ArabicTranscriptionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      title: 'تفريغ الصوت الذكي',
      debugShowCheckedModeBanner: false,
      
      // Theme Settings (Material 3)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Supports Dark Mode automatically
      
      // Full RTL & Arabic Localization Support
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'), // Explicit Arabic Locale
      ],
      locale: const Locale('ar', 'SA'), // Default to Arabic
      
      home: settings.hasCompletedOnboarding ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
