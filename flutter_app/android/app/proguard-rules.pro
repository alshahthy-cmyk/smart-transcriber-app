# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class plugins.flutter.io.**  { *; }

# Dart
-keep class android.arch.** { *; }
-dontwarn android.arch.**

# FFMPEG
-keep class com.arthenica.ffmpeg.** { *; }
-dontwarn com.arthenica.ffmpeg.**
