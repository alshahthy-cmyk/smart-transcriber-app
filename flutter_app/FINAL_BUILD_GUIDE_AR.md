# دليل البناء النهائي (Final Build Guide)

هذا الدليل يوضح خطوات استخراج التطبيق كنسخة نهائية (Release) للاندرويد بصيغتي APK و App Bundle (AAB).

## 1. إنشاء مفتاح التوقيع (Keystore)
قبل بناء النسخة النهائية، يجب إنشاء مفتاح توقيع رقمي للتطبيق. افتح موجه الأوامر (Terminal) ونفذ الأمر التالي:
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*احتفظ بكلمة المرور الخاصة بالمفتاح في مكان آمن.*

## 2. إعداد ملف build.gradle
في ملف `android/app/build.gradle`، تأكد من تحديث قسم `signingConfigs` ليعكس مفتاح التوقيع الذي قمت بإنشائه:
```gradle
signingConfigs {
    release {
        storeFile file("upload-keystore.jks")
        storePassword "كلمة_المرور_الخاصة_بك"
        keyAlias "upload"
        keyPassword "كلمة_المرور_الخاصة_بك"
    }
}
```
ثم قم بتغيير `signingConfig signingConfigs.debug` إلى `signingConfig signingConfigs.release` في قسم `buildTypes { release { ... } }`.

## 3. بناء ملف APK
لبناء ملف للاختبار المباشر أو التوزيع المباشر (مثل رفعه على موقعك الشخصي):
```bash
flutter build apk --release --split-per-abi
```
*هذا سينتج ملفات APK منفصلة لكل معمارية (مثل arm64)، يمكنك العثور عليها في مسار:* `build/app/outputs/flutter-apk/`

## 4. بناء ملف AAB (متجر جوجل بلاي)
لرفع التطبيق إلى متجر جوجل بلاي، يُفضل بناء AAB:
```bash
flutter build appbundle --release
```
*ستجد الملف النهائي في مسار:* `build/app/outputs/bundle/release/app-release.aab`

## 5. ملاحظات تحسين الأداء (Obfuscation & Proguard)
لقد قمنا بتفعيل ShrinkResources و MinifyEnabled في ملف `build.gradle` لتقليل حجم التطبيق وحمايته. تأكد من اختبار النسخة النهائية (Release) جيداً، حيث أن عملية الـ Obfuscation قد تؤثر على بعض المكتبات إذا لم يتم تكوين `proguard-rules.pro` بشكل صحيح (وهو ما تم تهيئته مسبقاً في المرحلة A12).
