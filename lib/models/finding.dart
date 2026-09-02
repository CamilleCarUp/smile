/// Ein Befund zu einer Rechnung.
///
/// Bewusst getrennt von [TariffLine.flagged]: Manche Befunde betreffen eine
/// einzelne Position, andere das Preisniveau der ganzen Rechnung.
enum FindingKind {
  /// Der Faktor zwischen Taxpunkten und Franken liegt ueber dem, was der
  /// Tarif fuer Privatpatienten zulaesst. Rein rechnerisch belegbar.
  factorAboveTariffMaximum,
}

class InvoiceFinding {
  final FindingKind kind;

  /// Kurzfassung fuer die Anzeige.
  final String title;

  /// Was die App gerechnet hat — damit der Befund nachvollziehbar bleibt und
  /// nicht als Orakelspruch dasteht.
  final String explanation;

  /// Der beobachtete und der zulaessige Wert, fuer die Anzeige.
  final double? observed;
  final double? allowed;

  /// Betrag, um den die Rechnung ueber dem zulaessigen Rahmen liegt.
  final double? excessChf;

  const InvoiceFinding({
    required this.kind,
    required this.title,
    required this.explanation,
    this.observed,
    this.allowed,
    this.excessChf,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'title': title,
        'explanation': explanation,
        'observed': observed,
        'allowed': allowed,
        'excessChf': excessChf,
      };

  factory InvoiceFinding.fromJson(Map<String, dynamic> json) => InvoiceFinding(
        kind: FindingKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => FindingKind.factorAboveTariffMaximum,
        ),
        title: json['title'] as String,
        explanation: json['explanation'] as String,
        observed: (json['observed'] as num?)?.toDouble(),
        allowed: (json['allowed'] as num?)?.toDouble(),
        excessChf: (json['excessChf'] as num?)?.toDouble(),
      );
}
