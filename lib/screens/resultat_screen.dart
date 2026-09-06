import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/quetes.dart';
import '../models/module.dart';
import '../models/question.dart';
import '../widgets/couleurs_parcours.dart';
import 'module_screen.dart';
import 'quiz_screen.dart';

/// Écran Résultat : score, questions ratées, bouton "Refaire les ratées".
/// Quand le module vient d'être réussi, on le fête et on propose le module
/// suivant du parcours.
class ResultatScreen extends StatelessWidget {
  const ResultatScreen({
    super.key,
    required this.titre,
    this.module,
    required this.score,
    required this.total,
    required this.questionsRatees,
    this.dejaReussi = false,
    this.tempsUtilise,
    this.eclair = false,
    this.recordAvant = 0,
    this.meilleurCombo = 0,
    this.couronnesAvant = 0,
  });

  final String titre;

  /// Module du quiz, `null` pour une révision multi-modules.
  final Module? module;
  final int score;
  final int total;
  final List<Question> questionsRatees;

  /// Le module était déjà réussi avant ce quiz : pas de fanfare.
  final bool dejaReussi;

  /// Durée de l'épreuve (mode examen), affichée sous le score.
  final Duration? tempsUtilise;

  /// Mode éclair : on compare au record d'avant ce quiz.
  final bool eclair;
  final int recordAvant;

  /// Meilleur enchaînement de bonnes réponses pendant le quiz.
  final int meilleurCombo;

  /// Couronnes du module avant ce quiz, pour annoncer les nouvelles.
  final int couronnesAvant;

