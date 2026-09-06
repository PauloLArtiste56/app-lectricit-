import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/quetes.dart';

/// Carte « Quêtes du jour » : trois petits défis renouvelés chaque jour,
/// avec une barre d'avancement et la récompense en XP.
class CarteQuetes extends StatelessWidget {
  const CarteQuetes({super.key});

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quetes = etat.quetesDuJour;
    final accomplies = quetes.where((q) => q.accomplie).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Quêtes du jour', style: theme.textTheme.titleMedium),
                ),
                Text(
                  '$accomplies/${quetes.length}',
                  style: theme.textTheme.labelLarge?.copyWith(color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final q in quetes) _LigneQuete(etat: q),
          ],
        ),
      ),
    );
  }
}

class _LigneQuete extends StatelessWidget {
  const _LigneQuete({required this.etat});

  final EtatQuete etat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = etat.quete;
    final couleur = etat.accomplie ? Colors.green.shade600 : scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: couleur.withValues(alpha: 0.15),
            child: Icon(etat.accomplie ? Icons.done : q.icone, color: couleur, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.titre,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: etat.accomplie ? TextDecoration.lineThrough : null,
                    color: etat.accomplie ? scheme.outline : null,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: etat.progression,
                    minHeight: 6,
                    color: couleur,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            etat.accomplie ? '+${q.xp} XP' : '${etat.avancement}/${q.cible}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: etat.accomplie ? Colors.amber.shade800 : scheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
