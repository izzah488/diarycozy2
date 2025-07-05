import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme_provider.dart';
import 'page/login_page.dart';
import 'page/diary_home_page.dart'; // Assuming this is your home page
import 'page/profile_page.dart'; // Import the new profile page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project URL and anon key
  await Supabase.initialize(
    url: 'https://xfdvbbdwpgmgkufrwscf.supabase.co', // Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmZHZiYmR3cGdtZ2t1ZnJ3c2NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzNjY4NTAsImV4cCI6MjA2Njk0Mjg1MH0.QbweiI5RD352o5ozl--Vz2p2VWv1goL2f1hBf7pVikQ', // Replace with your Supabase anon key
  );

  runApp(
    // ChangeNotifierProvider makes ThemeProvider available throughout the widget tree
    ChangeNotifierProvider(
      // Initialize ThemeProvider with the light theme as default
      create: (_) => ThemeProvider(),
      child: const DiaryApp(),
    ),
  );
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to get the current theme
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Set to false to remove the debug banner
      title: 'My Cozy Diary',
      theme: themeProvider.theme, // Apply the current theme from ThemeProvider
      // Determine the initial route based on user's authentication status
      initialRoute: Supabase.instance.client.auth.currentUser == null
          ? '/login' // If no user is logged in, go to login page
          : '/home', // If a user is logged in, go to home page
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const DiaryHomePage(),
        '/profile': (context) => ProfilePage(totalEntries: 0), // Add the profile page route and provide totalEntries
      },
    );
  }
}