  void _refaireLesRatees(BuildContext context) {
    // On remplace l'écran Résultat par un nouveau quiz limité aux ratées,
    // pour ne pas empiler les écrans à chaque tentative.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          titre: titre,
          module: module,
          questions: questionsRatees,
        ),
      ),
    );
  }

  void _retourParcours(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _ouvrirSuivant(BuildContext context, Module suivant) {
    // On revient au parcours puis on ouvre le module suivant : le bouton
    // retour du module ramène ainsi au chemin.
    Navigator.of(context)
      ..popUntil((route) => route.isFirst)
      ..push(MaterialPageRoute<void>(
        builder: (_) => ModuleScreen(module: suivant),
      ));
  }

  /// Ce qu'il fallait répondre, en une ligne.
  String _bonneReponse(Question q) => switch (q.type) {
        TypeQuestion.qcm ||
        TypeQuestion.image =>
          'Bonne réponse : ${q.reponses[q.bonne]}',
        TypeQuestion.ordre => 'Bon ordre : ${q.reponses.join(' → ')}',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final etat = context.watch<AppState>();
    final sansFaute = questionsRatees.isEmpty;
    final nouveauRecord = eclair && score > recordAvant && score > 0;
    final m = module;
    final reussi = m != null && etat.moduleReussi(m);
    final suivant = m == null ? null : etat.moduleSuivant(m);
    final chapitre = m == null ? null : etat.chapitreDe(m);
    final chapitreFini = m != null &&
        chapitre != null &&
        chapitre.modulesIds.last == m.id &&
        etat.chapitreComplet(chapitre);

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          if (reussi && !dejaReussi)
            _Fanfare(
              titre: chapitreFini ? 'Chapitre terminé !' : 'Module réussi !',
              sousTitre: chapitreFini
                  ? '« ${chapitre.titre} » est complet. Bravo !'
                  : suivant == null
                      ? 'Tu as fini le parcours. Chapeau !'
                      : 'Le module suivant est débloqué.',
            )
          else if (nouveauRecord)
            const _Fanfare(
              titre: 'Nouveau record !',
              sousTitre: 'Ton meilleur score en mode éclair.',
            )
          else
            Text(
              sansFaute ? 'Sans faute !' : 'Quiz terminé',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
          const SizedBox(height: 8),
          // Le score « compte » de 0 jusqu'à sa valeur.
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              '$v / $total',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                color: sansFaute || reussi
                    ? Colors.green.shade700
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${AppState.xpPour(score)} XP',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Nouvelle couronne de maîtrise sur le module.
          if (m != null && etat.couronnes(m) > couronnesAvant)
            _Bandeau(
              icone: Icons.workspace_premium,
              couleur: const Color(0xFFB88A00),
              texte: 'Couronne ${etat.couronnes(m)} sur 3 : '
                  '${switch (etat.couronnes(m)) {
                1 => 'module réussi',
                2 => 'sans faute',
                _ => 'confirmé en révision',
              }} !',
            ),
          // Quêtes accomplies et badges débloqués par ce quiz.
          for (final r in etat.recompensesRecentes)
            _Bandeau(
              icone: Icons.flag,
              couleur: Colors.amber.shade800,
              texte: 'Quête accomplie : ${_titreQuete(r.id)}  (+${r.xp} XP)',
            ),
          for (final b in etat.badgesRecents)
            _Bandeau(
              icone: b.icone,
              couleur: Colors.purple.shade400,
              texte: 'Nouveau badge : ${b.titre}',
            ),
          if (eclair && !nouveauRecord && recordAvant > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Record : $recordAvant / $total',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (meilleurCombo >= 3) ...[
            const SizedBox(height: 8),
            Text(
              'Meilleur combo : ×$meilleurCombo',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (tempsUtilise case final t?) ...[
            const SizedBox(height: 8),
            Text(
              'Temps : ${t.inMinutes} min ${(t.inSeconds % 60).toString().padLeft(2, '0')} s',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (m != null && !reussi) ...[
            const SizedBox(height: 8),
            Text(
              'Il faut ${(m.nombreQuestions * AppState.seuilReussite).ceil()} '
              'questions réussies sur ${m.nombreQuestions} pour débloquer la '
              'suite (${etat.questionsReussies(m)} pour l\'instant).',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          if (!sansFaute) ...[
            Text('À revoir', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final question in questionsRatees)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.close, color: Colors.red),
                  title: Text(question.enonce),
                  subtitle: Text(_bonneReponse(question)),
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (reussi && suivant != null) ...[
            FilledButton.icon(
              onPressed: () => _ouvrirSuivant(context, suivant),
              icon: const Icon(Icons.arrow_forward),
              label: Text('Module suivant : ${suivant.titre}'),
            ),
            const SizedBox(height: 8),
          ],
          if (!sansFaute) ...[
            (reussi ? OutlinedButton.icon : FilledButton.icon)(
              onPressed: () => _refaireLesRatees(context),
              icon: const Icon(Icons.replay),
              label: Text('Refaire les ratées (${questionsRatees.length})'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () => _retourParcours(context),
            child: const Text('Retour au parcours'),
          ),
        ],
      ),
    );
  }
}

/// Trophée qui grossit à l'apparition, avec le message de félicitations.
class _Fanfare extends StatelessWidget {
  const _Fanfare({required this.titre, required this.sousTitre});

  final String titre;
  final String sousTitre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, valeur, enfant) =>
              Transform.scale(scale: valeur, child: enfant),
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: vertReussi,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: vertReussiFonce, offset: Offset(0, 6))],
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 52),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          titre,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(sousTitre,
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Retrouve le titre d'une quête à partir de l'identifiant de sa
/// récompense (`quete:<id>:<date>`).
String _titreQuete(String idRecompense) {
  final parts = idRecompense.split(':');
  if (parts.length < 2) return idRecompense;
  for (final q in Quete.toutes) {
    if (q.id == parts[1]) return q.titre;
  }
  return parts[1];
}

/// Petit bandeau coloré : quête accomplie, badge gagné.
class _Bandeau extends StatelessWidget {
  const _Bandeau({required this.icone, required this.couleur, required this.texte});

  final IconData icone;
  final Color couleur;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: couleur),
            ),
          ),
        ],
      ),
    );
  }
}
