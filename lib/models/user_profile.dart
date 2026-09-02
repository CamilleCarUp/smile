/// Die Angaben, die der Nutzer ueber sich hinterlegt.
///
/// Vor- und Nachname getrennt, weil der Brief an die Praxis siezt: Darunter
/// gehoert ein vollstaendiger Name, nicht nur ein Vorname. Ohne ihn endet die
/// Rueckfrage mit "Freundliche Grüsse" und nichts weiter, und die Praxis
/// weiss nicht, wer schreibt.
///
/// Fuer den Versand wird nichts davon gebraucht: Die App verschickt nicht
/// selbst, sondern oeffnet die Mail-App des Nutzers. Der Absender kommt von
/// dort, und die gesendete Nachricht liegt anschliessend in dessen Ordner
/// "Gesendet". Die [email] ist deshalb freiwillig und dient allein einer
/// Kopie an sich selbst.
///
/// Kein Kanton mehr: Die zustaendige Ombudsstelle ergibt sich aus dem Ort der
/// Praxis auf der Rechnung (siehe docs/ortsverzeichnis.md). Ein zweiter,
/// von Hand gepflegter Kanton haette dazu nur widersprechen koennen.
class UserProfile {
  final String firstName;
  final String lastName;
  final String email;

  const UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  /// Beide Namensteile vorhanden? Ohne das laesst die App den Nutzer nicht
  /// weiter -- eine unterschriebene Rueckfrage ist die halbe Miete.
  bool get isComplete =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  bool get wantsCopy => email.trim().isNotEmpty;

  /// Der Name, wie er unter dem Brief steht.
  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
  }) =>
      UserProfile(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Frueher wurde ein einzelnes Feld "name" gespeichert. Wer die App aus
    // jener Zeit hat, soll seinen Eintrag behalten statt ihn neu tippen zu
    // muessen: Alles bis zum letzten Leerzeichen wird Vorname, der Rest
    // Nachname.
    final alt = (json['name'] as String?)?.trim();
    if (alt != null && alt.isNotEmpty && json['firstName'] == null) {
      final trenner = alt.lastIndexOf(' ');
      return UserProfile(
        firstName: trenner > 0 ? alt.substring(0, trenner).trim() : alt,
        lastName: trenner > 0 ? alt.substring(trenner + 1).trim() : '',
        email: (json['email'] ?? '') as String,
      );
    }

    return UserProfile(
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
    );
  }
}
