import 'package:flutter/material.dart';
import 'database.dart';
import 'screens/home_screen.dart';
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
  await NotificationService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Co-labourer',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) =>
          LockGate(child: child ?? const SizedBox.shrink()),
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}