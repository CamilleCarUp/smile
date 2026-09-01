import 'package:flutter/services.dart' show rootBundle;
import 'tariff_catalog.dart';

/// Laedt die Referenzdaten aus den App-Assets.
///
/// Bewusst getrennt vom [TariffCatalog] selbst: der Katalog ist reines Dart
/// und laesst sich in Tests aus einem String bauen; nur das Laden braucht
/// Flutter. Faellt das Laden aus, arbeitet die App mit leerem Katalog weiter
/// — der Resolver liest die Taxpunkte dann von der Rechnung.
class TariffRepository {
  static const assetPath = 'assets/reference-data/dentotar_seed.json';

  TariffCatalog? _cached;

  Future<TariffCatalog> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    try {
      final source = await rootBundle.loadString(assetPath);
      return _cached = TariffCatalog.fromJsonString(source);
    } catch (_) {
      return _cached = TariffCatalog.fromEntries(const []);
    }
  }

  /// Nur fuer Tests.
  void overrideWith(TariffCatalog catalog) => _cached = catalog;
}

final tariffRepository = TariffRepository();
