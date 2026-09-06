import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/quiz_session.dart';
import '../models/module.dart';
import '../models/question.dart';
import '../widgets/reponse_button.dart';
import 'fiche_screen.dart';
import 'resultat_screen.dart';

/// Écran Quiz : une question à la fois, feedback immédiat, barre de progression.
/// En mode examen ([examen]) : pas de correction pendant l'épreuve, un
/// chrono ([duree]) qui termine le quiz quand il tombe à zéro.
class QuizScreen extends StatefulWidget {
  /// [module] : quiz d'un module (son titre, son meilleur score). `null`
  /// pour une séance de révision qui mélange plusieurs modules.
  /// [questions] : sous-liste à utiliser ; par défaut toutes celles du module.
  const QuizScreen({
    super.key,
    this.module,
    this.questions,
    this.titre,
    this.melanger = true,
    this.examen = false,
    this.duree,
  }) : assert(module != null || questions != null);

  final Module? module;
  final List<Question>? questions;
  final String? titre;

  /// Désactivable dans les tests pour un ordre prévisible.
  final bool melanger;

  /// Examen blanc : on enchaîne les questions sans feedback.
  final bool examen;

  /// Temps imparti (mode examen). Sans limite si null.
  final Duration? duree;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizSession _session = QuizSession(
    widget.questions ?? widget.module!.questions,
    melanger: widget.melanger,
  );

  /// Type ordre : ordre courant des réponses (index affichés), modifiable
  /// par glisser-déposer tant qu'on n'a pas validé.
  late List<int> _ordreEnCours = _ordreInitial();

  List<int> _ordreInitial() =>
      List.generate(_session.questionCourante.reponses.length, (i) => i);

  String get _titre => widget.titre ?? widget.module?.titre ?? 'Quiz';

  /// Chrono du mode examen.
  Timer? _chrono;
  late Duration _restant = widget.duree ?? Duration.zero;
  final Stopwatch _tempsUtilise = Stopwatch();

