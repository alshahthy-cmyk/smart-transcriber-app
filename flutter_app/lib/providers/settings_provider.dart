import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/secure_storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

class SettingsState {
  final String apiKey;
  final bool isDemoMode;
  final bool hasCompletedOnboarding;

  SettingsState({
    this.apiKey = '',
    this.isDemoMode = false,
    this.hasCompletedOnboarding = false,
  });

  SettingsState copyWith({
    String? apiKey,
    bool? isDemoMode,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      apiKey: apiKey ?? this.apiKey,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(SettingsState(
    isDemoMode: _prefs.getBool('isDemoMode') ?? false,
    hasCompletedOnboarding: _prefs.getBool('hasCompletedOnboarding') ?? false,
  )) {
    _loadSecureData();
  }

  Future<void> _loadSecureData() async {
    final secureApiKey = await SecureStorageService.getApiKey();
    String finalApiKey = secureApiKey ?? '';
    
    // Migration
    if (finalApiKey.isEmpty) {
      final insecureKey = _prefs.getString('groq_api_key');
      if (insecureKey != null && insecureKey.isNotEmpty) {
        await SecureStorageService.saveApiKey(insecureKey);
        await _prefs.remove('groq_api_key');
        finalApiKey = insecureKey;
      }
    }

    state = state.copyWith(apiKey: finalApiKey);
  }

  Future<void> saveKey(String key) async {
    await SecureStorageService.saveApiKey(key);
    state = state.copyWith(apiKey: key, isDemoMode: false);
  }

  Future<void> setDemoMode(bool isDemo) async {
    await _prefs.setBool('isDemoMode', isDemo);
    state = state.copyWith(isDemoMode: isDemo);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool('hasCompletedOnboarding', true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }
}

// Deprecated Provider, keeping for compatibility and redirecting to new provider in short term if used in UI somewhere
final groqApiKeyProvider = StateNotifierProvider<ApiKeyNotifierAdapter, String>((ref) {
  return ApiKeyNotifierAdapter(ref.watch(settingsProvider.notifier));
});

class ApiKeyNotifierAdapter extends StateNotifier<String> {
  final SettingsNotifier _settingsNotifier;
  ApiKeyNotifierAdapter(this._settingsNotifier) : super('') {
     _settingsNotifier.addListener((state) { 
        if (this.state != state.apiKey) {
           this.state = state.apiKey;
        }
     });
  }

  Future<void> saveKey(String key) async {
    await _settingsNotifier.saveKey(key);
  }
}

