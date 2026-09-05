import 'package:flutter/material.dart';

/// Icône associée à chaque module, par son identifiant dans `content.json`.
/// Un module inconnu reçoit une icône générique.
IconData iconePourModule(String moduleId) {
  return switch (moduleId) {
    'grandeurs' => Icons.bolt,
    'courant' => Icons.waves,
    'circuits' => Icons.account_tree,
    'symboles' => Icons.schema,
    'securite' => Icons.health_and_safety,
    _ => Icons.menu_book,
  };
}
