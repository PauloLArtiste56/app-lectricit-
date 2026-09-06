import 'package:flutter/material.dart';

import '../models/module.dart';
import 'module_icon.dart';

/// État d'un module sur le chemin du parcours.
enum EtatNoeud { aFaire, enCours, reussi }

/// Un rond du parcours : l'icône du module, un anneau de progression et le
/// titre en dessous.
class NoeudModule extends StatelessWidget {
  const NoeudModule({
    super.key,
    required this.module,
    required this.etat,
    required this.progression,
    this.onTap,
  });

  final Module module;
  final EtatNoeud etat;

  /// Entre 0 et 1 : part des questions réussies.
  final double progression;
  final VoidCallback? onTap;

  /// Diamètre du rond, utilisé aussi pour tracer le chemin entre les ronds.
  static const double diametre = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (Color fond, Color avant, IconData icone) = switch (etat) {
      EtatNoeud.reussi => (Colors.green.shade600, Colors.white, Icons.check),
      EtatNoeud.enCours => (
          scheme.primary,
          scheme.onPrimary,
          iconePourModule(module.id)
        ),
      EtatNoeud.aFaire => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          iconePourModule(module.id)
        ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: diametre,
              height: diametre,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // L'anneau montre la progression d'un module commencé.
                  if (etat == EtatNoeud.enCours)
                    CircularProgressIndicator(
                      value: progression,
                      strokeWidth: 5,
                      color: Colors.green.shade600,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
                      child: Icon(icone, color: avant, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              module.titre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: etat == EtatNoeud.aFaire
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
