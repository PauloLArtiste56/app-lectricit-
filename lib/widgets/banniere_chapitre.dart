import 'package:flutter/material.dart';

import '../models/chapitre.dart';
import 'couleurs_parcours.dart';

/// Bandeau qui ouvre un chapitre sur le parcours : numéro, titre,
/// description et nombre de modules réussis. Il prend la couleur du
/// chapitre, et passe en vert quand tout le chapitre est réussi.
class BanniereChapitre extends StatelessWidget {
  const BanniereChapitre({
    super.key,
    required this.numero,
    required this.chapitre,
    required this.reussis,
    required this.total,
  });

  final int numero;
  final Chapitre chapitre;
  final int reussis;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complet = total > 0 && reussis == total;
    final fond = complet ? vertReussi : couleurChapitre(chapitre);
    final ombre = assombrir(fond);
    final avant = texteSur(fond);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(18),
          // Le même relief que les boutons : une ombre pleine vers le bas.
          boxShadow: [BoxShadow(color: ombre, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHAPITRE $numero',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: avant.withValues(alpha: 0.85),
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    chapitre.titre,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: avant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (chapitre.description.isNotEmpty)
                    Text(
                      chapitre.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: avant),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Icon(complet ? Icons.emoji_events : Icons.flag, color: avant),
                Text(
                  '$reussis/$total',
                  style: theme.textTheme.labelLarge?.copyWith(color: avant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
