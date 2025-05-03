import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/task_model.dart';
import 'package:timezone/timezone.dart' as tz;

Color strengthenColor(Color color, double factor) {
  int r = (color.red * factor).clamp(0, 255).toInt();
  int g = (color.green * factor).clamp(0, 255).toInt();
  int b = (color.blue * factor).clamp(0, 255).toInt();

  return Color.fromARGB(color.alpha, r, g, b);
}

List<DateTime> generateWeekDates(int weekOffset) {
  final today = DateTime.now();
  DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  // go back or go ahead by 7 days
  startOfWeek = startOfWeek.add(Duration(days: weekOffset * 7));

  return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
}

String rgbToHex(Color color) {
  return '${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}';
}

Color hexToRgb(String hex) {
  return Color(int.parse(hex, radix: 16) + 0xFF000000);
}

// function to schedule notification 10 mins before deadline
Future<void> scheduleTaskNotification(TaskModel task) async {
  final scheduledTime = task.dueAt.subtract(Duration(minutes: 10));
  final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
  final now = DateTime.now();

  if (!scheduledTime.isAfter(now)) {
    print("❌ Not scheduling: $scheduledTime is not in the future.");
    return;
  }

  const androidDetails = AndroidNotificationDetails(
    'task_deadline_channel',
    'Task Deadlines',
    channelDescription: 'Reminder before task deadline',
    importance: Importance.max,
    priority: Priority.high,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    task.id.hashCode,
    'Upcoming Task Deadline',
    'Task "${task.title}" is due in 10 minutes!',
    tzScheduledTime.subtract(
      Duration(hours: 2),
    ), // because of the UTC convirsion
    notificationDetails,
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

final navigatorKey = GlobalKey<NavigatorState>();
