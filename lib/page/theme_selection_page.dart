import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class ThemeSelectionPage extends StatelessWidget {
  const ThemeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final themes = [
      {'name': 'Light Theme', 'key': 'light'},
      {'name': 'Dark Theme', 'key': 'dark'},
      {'name': 'Soft Pink Theme', 'key': 'pink'},
      {'name': 'Blue Theme', 'key': 'blue'},
      {'name': 'Green Theme', 'key': 'green'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Theme'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = themeProvider.themeName == theme['key'];


          return ListTile(
            title: Text(theme['name']!),
            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              themeProvider.setTheme(theme['key']!);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
