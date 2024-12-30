import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:todo/screens/home_screen.dart';
import 'package:todo/screens/login_screen.dart';
import 'package:todo/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await requestNotificationPermission();
  await Firebase.initializeApp();
  await requestNotificationPermission();

  await AwesomeNotifications().initialize(
    'resource://drawable/app_icon',
    [
      NotificationChannel(
        channelKey: 'alarm_channel',
        channelName: 'Alarm Notifications',
        channelDescription: 'Channel for alarm notifications',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/alarm_sound',
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableLights: true,
        enableVibration: true,
      ),
    ],
  );

  await NotificationService().initialize();

  runApp(MainApp());
}

Future<void> requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

class MainApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Todo",
      theme:
          ThemeData(primarySwatch: Colors.indigo, primaryColor: Colors.indigo),
      home: _auth.currentUser != null ? const HomeScreen() : LoginScreen(),
    );
  }
}
