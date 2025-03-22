import 'package:ct312h_project/ui/Login/loginScreen.dart';
import 'package:flutter/material.dart';
import '../../models/theme_manager.dart';
import 'package:provider/provider.dart';
import 'btn_function.dart';
import '../../screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> navigateToFavorites(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      Navigator.pushNamed(context, '/favorites', arguments: userId);
    } else {
      print("Lỗi: Không tìm thấy userId");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setting'),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // Edit Profile
          ListTile(
            leading: Icon(Icons.person,
                color: Theme.of(context).colorScheme.secondary),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Navigator.pushNamed(context, '/editprofile');
            },
          ),
          const Divider(),

          // Favorites
          ListTile(
            leading: Icon(Icons.favorite,
                color: Theme.of(context).colorScheme.error),
            title: const Text('Favorites'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              navigateToFavorites(context);
            },
          ),
          const Divider(),

          // Dark Mode Toggle
          SwitchListTile(
            secondary: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const Divider(),

          // Change Password
          ListTile(
            leading:
                Icon(Icons.lock, color: Theme.of(context).colorScheme.error),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Navigator.pushNamed(context, '/changepass');
            },
          ),
          const Divider(),

          // Log Out
          ListTile(
            leading: Icon(Icons.exit_to_app,
                color: Theme.of(context).colorScheme.secondary),
            title: Text(
              'Log Out',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }
}
