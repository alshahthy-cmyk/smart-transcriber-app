import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundServiceHelper {
  static final BackgroundServiceHelper _instance = BackgroundServiceHelper._internal();
  factory BackgroundServiceHelper() => _instance;
  BackgroundServiceHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_bg_service_small');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'upload_channel',
        initialNotificationTitle: 'جاري العملية',
        initialNotificationContent: 'التحضير...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Handle data updates from main app and show notification
  service.on('update').listen((event) {
    if (event != null && event.containsKey('progress')) {
      final double progress = event['progress'] as double;
      final String status = event['status'] as String;
      
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "تفريغ الصوت الذكي",
          content: "$status - ${(progress * 100).toInt()}%",
        );
      }
    }
  });

  service.on('complete').listen((event) {
     if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "اكتملت العملية",
          content: "تم تفريغ الملف الصوتي بنجاح",
        );
        service.stopSelf();
     }
  });
}
