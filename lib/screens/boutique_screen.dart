import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/tenue.dart';

/// Boutique : dépenser les XP gagnés en gels de série (qui sauvent la série
/// un jour manqué) et en tenues pour la mascotte.
class BoutiqueScreen extends StatelessWidget {
  const BoutiqueScreen({super.key});

  void _prevenir(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _acheterGel(BuildContext context, AppState etat) async {
    final ok = await etat.acheterGel();
    if (!context.mounted) return;
    _prevenir(context, ok ? 'Gel de série acheté !' : 'Pas assez d\'XP disponibles.');
  }

  Future<void> _acheterTenue(BuildContext context, AppState etat, Tenue t) async {
    final ok = await etat.acheterTenue(t);
    if (!context.mounted) return;
    _prevenir(context, ok ? '${t.nom} : achetée et portée !' : 'Pas assez d\'XP disponibles.');
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Boutique')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Solde.
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber.shade700, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${etat.xpDisponibles} XP disponibles',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${etat.xpTotal} XP gagnés au total, ${etat.xpDepenses} dépensés. '
                          'Dépenser ne fait pas baisser ton niveau.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Gel de série', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.lightBlue.shade50,
                child: Icon(Icons.ac_unit, color: Colors.lightBlue.shade700),
              ),
              title: Text('En stock : ${etat.gels} / ${AppState.gelsMax}'),
              subtitle: const Text(
                'Un jour sans quiz ? Un gel le compte quand même et ta série continue. '
                'Il s\'utilise tout seul.',
              ),
              trailing: FilledButton(
                // Le thème met les boutons en pleine largeur : pas ici.
                style: _compact,
                onPressed: etat.peutAcheterGel() ? () => _acheterGel(context, etat) : null,
                child: Text('${AppState.prixGel} XP'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Tenues de la pile', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final t in Tenue.toutes) _CarteTenue(tenue: t),
          if (etat.tenuePortee != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => etat.porterTenue(null),
              icon: const Icon(Icons.close),
              label: const Text('Retirer la tenue'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Style des boutons d'achat : taille au contenu, pas en pleine largeur.
final ButtonStyle _compact = ButtonStyle(
  minimumSize: WidgetStateProperty.all(const Size(72, 40)),
  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14)),
);

class _CarteTenue extends StatelessWidget {
  const _CarteTenue({required this.tenue});

  final Tenue tenue;

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final achetee = etat.tenueAchetee(tenue);
    final portee = etat.tenuePortee?.id == tenue.id;
    final boutique = context.findAncestorWidgetOfExactType<BoutiqueScreen>()!;

    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/decors/pile_2.png', fit: BoxFit.contain),
              Image.asset('assets/images/${tenue.image}', fit: BoxFit.contain),
            ],
          ),
        ),
        title: Text(tenue.nom),
        subtitle: Text(tenue.description),
        trailing: portee
            ? const Chip(label: Text('Portée'), avatar: Icon(Icons.check, size: 18))
            : achetee
                ? OutlinedButton(
                    style: _compact,
                    onPressed: () => etat.porterTenue(tenue),
                    child: const Text('Porter'),
                  )
                : FilledButton(
                    style: _compact,
                    onPressed: etat.xpDisponibles >= tenue.prix
                        ? () => boutique._acheterTenue(context, etat, tenue)
                        : null,
                    child: Text('${tenue.prix} XP'),
                  ),
      ),
    );
  }
}
