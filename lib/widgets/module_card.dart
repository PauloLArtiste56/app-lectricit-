import 'package:flutter/material.dart';

import '../models/module.dart';

/// Carte d'un module sur l'écran d'accueil : titre + progression "3/10".
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.module,
    required this.questionsReussies,
    this.onTap,
  });

  final Module module;

  /// Nombre de questions déjà réussies dans ce module.
  final int questionsReussies;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final total = module.nombreQuestions;
    final enPreparation = total == 0;
    final progression = enPreparation ? 0.0 : questionsReussies / total;

    return Card(
      child: ListTile(
        onTap: enPreparation ? null : onTap,
        leading: CircleAvatar(child: Text('${module.ordre}')),
        title: Text(module.titre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              enPreparation
                  ? 'Contenu à venir'
                  : '$questionsReussies/$total questions réussies',
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progression),
          ],
        ),
        trailing: enPreparation ? null : const Icon(Icons.chevron_right),
      ),
    );
  }
}
