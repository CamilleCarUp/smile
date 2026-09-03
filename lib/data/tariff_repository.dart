import 'package:flutter/services.dart' show rootBundle;
import 'tariff_catalog.dart';

/// Laedt die Referenzdaten aus den App-Assets.
///
/// Bewusst getrennt vom [TariffCatalog] selbst: der Katalog ist reines Dart
/// und laesst sich in Tests aus einem String bauen; nur das Laden braucht
/// Flutter. Faellt das Laden aus, arbeitet die App mit leerem Katalog weiter
/// — der Resolver liest die Taxpunkte dann von der Rechnung.
class TariffRepository {
  /// Die vierzehn Positionen aus belegbaren Quellen. Liegt im Repository.
  static const seedPath = 'assets/reference-data/dentotar_seed.json';

  /// Der lizenzierte Katalog samt Bandbreite, Limitationen und
  /// Kumulationsverboten.
  ///
  /// Liegt **nicht** im Repository (siehe .gitignore und
  /// docs/tarif-branch.md). Ist die Datei da, arbeitet die App damit; fehlt
  /// sie, bleibt es beim Seed und die erweiterten Regeln pruefen nichts.
  static const vollstaendigPath = 'assets/reference-data/tarif_vollstaendig.json';

  TariffCatalog? _cached;

  Future<TariffCatalog> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    // Erst der vollstaendige Katalog, dann der Seed. Kein Fehler, wenn der
    // erste fehlt -- das ist der Normalfall ohne Lizenz.
    for (final pfad in const [vollstaendigPath, seedPath]) {
      try {
        final source = await rootBundle.loadString(pfad);
        final katalog = TariffCatalog.fromJsonString(source);
        if (!katalog.isEmpty) return _cached = katalog;
      } catch (_) {
        // naechster Pfad
      }
    }
    return _cached = TariffCatalog.fromEntries(const []);
  }

  /// Nur fuer Tests.
  void overrideWith(TariffCatalog catalog) => _cached = catalog;
}

final tariffRepository = TariffRepository();
