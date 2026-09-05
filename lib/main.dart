import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

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
        theme: ElecTheme.clair(),
        darkTheme: ElecTheme.sombre(),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
        // Sur un grand écran (Chrome sur PC), on limite la largeur pour
        // garder l'allure d'un téléphone. Sans effet sur un vrai mobile.
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ElecTheme.largeurMax),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
