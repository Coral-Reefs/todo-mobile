import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:todo/screens/home_screen.dart';
import 'package:todo/screens/login_screen.dart';
import 'package:todo/notifications/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await requestNotificationPermission();
  await Firebase.initializeApp();
  await requestNotificationPermission();
  await NotificationService().initialize();
  await AndroidAlarmManager.initialize();
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