  @override
  void initState() {
    super.initState();
    _tempsUtilise.start();
    if (widget.duree != null) {
      _chrono = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _restant -= const Duration(seconds: 1);
        });
        if (_restant <= Duration.zero) _tempsEcoule();
      });
    }
  }

  @override
  void dispose() {
    _chrono?.cancel();
    super.dispose();
  }

  void _tempsEcoule() {
    _chrono?.cancel();
    _session.terminerMaintenant();
    _finir();
  }

  String get _chronoTexte {
    final m = _restant.inMinutes;
    final s = _restant.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _apresReponse() {
    // Petit retour haptique sur téléphone (sans effet sur le web).
    if (_session.derniereReussie) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _repondre(int index) {
    setState(() => _session.repondre(index));
    _apresReponse();
    // En examen, pas de correction : on enchaîne.
    if (widget.examen) _suivante();
  }

  void _validerOrdre() {
    setState(() => _session.repondreOrdre(_ordreEnCours));
    _apresReponse();
    if (widget.examen) _suivante();
  }

  void _suivante() {
    setState(() {
      _session.suivante();
      if (!_session.estTerminee) _ordreEnCours = _ordreInitial();
    });
    if (_session.estTerminee) _finir();
  }

  /// Enregistre le résultat et affiche l'écran Résultat.
  void _finir() {
    _chrono?.cancel();
    _tempsUtilise.stop();
    {
      final complet = widget.questions == null ||
          (widget.module != null &&
              widget.questions!.length == widget.module!.nombreQuestions);
      final etat = context.read<AppState>();
      // Réussi avant ce quiz ? Sert à fêter (ou non) le passage du seuil.
      final dejaReussi =
          widget.module != null && etat.moduleReussi(widget.module!);
      // La sauvegarde part en arrière-plan ; on n'attend pas pour afficher.
      etat.enregistrerResultat(
        _session,
        moduleComplet: complet ? widget.module : null,
        examen: widget.examen,
      );
      _afficherResultat(dejaReussi: dejaReussi);
    }
  }

  /// Remplace l'écran Quiz par l'écran Résultat : le bouton "retour" du
  /// résultat ramène donc à l'accueil, pas au milieu du quiz.
  void _afficherResultat({required bool dejaReussi}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultatScreen(
          titre: _titre,
          module: widget.module,
          dejaReussi: dejaReussi,
          score: _session.score,
          total: _session.total,
          questionsRatees: _session.questionsRatees,
          tempsUtilise: widget.examen ? _tempsUtilise.elapsed : null,
        ),
      ),
    );
  }

  void _revoirLaFiche() {
    final cible = context.read<AppState>().ficheDe(_session.questionCourante);
    if (cible == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FicheScreen(
          module: cible.module,
          index: cible.index,
          depuisQuiz: true,
        ),
      ),
    );
  }

  EtatReponse _etatQcm(int index) {
    if (!_session.aRepondu) return EtatReponse.neutre;
    if (_session.estBonneAffichee(index)) return EtatReponse.bonne;
    if (index == _session.choix) return EtatReponse.mauvaise;
    return EtatReponse.neutre;
  }

  @override
  Widget build(BuildContext context) {
    final question = _session.questionCourante;
    final theme = Theme.of(context);
    final aRepondu = _session.aRepondu;
    final reussie = _session.derniereReussie;
    final fiche = context.read<AppState>().ficheDe(question)?.fiche;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titre),
        actions: [
          if (widget.duree != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      color: _restant.inSeconds <= 60 ? Colors.red : null),
                  const SizedBox(width: 4),
                  Text(
                    _chronoTexte,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _restant.inSeconds <= 60 ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(value: _session.progression),
          const SizedBox(height: 8),
          Text(
            'Question ${_session.numero} / ${_session.total}',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 24),
          if (question.image case final image?) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/$image',
                fit: BoxFit.contain,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(question.enonce, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          if (question.type == TypeQuestion.ordre)
            ..._buildOrdre(theme)
          else
            for (var i = 0; i < _session.reponsesAffichees.length; i++)
              ReponseButton(
                texte: _session.reponsesAffichees[i],
                etat: _etatQcm(i),
                onPressed: aRepondu ? null : () => _repondre(i),
              ),
          if (aRepondu) ...[
            const SizedBox(height: 16),
            Card(
              color: reussie ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reussie ? 'Bonne réponse !' : 'Mauvaise réponse',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: reussie ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(question.explication,
                        style: const TextStyle(color: Colors.black87)),
                    if (!reussie && fiche != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _revoirLaFiche,
                          icon: const Icon(Icons.menu_book),
                          label: Text('Revoir la fiche « ${fiche.titre} »'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _suivante,
              child: Text(_session.estDerniere ? 'Terminer' : 'Question suivante'),
            ),
          ],
        ],
      ),
    );
  }

  /// Question "ordre" : liste réordonnable, puis bouton Valider.
  List<Widget> _buildOrdre(ThemeData theme) {
    final reponses = _session.reponsesAffichees;
    final aRepondu = _session.aRepondu;
    final scheme = theme.colorScheme;

    Widget ligne(int position, int indexAffiche) {
      Color? couleur;
      IconData? icone;
      if (aRepondu) {
        final ok = _session.estBienPlacee(position);
        couleur = ok ? Colors.green : Colors.red;
        icone = ok ? Icons.check_circle : Icons.cancel;
      }
      return Card(
        key: ValueKey(indexAffiche),
        color: couleur?.withValues(alpha: 0.12),
        shape: couleur == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: couleur, width: 2),
              ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Text('${position + 1}',
                style: TextStyle(color: scheme.onPrimaryContainer)),
          ),
          title: Text(reponses[indexAffiche]),
          trailing: aRepondu
              ? Icon(icone, color: couleur)
              : const Icon(Icons.drag_handle),
        ),
      );
    }

    return [
      Text(
        aRepondu
            ? 'Ton ordre :'
            : 'Glisse les étapes pour les remettre dans le bon ordre :',
        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.outline),
      ),
      const SizedBox(height: 8),
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: !aRepondu,
        onReorderItem: (ancien, nouveau) {
          if (aRepondu) return;
          setState(() {
            final item = _ordreEnCours.removeAt(ancien);
            _ordreEnCours.insert(nouveau, item);
          });
        },
        children: [
          for (var p = 0; p < _ordreEnCours.length; p++)
            ligne(p, _ordreEnCours[p]),
        ],
      ),
      if (!aRepondu) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _validerOrdre,
          icon: const Icon(Icons.check),
          label: const Text('Valider cet ordre'),
        ),
      ],
      if (aRepondu && !_session.derniereReussie) ...[
        const SizedBox(height: 12),
        Text('Le bon ordre :', style: theme.textTheme.titleSmall),
        for (var i = 0; i < _session.questionCourante.reponses.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${i + 1}. ${_session.questionCourante.reponses[i]}'),
          ),
      ],
    ];
  }
}
