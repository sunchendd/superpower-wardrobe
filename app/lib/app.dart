import 'package:flutter/material.dart';
import 'features/shell/main_shell.dart';

class SuperpowerWardrobeApp extends StatelessWidget {
  const SuperpowerWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superpower Wardrobe',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
