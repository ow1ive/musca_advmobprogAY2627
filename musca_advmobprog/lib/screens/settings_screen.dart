import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          ],
        ),
      ),
    );
  }
}
