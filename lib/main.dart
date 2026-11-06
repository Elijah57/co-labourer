import 'package:flutter/material.dart';
import 'database.dart';
import 'screens/person/person_list.dart';
import 'services/auto_backup.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  await AutoBackup.instance.init();
  await NotificationService.instance.init();
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
      home: const PeopleListScreen(),
    );
  }
}