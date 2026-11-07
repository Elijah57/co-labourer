import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../widgets/home_tile.dart';
import 'me/me_screen.dart';
import '../../screens/person/person_list.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NotificationService.instance.handlePending(),
    );
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Co-laborer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HomeTile(icon: Icons.auto_awesome, label: 'God'),
                  const SizedBox(height: 16),
                  HomeTile(
                    icon: Icons.person_outline,
                    label: 'Me',
                    onTap: () => _open(const MeScreen()),
                  ),
                  const SizedBox(height: 16),
                  HomeTile(
                    icon: Icons.groups_outlined,
                    label: 'Assignment',
                    onTap: () => _open(const PeopleListScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}