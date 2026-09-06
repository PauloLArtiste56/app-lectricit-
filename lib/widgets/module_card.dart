import 'package:flutter/material.dart';

import '../models/module.dart';
import 'couronnes.dart';
import 'module_icon.dart';

/// Carte d'un module sur l'écran d'accueil : icône, titre, progression "3/10".
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.module,
    required this.questionsReussies,
    this.couleur,
    this.couronnes = 0,
    this.onTap,
  });

  final Module module;

  /// Nombre de questions déjà réussies dans ce module.
  final int questionsReussies;

  /// Couleur du chapitre du module (icône et barre).
  final Color? couleur;

  /// Couronnes de maîtrise gagnées (0 à 3).
  final int couronnes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = module.nombreQuestions;
    final enPreparation = total == 0;
    final termine = !enPreparation && questionsReussies == total;
    final progression = enPreparation ? 0.0 : questionsReussies / total;
    final teinte = couleur ?? scheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enPreparation ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    termine ? Colors.green.shade600 : teinte.withValues(alpha: 0.15),
                foregroundColor: termine ? Colors.white : teinte,
                child: Icon(termine ? Icons.check : iconePourModule(module.id)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            module.titre,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (!enPreparation) Couronnes(nombre: couronnes, taille: 14),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enPreparation
                          ? 'Contenu à venir'
                          : '$questionsReussies/$total questions réussies',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progression,
                      minHeight: 6,
                      color: termine ? Colors.green.shade600 : teinte,
                    ),
                  ],
                ),
              ),
              if (!enPreparation) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
