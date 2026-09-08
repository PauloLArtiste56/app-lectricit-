import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/calculs.dart';

/// Boîte à outils : les calculs du quotidien de l'électricien, avec le
/// résultat qui se met à jour au fur et à mesure de la saisie.
class OutilsScreen extends StatelessWidget {
  const OutilsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boîte à outils')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _OutilOhm(),
          _OutilPuissance(),
          _OutilSection(),
          _OutilChute(),
          _OutilCout(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Écrit un nombre à la française : virgule décimale, pas de zéros inutiles.
String formater(double valeur, {int decimales = 2}) {
  if (valeur.isNaN || valeur.isInfinite) return '—';
  var texte = valeur.toStringAsFixed(decimales);
  if (texte.contains('.')) {
    texte = texte.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return texte.replaceAll('.', ',');
}

/// Lit un nombre tapé par l'utilisateur, virgule ou point.
double? lireNombre(String texte) =>
    double.tryParse(texte.trim().replaceAll(',', '.'));

/// Cadre commun d'un outil : titre, contenu, et le résultat en bas.
class _Cadre extends StatelessWidget {
  const _Cadre({
    required this.icone,
    required this.titre,
    required this.enfants,
    this.resultat,
    this.note,
    this.alerte = false,
  });

  final IconData icone;
  final String titre;
  final List<Widget> enfants;

  /// Ligne de résultat, `null` tant que la saisie est incomplète.
  final String? resultat;
  final String? note;

  /// Le résultat sort des clous : cadre orange au lieu de vert.
  final bool alerte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final couleur = alerte ? Colors.orange.shade800 : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icone, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titre,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...enfants,
            if (resultat != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: couleur.withValues(alpha: 0.5)),
                ),
                child: Text(
                  resultat!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: couleur,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 8),
              Text(note!,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Champ de saisie d'un nombre, avec son unité.
class _Champ extends StatelessWidget {
  const _Champ({
    required this.controleur,
    required this.label,
    required this.unite,
    required this.onChanged,
  });

  final TextEditingController controleur;
  final String label;
  final String unite;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controleur,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        decoration: InputDecoration(
          labelText: label,
          suffixText: unite,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

// --- Loi d'Ohm --------------------------------------------------------------

class _OutilOhm extends StatefulWidget {
  const _OutilOhm();

  @override
  State<_OutilOhm> createState() => _OutilOhmState();
}

class _OutilOhmState extends State<_OutilOhm> {
  /// Ce qu'on cherche : 0 tension, 1 courant, 2 résistance.
  int _cible = 0;
  final _a = TextEditingController();
  final _b = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = lireNombre(_a.text);
    final b = lireNombre(_b.text);
    final (labelA, uniteA, labelB, uniteB) = switch (_cible) {
      0 => ('Résistance R', 'Ω', 'Courant I', 'A'),
      1 => ('Tension U', 'V', 'Résistance R', 'Ω'),
      _ => ('Tension U', 'V', 'Courant I', 'A'),
    };
    String? resultat;
    if (a != null && b != null) {
      resultat = switch (_cible) {
        0 => 'U = R × I = ${formater(Calculs.tension(a, b))} V',
        1 => 'I = U / R = ${formater(Calculs.courant(a, b))} A',
        _ => 'R = U / I = ${formater(Calculs.resistance(a, b))} Ω',
      };
    }

    return _Cadre(
      icone: Icons.calculate,
      titre: 'Loi d\'Ohm',
      resultat: resultat,
      note: 'U en volts, R en ohms, I en ampères.',
      enfants: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Tension')),
            ButtonSegment(value: 1, label: Text('Courant')),
            ButtonSegment(value: 2, label: Text('Résistance')),
          ],
          selected: {_cible},
          onSelectionChanged: (s) => setState(() => _cible = s.first),
        ),
        const SizedBox(height: 12),
        _Champ(
          controleur: _a,
          label: labelA,
          unite: uniteA,
          onChanged: (_) => setState(() {}),
        ),
        _Champ(
          controleur: _b,
          label: labelB,
          unite: uniteB,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

// --- Puissance et courant ---------------------------------------------------

class _OutilPuissance extends StatefulWidget {
  const _OutilPuissance();

  @override
  State<_OutilPuissance> createState() => _OutilPuissanceState();
}

class _OutilPuissanceState extends State<_OutilPuissance> {
  /// 0 : chercher la puissance. 1 : chercher le courant.
  int _cible = 1;
  final _tension = TextEditingController(text: '230');
  final _autre = TextEditingController();

  @override
  void dispose() {
    _tension.dispose();
    _autre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = lireNombre(_tension.text);
    final v = lireNombre(_autre.text);
    String? resultat;
    if (u != null && v != null) {
      resultat = _cible == 0
          ? 'P = U × I = ${formater(Calculs.puissance(u, v))} W'
          : 'I = P / U = ${formater(Calculs.courantPourPuissance(v, u))} A';
    }

    return _Cadre(
      icone: Icons.bolt,
      titre: 'Puissance et courant',
      resultat: resultat,
      note: 'Monophasé. Un appareil de 2 000 W sous 230 V appelle 8,7 A.',
      enfants: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Puissance')),
            ButtonSegment(value: 1, label: Text('Courant')),
          ],
          selected: {_cible},
          onSelectionChanged: (s) => setState(() => _cible = s.first),
        ),
        const SizedBox(height: 12),
        _Champ(
          controleur: _tension,
          label: 'Tension U',
          unite: 'V',
          onChanged: (_) => setState(() {}),
        ),
        _Champ(
          controleur: _autre,
          label: _cible == 0 ? 'Courant I' : 'Puissance P',
          unite: _cible == 0 ? 'A' : 'W',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

// --- Section et calibre -----------------------------------------------------

class _OutilSection extends StatefulWidget {
  const _OutilSection();

  @override
  State<_OutilSection> createState() => _OutilSectionState();
}

class _OutilSectionState extends State<_OutilSection> {
  final _courant = TextEditingController();

  @override
  void dispose() {
    _courant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final i = lireNombre(_courant.text);
    String? resultat;
    var alerte = false;
    if (i != null && i > 0) {
      final section = Calculs.sectionMinimale(i);
      if (section == null) {
        resultat = 'Au-delà de 63 A : ce tableau ne suffit plus.';
        alerte = true;
      } else {
        resultat = 'Section minimale ${formater(section)} mm², '
            'disjoncteur ${Calculs.calibrePour(section)} A';
      }
    }

    return _Cadre(
      icone: Icons.cable,
      titre: 'Section de câble',
      resultat: resultat,
      alerte: alerte,
      note: 'Cuivre, circuits domestiques. Une grande longueur ou un câble '
          'sous isolant peuvent imposer plus gros : vérifie la chute de tension.',
      enfants: [
        _Champ(
          controleur: _courant,
          label: 'Courant du circuit',
          unite: 'A',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (section, calibre) in Calculs.sections)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text('${formater(section)} mm² · $calibre A',
                    style: theme.textTheme.labelSmall),
              ),
          ],
        ),
      ],
    );
  }
}

// --- Chute de tension -------------------------------------------------------

class _OutilChute extends StatefulWidget {
  const _OutilChute();

  @override
  State<_OutilChute> createState() => _OutilChuteState();
}

class _OutilChuteState extends State<_OutilChute> {
  bool _triphase = false;
  final _longueur = TextEditingController();
  final _courant = TextEditingController();
  final _section = TextEditingController();

  @override
  void dispose() {
    _longueur.dispose();
    _courant.dispose();
    _section.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = lireNombre(_longueur.text);
    final i = lireNombre(_courant.text);
    final s = lireNombre(_section.text);
    String? resultat;
    var alerte = false;
    if (l != null && i != null && s != null && s > 0) {
      final chute = Calculs.chuteTension(
        longueur: l,
        courantA: i,
        section: s,
        triphase: _triphase,
      );
      final pourcent =
          Calculs.chutePourcent(chute, _triphase ? 400 : 230);
      alerte = pourcent > Calculs.chuteMaxAutres;
      resultat = 'Chute de ${formater(chute)} V, soit '
          '${formater(pourcent, decimales: 1)} %'
          '${alerte ? ' : trop, il faut une section plus grosse.' : ''}';
    }

    return _Cadre(
      icone: Icons.trending_down,
      titre: 'Chute de tension',
      resultat: resultat,
      alerte: alerte,
      note: 'Câble cuivre. Maximum admis : '
          '${formater(Calculs.chuteMaxEclairage)} % en éclairage, '
          '${formater(Calculs.chuteMaxAutres)} % pour les autres usages.',
      enfants: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Monophasé 230 V')),
            ButtonSegment(value: true, label: Text('Triphasé 400 V')),
          ],
          selected: {_triphase},
          onSelectionChanged: (s) => setState(() => _triphase = s.first),
        ),
        const SizedBox(height: 12),
        _Champ(
          controleur: _longueur,
          label: 'Longueur du câble',
          unite: 'm',
          onChanged: (_) => setState(() {}),
        ),
        _Champ(
          controleur: _courant,
          label: 'Courant',
          unite: 'A',
          onChanged: (_) => setState(() {}),
        ),
        _Champ(
          controleur: _section,
          label: 'Section',
          unite: 'mm²',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

// --- Coût d'un appareil -----------------------------------------------------

class _OutilCout extends StatefulWidget {
  const _OutilCout();

  @override
  State<_OutilCout> createState() => _OutilCoutState();
}

class _OutilCoutState extends State<_OutilCout> {
  final _puissance = TextEditingController();
  final _heures = TextEditingController();
  final _prix = TextEditingController(text: '0,20');

  @override
  void dispose() {
    _puissance.dispose();
    _heures.dispose();
    _prix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = lireNombre(_puissance.text);
    final h = lireNombre(_heures.text);
    final prix = lireNombre(_prix.text);
    String? resultat;
    if (p != null && h != null && prix != null) {
      final kwhJour = Calculs.energie(p, h);
      final coutMois = Calculs.cout(kwhJour * 30, prix);
      resultat = '${formater(kwhJour)} kWh par jour, soit '
          '${formater(coutMois)} € par mois';
    }

    return _Cadre(
      icone: Icons.euro,
      titre: 'Coût d\'un appareil',
      resultat: resultat,
      note: 'Sur 30 jours. Le prix du kWh est sur ta facture.',
      enfants: [
        _Champ(
          controleur: _puissance,
          label: 'Puissance',
          unite: 'W',
          onChanged: (_) => setState(() {}),
        ),
        _Champ(
          controleur: _heures,
          label: 'Heures par jour',
          unite: 'h',
          onChanged: (_) => setState(() {}),
        ),
        _Champ(
          controleur: _prix,
          label: 'Prix du kWh',
          unite: '€',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
