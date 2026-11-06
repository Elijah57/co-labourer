import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/person.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'followups',
      'Follow-up reminders',
      channelDescription: 'Reminders to follow up with people',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  int _idFor(String personId) =>
      int.parse(personId.substring(0, 7), radix: 16);

  Future<void> cancel(String personId) =>
      _plugin.cancel(id: _idFor(personId));

  Future<void> schedule(Person person) async {
    await cancel(person.id);

    final d = person.followUpDate;
    if (d == null) return;

    final now = DateTime.now();
    final target = DateTime(d.year, d.month, d.day, 9);
    if (!target.isAfter(now)) return;

    final when = tz.TZDateTime.now(tz.UTC).add(target.difference(now));

    final name = [
      person.firstname,
      person.lastname,
      person.othername,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

    await _plugin.zonedSchedule(
      id: _idFor(person.id),
      title: 'Follow up: $name',
      body: person.metAt != null
          ? 'You met at ${person.metAt}'
          : 'Time to reach out',
      scheduledDate: when,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> rescheduleAll(List<Person> people) async {
    await _plugin.cancelAll();
    for (final p in people) {
      await schedule(p);
    }
  }
}
