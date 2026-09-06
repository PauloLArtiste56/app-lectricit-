import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/cas_pratique.dart';
import '../widgets/module_icon.dart';
import 'quiz_screen.dart';

/// Liste des cas pratiques : une situation concrète à résoudre étape par
/// étape. Un cas est « résolu » à partir de 80 % de bonnes réponses.
class CasPratiquesScreen extends StatelessWidget {
  const CasPratiquesScreen({super.key});

  void _ouvrir(BuildContext context, CasPratique cas) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QuizScreen(cas: cas)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cas = etat.casPratiques;
    final resolus = etat.casResolus;

    return Scaffold(
      appBar: AppBar(title: const Text('Cas pratiques')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Une situation réelle, à résoudre étape par étape. '
            '$resolus / ${cas.length} résolu${resolus > 1 ? 's' : ''}.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 12),
          for (final c in cas)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: etat.casResolu(c)
                      ? Colors.green.shade100
                      : scheme.primaryContainer,
                  child: Icon(
                    etat.casResolu(c) ? Icons.check : iconePourModule(c.moduleId),
                    color: etat.casResolu(c)
                        ? Colors.green.shade800
                        : scheme.onPrimaryContainer,
                  ),
                ),
                title: Text(c.titre),
                subtitle: Text(
                  c.contexte,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text('${c.etapes.length} étapes',
                    style: theme.textTheme.labelSmall),
                onTap: () => _ouvrir(context, c),
              ),
            ),
        ],
      ),
    );
  }
}
