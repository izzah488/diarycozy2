import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Theme'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            title: const Text('Light Theme'),
            trailing: themeProvider.currentThemeName == 'light'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setTheme('light');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Dark Theme'),
            trailing: themeProvider.currentThemeName == 'dark'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setTheme('dark');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Soft Pink Theme'),
            trailing: themeProvider.currentThemeName == 'pink'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setTheme('pink');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Blue Theme'),
            trailing: themeProvider.currentThemeName == 'blue'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setTheme('blue');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Green Theme'),
            trailing: themeProvider.currentThemeName == 'green'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setTheme('green');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
