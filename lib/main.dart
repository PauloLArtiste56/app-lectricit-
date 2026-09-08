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
      // Consumer : le thème suit le réglage choisi dans les paramètres.
      child: Consumer<AppState>(
        builder: (context, etat, _) => MaterialApp(
        title: 'ElecApp',
        theme: ElecTheme.clair(),
        darkTheme: ElecTheme.sombre(),
        themeMode: switch (etat.parametres.theme) {
          'clair' => ThemeMode.light,
          'sombre' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        home: const HomeShell(),
        // Sur un grand écran (Chrome sur PC), on limite la largeur pour
        // garder l'allure d'un téléphone. Sans effet sur un vrai mobile.
        builder: (context, child) => MediaQuery(
          // Taille du texte choisie dans les paramètres, pour toute l'appli.
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(etat.parametres.tailleTexte),
          ),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ElecTheme.largeurMax),
                child: child,
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
