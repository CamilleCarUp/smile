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
/// Eine Mengenbeschraenkung, wie der Tarif sie zu einzelnen Positionen nennt.
///
/// Im Tarif steht das als Satz: "Maximal 6 mal pro Sitzung verrechenbar",
/// "Darf pro Patient innerhalb von 12 Monaten in der gleichen Praxis nur 1 mal
/// verrechnet werden". Hier steht dasselbe als pruefbare Angabe.
class Limitation {
  /// Hoechstmenge innerhalb des Bezugsrahmens.
  final int maxAnzahl;

  /// Bezugsrahmen. Null heisst: je Sitzung.
  final Duration? zeitraum;

  /// Gilt der Zeitraum nur fuer dieselbe Praxis? Der Tarif formuliert es so,
  /// und es ist der Unterschied zwischen einer belegbaren und einer
  /// uebergriffigen Pruefung.
  final bool gleichePraxis;

  /// Der Wortlaut aus dem Tarif -- damit ein Befund die Grundlage nennen kann
  /// und nicht als Behauptung der App dasteht.
  final String wortlaut;

  const Limitation({
    required this.maxAnzahl,
    required this.wortlaut,
    this.zeitraum,
    this.gleichePraxis = true,
  });

  bool get jeSitzung => zeitraum == null;
}

class TariffEntry {
  final String code;
  final String description;

  /// Taxpunkte. Der Preis ergibt sich als Taxpunkte × Taxpunktwert der Praxis.
  final double taxpunkte;

  /// Ober- und Untergrenze der Taxpunkte fuer Privatpatienten.
  ///
  /// Der Tarif nennt sie je Position ("TP (PP) max" / "TP (PP) min"). Damit
  /// wird aus einer Aussage ueber das Preisniveau der ganzen Rechnung eine
  /// ueber die einzelne Position. Null, solange der Katalog sie nicht
  /// enthaelt -- dann bleibt es beim bisherigen Faktorvergleich.
  final double? ppMax;
  final double? ppMin;

  /// Was die Position umfasst, in den Worten des Tarifs.
  final List<String> beinhaltet;

  /// Mengenbeschraenkungen dieser Position.
  final List<Limitation> limitationen;

  /// Codes, mit denen diese Position nicht zusammen verrechnet werden darf.
  final List<String> nichtKumulierbarMit;

  const TariffEntry({
    required this.code,
    required this.description,
    required this.taxpunkte,
    this.ppMax,
    this.ppMin,
    this.beinhaltet = const [],
    this.limitationen = const [],
    this.nichtKumulierbarMit = const [],
  });

  /// Traegt der Eintrag mehr als Taxpunkte? Entscheidet, ob die erweiterten
  /// Regeln ueberhaupt etwas pruefen koennen.
  bool get istVollstaendig =>
      ppMax != null || limitationen.isNotEmpty || nichtKumulierbarMit.isNotEmpty;
}

/// Ein Limitations-Eintrag aus der Katalogdatei.
///
/// `tage: null` heisst "je Sitzung"; sonst der Zeitraum in Tagen, wie ihn der
/// Tarif nennt (12 Monate = 365).
Limitation _limitationAus(Map<String, dynamic> map) => Limitation(
      maxAnzahl: (map['max'] as num).toInt(),
      wortlaut: (map['wortlaut'] ?? '') as String,
      zeitraum: map['tage'] == null
          ? null
          : Duration(days: (map['tage'] as num).toInt()),
      gleichePraxis: (map['gleiche_praxis'] ?? true) as bool,
    );

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
        ppMax: (map['tp_pp_max'] as num?)?.toDouble(),
        ppMin: (map['tp_pp_min'] as num?)?.toDouble(),
        beinhaltet: [for (final b in (map['beinhaltet'] as List?) ?? const []) b as String],
        nichtKumulierbarMit: [
          for (final c in (map['nicht_kumulierbar_mit'] as List?) ?? const []) c as String
        ],
        limitationen: [
          for (final raw in (map['limitationen'] as List?) ?? const [])
            _limitationAus(Map<String, dynamic>.from(raw as Map)),
        ],
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

  /// Enthaelt der Katalog die erweiterten Angaben (Bandbreite, Limitationen,
  /// Kumulationsverbote)? Falsch beim mitgelieferten Seed -- dann pruefen die
  /// erweiterten Regeln nichts, statt auf leeren Daten zu urteilen.
  bool get istVollstaendig => _byCode.values.any((e) => e.istVollstaendig);
}
