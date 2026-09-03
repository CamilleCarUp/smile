/// Ein Befund zu einer Rechnung.
///
/// Bewusst getrennt von [TariffLine.flagged]: Manche Befunde betreffen eine
/// einzelne Position, andere das Preisniveau der ganzen Rechnung.
enum FindingKind {
  /// Der Faktor zwischen Taxpunkten und Franken liegt ueber dem, was der
  /// Tarif fuer Privatpatienten zulaesst. Rein rechnerisch belegbar.
  factorAboveTariffMaximum,

  /// Eine einzelne Position liegt ueber ihrer eigenen Obergrenze fuer
  /// Privatpatienten. Genauer als der Faktor ueber die ganze Rechnung: Eine
  /// teure Position geht im Durchschnitt sonst unter.
  positionAboveMaximum,

  /// Die Menge uebersteigt, was der Tarif fuer diese Position je Sitzung
  /// zulaesst.
  quantityAboveLimit,

  /// Dieselbe Position wurde innerhalb der Frist schon einmal verrechnet, die
  /// der Tarif nennt. Nur pruefbar, weil der Verlauf auf dem Geraet liegt.
  repeatedWithinPeriod,

  /// Zwei Positionen, die der Tarif nicht zusammen zulaesst.
  notCumulable,
}

class InvoiceFinding {
  final FindingKind kind;

  /// Kurzfassung fuer die Anzeige.
  final String title;

  /// Was die App gerechnet hat — damit der Befund nachvollziehbar bleibt und
  /// nicht als Orakelspruch dasteht.
  final String explanation;

  /// Derselbe Befund, wie er in der Rueckfrage an die Praxis steht.
  ///
  /// Zwei Fassungen, weil zwei Leser: Auf dem Bildschirm duzt die App ihren
  /// Nutzer und erklaert ihm ihre Rechnung. Im Brief an die Praxis steht
  /// dieselbe Feststellung sachlich und in der dritten Person -- und als
  /// Frage, nicht als Vorwurf. Fehlt sie, nimmt der Brief [explanation].
  final String? frage;

  /// Der beobachtete und der zulaessige Wert, fuer die Anzeige.
  final double? observed;
  final double? allowed;

  /// Betrag, um den die Rechnung ueber dem zulaessigen Rahmen liegt.
  final double? excessChf;

  const InvoiceFinding({
    required this.kind,
    required this.title,
    required this.explanation,
    this.frage,
    this.observed,
    this.allowed,
    this.excessChf,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'title': title,
        'explanation': explanation,
        'frage': frage,
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
        frage: json['frage'] as String?,
        observed: (json['observed'] as num?)?.toDouble(),
        allowed: (json['allowed'] as num?)?.toDouble(),
        excessChf: (json['excessChf'] as num?)?.toDouble(),
      );
}
