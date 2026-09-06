import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/question.dart';
import '../widgets/bouton_relief.dart';

/// Cartes à retourner : la question au recto, la réponse au verso. On
/// retourne la carte, puis on dit si on savait (« Je sais ») ou non
/// (« À revoir » : la question rejoint les points faibles).
class CartesScreen extends StatefulWidget {
  const CartesScreen({super.key, required this.titre, required this.questions});

  final String titre;
  final List<Question> questions;

  @override
  State<CartesScreen> createState() => _CartesScreenState();
}

class _CartesScreenState extends State<CartesScreen> {
  late List<Question> _cartes = List.of(widget.questions);
  int _index = 0;
  bool _retournee = false;
  final List<Question> _sues = [];
  final List<Question> _aRevoir = [];

  bool get _finie => _index >= _cartes.length;
  Question get _carte => _cartes[_index];

  void _retourner() => setState(() => _retournee = true);

  void _repondre({required bool sue}) {
    if (sue) {
      _sues.add(_carte);
    } else {
      _aRevoir.add(_carte);
      context.read<AppState>().marquerARevoir(_carte);
    }
    setState(() {
      _index++;
      _retournee = false;
    });
  }

  void _refaireARevoir() {
    setState(() {
      _cartes = List.of(_aRevoir);
      _aRevoir.clear();
      _sues.clear();
      _index = 0;
      _retournee = false;
    });
  }

  /// Ce qu'il fallait répondre, en une ligne.
  static String reponseDe(Question q) => switch (q.type) {
        TypeQuestion.qcm || TypeQuestion.image => q.reponses[q.bonne],
        TypeQuestion.ordre => q.reponses.join(' → '),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: _finie ? _bilan(theme) : _carteEnCours(theme),
    );
  }

  Widget _carteEnCours(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _index / _cartes.length,
                  minHeight: 14,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 12),
              Text('Carte ${_index + 1} / ${_cartes.length}',
                  style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: _retournee ? null : _retourner,
              child: _CarteRetournable(
                key: ValueKey(_carte.id),
                retournee: _retournee,
                recto: _Face(
                  couleur: scheme.primaryContainer,
                  encre: scheme.onPrimaryContainer,
                  etiquette: 'QUESTION',
                  image: _carte.image,
                  texte: _carte.enonce,
                  pied: 'Touche la carte pour voir la réponse',
                ),
                verso: _Face(
                  couleur: const Color(0xFFD7FFB8),
                  encre: const Color(0xFF3D8A00),
                  etiquette: 'RÉPONSE',
                  texte: reponseDe(_carte),
                  pied: _carte.explication,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_retournee)
            BoutonRelief(
              label: 'Retourner la carte',
              icone: Icons.flip,
              couleur: scheme.primary,
              onPressed: _retourner,
            )
          else
            Row(
              children: [
                Expanded(
                  child: BoutonRelief(
                    label: 'À revoir',
                    icone: Icons.replay,
                    couleur: Colors.orange.shade700,
                    onPressed: () => _repondre(sue: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BoutonRelief(
                    label: 'Je sais',
                    icone: Icons.check,
                    couleur: Colors.green.shade600,
                    onPressed: () => _repondre(sue: true),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _bilan(ThemeData theme) {
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Icon(Icons.style, size: 64, color: scheme.primary),
        const SizedBox(height: 12),
        Text('Cartes terminées',
            textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${_sues.length} sue${_sues.length > 1 ? 's' : ''} · '
          '${_aRevoir.length} à revoir',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (_aRevoir.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Les cartes à revoir ont rejoint tes points faibles.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
        const SizedBox(height: 24),
        if (_aRevoir.isNotEmpty) ...[
          BoutonRelief(
            label: 'Refaire celles à revoir (${_aRevoir.length})',
            icone: Icons.replay,
            couleur: Colors.orange.shade700,
            onPressed: _refaireARevoir,
          ),
          const SizedBox(height: 12),
        ],
        BoutonRelief(
          label: 'Retour',
          couleur: scheme.primary,
          secondaire: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Carte qui pivote autour de son axe vertical pour montrer le verso.
class _CarteRetournable extends StatelessWidget {
  const _CarteRetournable({
    super.key,
    required this.retournee,
    required this.recto,
    required this.verso,
  });

  final bool retournee;
  final Widget recto;
  final Widget verso;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: retournee ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (_, t, _) {
        final angle = t * math.pi;
        final montreRecto = t < 0.5;
        return Transform(
          alignment: Alignment.center,
          // Légère perspective pour l'effet 3D.
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: montreRecto
              ? recto
              // Le verso est pré-retourné pour être lisible une fois pivoté.
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: verso,
                ),
        );
      },
    );
  }
}

/// Une face de carte : étiquette, image optionnelle, texte, note en bas.
class _Face extends StatelessWidget {
  const _Face({
    required this.couleur,
    required this.encre,
    required this.etiquette,
    required this.texte,
    required this.pied,
    this.image,
  });

  final Color couleur;
  final Color encre;
  final String etiquette;
  final String texte;
  final String pied;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            etiquette,
            style: theme.textTheme.labelSmall?.copyWith(
              color: encre,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (image case final i?) ...[
                      Image.asset('assets/images/$i', height: 140, fit: BoxFit.contain),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      texte,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: encre,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            pied,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: encre),
          ),
        ],
      ),
    );
  }
}
