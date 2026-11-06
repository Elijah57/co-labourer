import 'package:flutter/material.dart';
import 'database.dart';
import 'repository/person.dart';
import 'screens/person/person_list.dart';
import 'screens/person/person_detail.dart';
import 'services/app_lock.dart';
import 'services/auto_backup.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/lock_gate.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  await AutoBackup.instance.init();
  await AppLock.instance.init();
  NotificationService.instance.onOpenPerson = (id) async {
    final person = await PeopleRepository().getById(id);
    final nav = navigatorKey.currentState;
    if (person == null || nav == null) return;
    await nav.push(
      MaterialPageRoute(builder: (_) => PersonDetailScreen(person: person)),
    );
    NotificationService.instance.refreshList?.call();
  };
  await NotificationService.instance.init();
  await NotificationService.instance.rescheduleAll(
    await PeopleRepository().getAllPeople(),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Co-laborer',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          LockGate(child: child ?? const SizedBox.shrink()),
      navigatorKey: navigatorKey,
      home: const PeopleListScreen(),
    );
  }
}
