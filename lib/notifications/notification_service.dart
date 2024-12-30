import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            'app_icon'); // Make sure the icon is in assets

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

  Future<void> alarmCallback() async {
    print('Alarm triggered');
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

    if (alarmTime.isAfter(DateTime.now())) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: alarmTime.hashCode,
          channelKey: 'alarm_channel',
          title: 'Task Reminder',
          body: 'Your task "$taskTitle" is due in 10 minutes!',
          notificationLayout: NotificationLayout.Default,
          autoDismissible: false,
          locked: true,
          fullScreenIntent: true,
          displayOnForeground: true,
          displayOnBackground: true,
          criticalAlert: true,
          wakeUpScreen: true,
          category: NotificationCategory.Alarm,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'STOP_ALARM',
            label: 'I got it!',
            autoDismissible: true,
            actionType: ActionType.DismissAction,
          ),
          NotificationActionButton(
            key: 'SNOOZE_ALARM',
            label: 'Snooze',
            autoDismissible: true,
            actionType: ActionType.Default,
          ),
        ],
        schedule: NotificationCalendar.fromDate(
          date: alarmTime,
          preciseAlarm: true,
        ),
      );
      print('Alarm notification scheduled.');
    } else {
      print('Alarm time $alarmTime is in the past and cannot be scheduled.');
    }
  }
}
