import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    final getStorage = GetStorage();
    bool notificationDenied = getStorage.read('notificationDenied') ?? false;
    if (notificationDenied == true) return;

    //request permission if not granted
    PermissionStatus status = await Permission.notification.status;
    if (!status.isGranted) {
      // The permission is not granted, request it.
      status = await Permission.notification.request();
      getStorage.write('notificationDenied', status.isDenied);
    }

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'channelId',
            'channelName',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

    // Initialization setting for android
    const InitializationSettings initializationSettingsAndroid =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/ic_launcher"));
    _notificationsPlugin.initialize(
      initializationSettingsAndroid,
      // to handle event when we receive notification
      onDidReceiveNotificationResponse: (details) {
        if (details.input != null) {}
      },
    );
  }

  static Future<void> showNotification(
      {int id = 0,
      String? title,
      String? body,
      String? payload,
      int? millisecondDuration,
      int progress = 0,
      bool sound = true,
      int maxProgress = 0}) async {
    return _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails('channelId', 'channelName',
            importance: Importance.max,
            progress: progress,
            maxProgress: maxProgress,
            priority: Priority.high,
            onlyAlertOnce: true,
            showProgress: maxProgress > 0,
            timeoutAfter: millisecondDuration,
            indeterminate: maxProgress == 1,
            ongoing: maxProgress > 0,
            autoCancel: maxProgress == 0),
      ),
    );
  }

  static void clearAll() {
    _notificationsPlugin.cancelAll();
  }
}
