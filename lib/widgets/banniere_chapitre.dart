import 'package:flutter/material.dart';

import '../models/chapitre.dart';

/// Bandeau qui ouvre un chapitre sur le parcours : numéro, titre,
/// description et nombre de modules réussis.
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
    final scheme = theme.colorScheme;
    final complet = total > 0 && reussis == total;
    final fond = complet ? Colors.green.shade600 : scheme.primary;
    final avant = complet ? Colors.white : scheme.onPrimary;

    return Card(
      color: fond,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapitre $numero',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: avant.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    chapitre.titre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: avant,
                      fontWeight: FontWeight.bold,
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
