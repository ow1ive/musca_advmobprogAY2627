import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ENHANCEMENT 1: Logout clears both DummyJSON and Firebase sessions, then returns to sign in.
  Future<void> _logout(BuildContext context) async {
    final userService = UserService();
    await userService.logout();
    await userService.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // Enhancement 3: Move dark/light mode control into Settings as a single switch.
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  themeModel.isDark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                title: const Text('Dark mode'),
                subtitle: Text(
                  themeModel.isDark
                      ? 'Dark theme is enabled'
                      : 'Light theme is enabled',
                ),
                value: themeModel.isDark,
                // Enhancement 3: Toggle app theme directly from this settings switch.
                onChanged: (_) => themeModel.toggleTheme(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Account',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
