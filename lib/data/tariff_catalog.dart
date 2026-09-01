import 'dart:convert';

/// Die Referenz-Taxpunkte je Tarifposition.
///
/// Reines Dart (dart:convert ist Kernbibliothek, kein Flutter) — das Laden
/// der Asset-Datei passiert bewusst woanders, damit der Katalog in Tests
/// direkt aus einem String gebaut werden kann.
///
/// ⚠️ Die hinterlegten Werte sind provisorisch und teils aus CHF-Betraegen
/// der Thesis zurueckgerechnet. Siehe docs/tarifdaten.md — vor einer
/// Veroeffentlichung ist die Klaerung mit der SSO zwingend.
class TariffEntry {
  final String code;
  final String description;

  /// Taxpunkte. Der Preis ergibt sich als Taxpunkte × Taxpunktwert der Praxis.
  final double taxpunkte;

  const TariffEntry({
    required this.code,
    required this.description,
    required this.taxpunkte,
  });
}

class TariffCatalog {
  final Map<String, TariffEntry> _byCode;

  /// Herkunftsvermerk aus den Referenzdaten — damit die App anzeigen kann,
  /// auf welcher Grundlage sie urteilt.
  final String status;

  const TariffCatalog._(this._byCode, this.status);

  factory TariffCatalog.fromEntries(List<TariffEntry> entries, {String status = ''}) {
    return TariffCatalog._(
      {for (final e in entries) e.code: e},
      status,
    );
  }

  factory TariffCatalog.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final codes = (json['codes'] as List?) ?? const [];
    final entries = codes.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return TariffEntry(
        code: map['code'] as String,
        description: (map['description_de'] ?? map['description_en'] ?? '') as String,
        taxpunkte: (map['tp'] as num).toDouble(),
      );
    }).toList();

    final meta = json['_meta'] as Map<String, dynamic>?;
    return TariffCatalog.fromEntries(entries, status: (meta?['status'] ?? '') as String);
  }

  TariffEntry? lookup(String code) => _byCode[code];
  bool contains(String code) => _byCode.containsKey(code);
  Iterable<TariffEntry> get entries => _byCode.values;
  int get size => _byCode.length;
  bool get isEmpty => _byCode.isEmpty;
}
