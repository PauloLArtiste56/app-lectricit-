import 'package:flutter/material.dart';

import 'couleurs_parcours.dart';

/// Bouton « en relief » façon Duolingo : une face colorée posée sur une
/// épaisseur plus sombre, qui s'enfonce quand on appuie.
/// [secondaire] : face claire avec bordure, pour l'action de second rang.
class BoutonRelief extends StatefulWidget {
  const BoutonRelief({
    super.key,
    required this.label,
    this.onPressed,
    this.icone,
    this.couleur,
    this.secondaire = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icone;

  /// Couleur de la face ; couleur principale du thème par défaut.
  final Color? couleur;
  final bool secondaire;

  static const double relief = 5;

  @override
  State<BoutonRelief> createState() => _BoutonReliefState();
}

class _BoutonReliefState extends State<BoutonRelief> {
  bool _enfonce = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final actif = widget.onPressed != null;
    final base = widget.couleur ?? scheme.primary;
    final Color face, dessous, encre;
    if (!actif) {
      face = scheme.surfaceContainerHighest;
      dessous = scheme.outlineVariant;
      encre = scheme.onSurfaceVariant;
    } else if (widget.secondaire) {
      face = scheme.surface;
      dessous = scheme.outlineVariant;
      encre = base;
    } else {
      face = base;
      dessous = assombrir(base);
      encre = texteSur(base);
    }
    final decalage = _enfonce ? BoutonRelief.relief : 0.0;

    return Semantics(
      button: true,
      enabled: actif,
      child: GestureDetector(
        onTapDown: actif ? (_) => setState(() => _enfonce = true) : null,
        onTapUp: actif ? (_) => setState(() => _enfonce = false) : null,
        onTapCancel: () => setState(() => _enfonce = false),
        onTap: widget.onPressed,
        child: SizedBox(
          height: 52 + BoutonRelief.relief,
          child: Stack(
            children: [
              Positioned.fill(
                top: BoutonRelief.relief,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dessous,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                top: decalage,
                left: 0,
                right: 0,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(16),
                    border: widget.secondaire && actif
                        ? Border.all(color: dessous, width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icone != null) ...[
                        Icon(widget.icone, color: encre, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: encre,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
