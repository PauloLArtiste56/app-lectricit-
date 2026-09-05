import 'package:flutter/material.dart';

import 'screens/accueil_screen.dart';

void main() {
  runApp(const ElecApp());
}

class ElecApp extends StatelessWidget {
  const ElecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElecApp',
      theme: ThemeData(
        colorSchemeSeed: Colors.amber,
        useMaterial3: true,
      ),
      home: const AccueilScreen(),
    );
  }
}
