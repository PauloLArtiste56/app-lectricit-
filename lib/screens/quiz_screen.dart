import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/quiz_session.dart';
import '../models/fiche.dart';
import '../models/module.dart';
import '../models/question.dart';
import '../widgets/bouton_relief.dart';
import '../widgets/couleurs_parcours.dart';
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
    final scheme = theme.colorScheme;
    final aRepondu = _session.aRepondu;
    final reussie = _session.derniereReussie;
    final etat = context.read<AppState>();
    final fiche = etat.ficheDe(question)?.fiche;
    final module = widget.module ?? etat.moduleDe(question);
    final chapitre = module == null ? null : etat.chapitreDe(module);
    final couleur = widget.examen
        ? scheme.primary
        : chapitre == null
            ? scheme.primary
            : couleurChapitre(chapitre);

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
          // Barre de progression épaisse, à la couleur du chapitre.
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _session.progression,
                  minHeight: 14,
                  color: couleur,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Question ${_session.numero} / ${_session.total}',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (question.image case final image?) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/$image',
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            question.enonce,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          if (question.type == TypeQuestion.ordre)
            ..._buildOrdre(theme)
          else
            for (var i = 0; i < _session.reponsesAffichees.length; i++)
              ReponseButton(
                texte: _session.reponsesAffichees[i],
                etat: _etatQcm(i),
                onPressed: aRepondu ? null : () => _repondre(i),
              ),
          // De la place pour que le panneau du bas ne cache rien.
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: _panneauBas(theme, question, fiche, couleur,
          aRepondu: aRepondu, reussie: reussie),
    );
  }

  /// Panneau fixé en bas : « Valider » pour une question ordre, puis la
  /// correction (vert ou rouge) avec le bouton pour continuer.
  Widget? _panneauBas(ThemeData theme, Question question, Fiche? fiche,
      Color couleur, {required bool aRepondu, required bool reussie}) {
    final scheme = theme.colorScheme;
    if (!aRepondu) {
      if (question.type != TypeQuestion.ordre) return null;
      return _CadreBas(
        couleur: scheme.surface,
        child: BoutonRelief(
          label: 'Valider cet ordre',
          icone: Icons.check,
          couleur: couleur,
          onPressed: _validerOrdre,
        ),
      );
    }
    final teinte = reussie ? Colors.green : Colors.red;
    final fond = reussie ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0);
    final encre = reussie ? const Color(0xFF3D8A00) : const Color(0xFFC62828);
    return _CadreBas(
      couleur: fond,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(reussie ? Icons.task_alt : Icons.highlight_off, color: encre, size: 28),
              const SizedBox(width: 8),
              Text(
                reussie ? 'Bonne réponse !' : 'Mauvaise réponse',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: encre,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question.explication,
            style: const TextStyle(color: Color(0xFF2E2E2E), height: 1.4),
          ),
          if (!reussie && fiche != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _revoirLaFiche,
                style: TextButton.styleFrom(foregroundColor: encre),
                icon: const Icon(Icons.menu_book),
                label: Text('Revoir la fiche « ${fiche.titre} »'),
              ),
            ),
          const SizedBox(height: 10),
          BoutonRelief(
            label: _session.estDerniere ? 'Terminer' : 'Question suivante',
            couleur: teinte.shade600,
            onPressed: _suivante,
          ),
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

/// Cadre du panneau du bas : fond coloré, coins arrondis en haut, respecte
/// la zone sûre du téléphone.
class _CadreBas extends StatelessWidget {
  const _CadreBas({required this.couleur, required this.child});

  final Color couleur;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: child,
        ),
      ),
    );
  }
}
