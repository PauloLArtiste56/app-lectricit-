import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'screens/accueil_screen.dart';

void main() {
  runApp(const ElecApp());
}

class ElecApp extends StatelessWidget {
  const ElecApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppState est créé une fois ici et accessible depuis tous les écrans.
    return ChangeNotifierProvider(
      create: (_) => AppState()..charger(),
      child: MaterialApp(
        title: 'ElecApp',
        theme: ThemeData(
          colorSchemeSeed: Colors.amber,
          useMaterial3: true,
        ),
        home: const AccueilScreen(),
      ),
    );
  }
}
