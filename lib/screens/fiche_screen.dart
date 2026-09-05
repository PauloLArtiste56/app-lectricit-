import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/fiche.dart';
import '../models/module.dart';
import 'quiz_screen.dart';

/// Écran Fiche : titre, texte, image optionnelle, et "Passer au quiz".
/// Ouvrir la fiche la marque comme lue.
class FicheScreen extends StatefulWidget {
  const FicheScreen({super.key, required this.module, required this.index});

  final Module module;

  /// Position de la fiche dans `module.fiches`.
  final int index;

  @override
  State<FicheScreen> createState() => _FicheScreenState();
}

class _FicheScreenState extends State<FicheScreen> {
  @override
  void initState() {
    super.initState();
    // On attend la fin du premier dessin pour ne pas modifier l'état
    // pendant la construction de l'écran.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().marquerFicheLue(widget.module, _fiche.id);
    });
  }

  Fiche get _fiche => widget.module.fiches[widget.index];
  bool get _estDerniere => widget.index == widget.module.fiches.length - 1;

  void _ficheSuivante() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            FicheScreen(module: widget.module, index: widget.index + 1),
      ),
    );
  }

  void _passerAuQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(module: widget.module),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fiche = _fiche;

    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche ${widget.index + 1} / ${widget.module.fiches.length}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(fiche.titre, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (fiche.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/${fiche.image}'),
            ),
            const SizedBox(height: 16),
          ],
          Text(fiche.contenu, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 32),
          if (!_estDerniere) ...[
            FilledButton.tonalIcon(
              onPressed: _ficheSuivante,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Fiche suivante'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _passerAuQuiz,
            icon: const Icon(Icons.quiz),
            label: const Text('Passer au quiz'),
          ),
        ],
      ),
    );
  }
}
