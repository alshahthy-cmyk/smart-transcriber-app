# Production Readiness Checklist

Before publishing the app to the Google Play Store, ensure that all checklist items are successfully fulfilled:

## 1. App Configuration
- [ ] **App Name**: Check `android/app/src/main/res/values/strings.xml` and `pubspec.yaml`.
- [ ] **App Icon**: Ensure the app icon is generated for all screen densities.
- [ ] **Package Name**: Double-check the applicationId in `android/app/build.gradle` (e.g., `com.example.transcription_app`).
- [ ] **Version Tag**: Update `version` in `pubspec.yaml` (e.g., `1.0.0+1`).

## 2. API & Secrets
- [ ] **API Keys**: Ensure no private API Keys are hardcoded in the source tree. If required, use `.env` files and `flutter_dotenv`.
- [ ] **Billing / Tiers**: Review Groq API quota and limits.

## 3. Permissions
- [ ] **Internet**: Included `<uses-permission android:name="android.permission.INTERNET"/>`.
- [ ] **Storage/Audio**: Check that file and audio permissions are thoroughly managed for Android 13/14+ (`READ_MEDIA_AUDIO`).
- [ ] **Foreground Service**: Ensure `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />` is declared.

## 4. UI / UX Quality
- [ ] **Dark Mode / Light Mode**: Verify the UI adapts cleanly to both system themes.
- [ ] **Arabic (RTL)**: All screens must natively support Right-to-Left layouts properly.
- [ ] **Error Handling**: Test edge cases (Network disconnect mid-processing, invalid API key).

## 5. Optimization
- [ ] **Proguard / R8**: Ensure `proguard-rules.pro` has no negative impact on FFmpeg and Background Service libraries.
- [ ] **Architecture Splits**: `split-per-abi` verified.
- [ ] **Temp File Clearing**: Ensured that old audio chunks and cached files are automatically deleted after processing.

## 6. Build
- [ ] **Keystore**: Setup release Keystore securely.
- [ ] **Test App Bundle (`.aab`)**: Install via bundletool to ensure stability before Google Play upload.
