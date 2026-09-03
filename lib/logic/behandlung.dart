import '../models/request.dart';

/// Eine Sitzung: alles, was an einem Tag gemacht wurde.
///
/// Eine Rechnung ist keine Liste, sondern ein Ablauf. Steht auf jeder Zeile
/// ein Behandlungsdatum, laesst sich das zeigen: erst die Untersuchung, dann
/// die Betaeubung, dann die Fuellung -- und beim naechsten Termin der Rest.
class Sitzung {
  /// Null, wenn die Praxis keine Zeilendaten druckt. Dann gibt es genau eine
  /// Sitzung mit allen Positionen -- die Rechnung sagt nicht mehr.
  final DateTime? datum;
  final List<TariffLine> positionen;

  const Sitzung({required this.datum, required this.positionen});

  double get summe =>
      positionen.fold<double>(0, (s, l) => s + l.amountChf);
}

/// Gruppiert die Positionen nach Behandlungstag.
///
/// Ohne Datum bleibt alles zusammen; das ist kein Mangel, sondern die
/// ehrliche Wiedergabe dessen, was auf der Rechnung steht.
List<Sitzung> sitzungen(List<TariffLine> lines) {
  if (lines.isEmpty) return const [];

  final mitDatum = lines.where((l) => l.date != null).toList();
  if (mitDatum.isEmpty) {
    return [Sitzung(datum: null, positionen: List.of(lines))];
  }

  final nachTag = <DateTime, List<TariffLine>>{};
  final ohneDatum = <TariffLine>[];
  for (final line in lines) {
    final d = line.date;
    if (d == null) {
      ohneDatum.add(line);
      continue;
    }
    nachTag.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(line);
  }

  final tage = nachTag.keys.toList()..sort();
  return [
    for (final tag in tage) Sitzung(datum: tag, positionen: nachTag[tag]!),
    // Positionen ohne Datum ganz hinten, statt sie einem Tag zuzuschlagen,
    // an dem sie vielleicht nicht waren.
    if (ohneDatum.isNotEmpty) Sitzung(datum: null, positionen: ohneDatum),
  ];
}
