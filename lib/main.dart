import 'theam/ThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider package
import 'page/MyHomePage.dart'; // Import the home page

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(), // Provide the ThemeProvider
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Access the ThemeProvider

    return MaterialApp(
      title: 'Chat with Bot',
      theme: themeProvider.getTheme(), // Use the theme from ThemeProvider
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(), // Set the home page
    );
  }
}
