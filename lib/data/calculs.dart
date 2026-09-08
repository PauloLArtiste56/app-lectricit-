/// Calculs de la boîte à outils : loi d'Ohm, puissance, section de câble,
/// chute de tension, coût d'un appareil. Fonctions pures, sans Flutter,
/// pour être vérifiables directement par les tests.
library;

/// Résistivité en ohms·mm² par mètre, valeurs retenues pour le calcul de
/// chute de tension d'une installation (NF C 15-100).
const double resistiviteCuivre = 0.023;
const double resistiviteAluminium = 0.037;

class Calculs {
  /// Loi d'Ohm : U = R × I.
  static double tension(double r, double i) => r * i;

  /// I = U / R.
  static double courant(double u, double r) => r == 0 ? 0 : u / r;

  /// R = U / I.
  static double resistance(double u, double i) => i == 0 ? 0 : u / i;

  /// Puissance en monophasé : P = U × I.
  static double puissance(double u, double i) => u * i;

  /// I = P / U : le courant appelé par un appareil.
  static double courantPourPuissance(double p, double u) => u == 0 ? 0 : p / u;

  /// Énergie en kilowattheures : une puissance en watts pendant des heures.
  static double energie(double watts, double heures) => watts * heures / 1000;

  static double cout(double kwh, double prixKwh) => kwh * prixKwh;

  /// Sections normalisées en mm² et courant maximal du disjoncteur associé,
  /// pour des circuits domestiques en cuivre (NF C 15-100).
  static const List<(double section, int calibre)> sections = [
    (1.5, 16),
    (2.5, 20),
    (4, 25),
    (6, 32),
    (10, 40),
    (16, 63),
  ];

  /// Plus petite section normalisée qui supporte ce courant, `null` au-delà
  /// du tableau (il faut alors une étude, pas une appli).
  static double? sectionMinimale(double courantA) {
    for (final (section, calibre) in sections) {
      if (courantA <= calibre) return section;
    }
    return null;
  }

  /// Calibre de disjoncteur associé à une section.
  static int? calibrePour(double section) {
    for (final (s, calibre) in sections) {
      if (s == section) return calibre;
    }
    return null;
  }

  /// Chute de tension en volts sur la longueur d'un câble.
  /// Monophasé : le courant fait l'aller et le retour, d'où le facteur 2.
  /// Triphasé : facteur racine de 3.
  static double chuteTension({
    required double longueur,
    required double courantA,
    required double section,
    bool triphase = false,
    double resistivite = resistiviteCuivre,
  }) {
    if (section <= 0) return 0;
    final facteur = triphase ? 1.7320508075688772 : 2.0;
    return facteur * resistivite * longueur * courantA / section;
  }

  static double chutePourcent(double chute, double tensionNominale) =>
      tensionNominale == 0 ? 0 : chute / tensionNominale * 100;

  /// Chute maximale admise : 3 % pour l'éclairage, 5 % pour le reste.
  static const double chuteMaxEclairage = 3;
  static const double chuteMaxAutres = 5;
}
