import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/parametres.dart';
import 'stats_screen.dart';

/// Numéro de version affiché dans « À propos » (à mettre à jour avec
/// `pubspec.yaml`).
const String versionApp = '0.1.0';

/// Écran Paramètres : apparence, apprentissage, examen, données, à propos.
/// Chaque changement est sauvegardé immédiatement.
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  Future<void> _modifier(BuildContext context, Parametres nouveaux) =>
      context.read<AppState>().modifierParametres(nouveaux);


  Future<void> _importer(BuildContext context) async {
    final controleur = TextEditingController();
    final texte = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer une progression'),
        content: TextField(
          controller: controleur,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Colle ici le code exporté',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controleur.text),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (texte == null || !context.mounted) return;
    final ok = await context.read<AppState>().importerProgression(texte);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Progression importée.'
          : 'Ce code n\'est pas un export valide. Rien n\'a été modifié.'),
    ));
  }

  Future<void> _reinitialiser(BuildContext context) async {
    final etat = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser la progression ?'),
        content: const Text(
          'Toutes les fiches lues, questions réussies et l\'historique '
          'seront effacés. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok == true) await etat.reinitialiser();
  }

  @override
  Widget build(BuildContext context) {
    final etat = context.watch<AppState>();
    final p = etat.parametres;
    final theme = Theme.of(context);

    Widget titre(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(s,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              )),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          titre('APPARENCE'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Thème'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'systeme', label: Text('Auto'), icon: Icon(Icons.phone_android)),
                  ButtonSegment(value: 'clair', label: Text('Clair'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: 'sombre', label: Text('Sombre'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {p.theme},
                onSelectionChanged: (s) => _modifier(context, p.copyWith(theme: s.first)),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Taille du texte'),
            trailing: DropdownButton<double>(
              value: p.tailleTexte,
              items: const [
                DropdownMenuItem(value: 0.9, child: Text('Petite')),
                DropdownMenuItem(value: 1.0, child: Text('Normale')),
                DropdownMenuItem(value: 1.1, child: Text('Grande')),
                DropdownMenuItem(value: 1.2, child: Text('Très grande')),
              ],
              onChanged: (t) =>
                  t == null ? null : _modifier(context, p.copyWith(tailleTexte: t)),
            ),
          ),
          titre('APPRENTISSAGE'),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Objectif du jour'),
            subtitle: const Text('XP à gagner chaque jour'),
            trailing: DropdownButton<int>(
              value: p.objectifXpJour,
              items: [
                for (final n in const [20, 50, 100, 200])
                  DropdownMenuItem(value: n, child: Text('$n XP')),
              ],
              onChanged: (n) =>
                  n == null ? null : _modifier(context, p.copyWith(objectifXpJour: n)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.today_outlined),
            title: const Text('Questions par séance du jour'),
            trailing: DropdownButton<int>(
              value: p.tailleSeance,
              items: [
                for (final n in const [5, 10, 15, 20])
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (n) => n == null ? null : _modifier(context, p.copyWith(tailleSeance: n)),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock_open_outlined),
            title: const Text('Parcours libre'),
            subtitle: const Text('Tous les modules ouverts, sans cadenas'),
            value: p.parcoursLibre,
            onChanged: (v) => _modifier(context, p.copyWith(parcoursLibre: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.shuffle),
            title: const Text('Mélanger les questions'),
            subtitle: const Text('Ordre des questions et des réponses'),
            value: p.melanger,
            onChanged: (v) => _modifier(context, p.copyWith(melanger: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibrations'),
            subtitle: const Text('Après chaque réponse, sur téléphone'),
            value: p.vibrations,
            onChanged: (v) => _modifier(context, p.copyWith(vibrations: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Sons'),
            subtitle: const Text('Bonne ou mauvaise réponse, combo, fin de quiz'),
            value: p.sons,
            onChanged: (v) => _modifier(context, p.copyWith(sons: v)),
          ),
          titre('EXAMEN BLANC'),
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text('Nombre de questions'),
            trailing: DropdownButton<int>(
              value: p.tailleExamen,
              items: [
                for (final n in const [10, 20, 30, 40])
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (n) => n == null ? null : _modifier(context, p.copyWith(tailleExamen: n)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Durée'),
            trailing: DropdownButton<int>(
              value: p.dureeExamenMinutes,
              items: [
                for (final n in const [5, 10, 15, 20, 30])
                  DropdownMenuItem(value: n, child: Text('$n min')),
              ],
              onChanged: (n) =>
                  n == null ? null : _modifier(context, p.copyWith(dureeExamenMinutes: n)),
            ),
          ),
          titre('DONNÉES'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Exporter la progression'),
            subtitle: Text(p.derniereSauvegarde.isEmpty
                ? 'Jamais sauvegardée : un code à copier et à garder'
                : 'Dernière sauvegarde le '
                    '${StatsScreen.formaterDate(p.derniereSauvegarde)}'),
            onTap: () => afficherExportProgression(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Importer une progression'),
            subtitle: const Text('Remplace la progression actuelle'),
            onTap: () => _importer(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('Réinitialiser la progression',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _reinitialiser(context),
          ),
          titre('À PROPOS'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('ElecApp $versionApp'),
            subtitle: Text(
              '${etat.modules.length} modules, ${etat.totalQuestions} questions. '
              'Apprendre les bases de l\'électricité et préparer l\'habilitation '
              'NF C 18-510. Contenu à but pédagogique : il ne remplace ni une '
              'formation ni la norme.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Boîte d'export de la progression : le code à copier et à garder.
/// Appelée depuis les paramètres et depuis le rappel des stats.
Future<void> afficherExportProgression(BuildContext context) async {
  final etat = context.read<AppState>();
  final texte = etat.exporterProgression();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exporter la progression'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Copie ce code et colle-le dans « Importer » sur '
              'ton autre appareil.'),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 140),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(texte,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Fermer'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: texte));
            // On note la date : le rappel de sauvegarde se tait.
            await etat.marquerSauvegarde();
            if (ctx.mounted) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copié.')),
              );
            }
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copier'),
        ),
      ],
    ),
  );
}
