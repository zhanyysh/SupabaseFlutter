import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/theme_service.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          if (user != null)
            UserAccountsDrawerHeader(
              accountName: const Text('Пользователь'),
              accountEmail: Text(user.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person, size: 40),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Тема оформления'),
            trailing: IconButton(
              icon: Icon(themeService.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode),
              onPressed: () {
                themeService.toggleTheme();
                setState(() {}); // Rebuild to show change
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Выйти', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
