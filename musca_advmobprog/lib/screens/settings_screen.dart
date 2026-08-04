import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an app theme',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Light mode'),
                trailing: !themeModel.isDark
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => themeModel.setDarkMode(false),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark mode'),
                trailing: themeModel.isDark
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () => themeModel.setDarkMode(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
