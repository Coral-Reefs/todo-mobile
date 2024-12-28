import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap);

    tz.initializeTimeZones();

    final PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      print('Notification permissions granted.');
    } else {
      print('Notification permissions denied.');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('Notification clicked: ${response.payload}');
  }

  void alarmCallback() {
    // final AssetsAudioPlayer player = AssetsAudioPlayer();
    // player.open(
    //   Audio('assets/playtime.mp3'),
    //   autoStart: true,
    //   loopMode: LoopMode.single,
    // );
    print('Alarm sound is playing!');
  }

  Future<void> scheduleNotification(
      DateTime dueDateTime, String taskTitle) async {
    print('Scheduling notification for: $taskTitle at $dueDateTime');
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'todo_channel',
      'Todo Notifications',
      channelDescription: 'Channel for todo tasks',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final DateTime notificationTime = dueDateTime.subtract(
      const Duration(minutes: 30),
    );
    final DateTime alarmTime = dueDateTime.subtract(
      const Duration(minutes: 10),
    );

    if (notificationTime.isAfter(DateTime.now())) {
      print('Notification will be triggered at: $notificationTime');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        taskTitle.hashCode,
        'Upcoming task: $taskTitle',
        'Your task is due in 30 minutes.',
        tz.TZDateTime.from(notificationTime, tz.local),
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskTitle,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('Notification scheduled successfully');
    }

    final int alarmId = 0;
    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
    );
    print('Alarm scheduled at: $dueDateTime');

    // final AndroidIntent intent = AndroidIntent(
    //   action: 'android.intent.action.SET_ALARM',
    //   arguments: <String, dynamic>{
    //     'android.intent.extra.alarm.HOUR': dueDateTime.hour,
    //     'android.intent.extra.alarm.MINUTES': dueDateTime.minute,
    //     'android.intent.extra.alarm.SKIP_UI': false,
    //   },
    // );
    // intent.launch();
  }
}
