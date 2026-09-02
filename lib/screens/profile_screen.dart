import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../state/profile_controller.dart';
import '../state/requests_repository.dart';
import '../state/sperr_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'welcome_screen.dart';

/// Die Angaben, die der Nutzer ueber sich hinterlegt.
///
/// Zwei Auftritte: Beim ersten Start als Pflichteingabe ([firstRun] = true),
/// danach jederzeit ueber "Meine Angaben" zum Aendern.
///
/// Warum beim ersten Start verbindlich: Der Name steht als Unterschrift unter
/// der Rueckfrage. Fehlt er, geht ein unsignierter Brief an eine Praxis --
/// das faellt erst auf, wenn er schon raus ist. Lieber einmal vorher fragen.
class ProfileScreen extends StatefulWidget {
  final bool firstRun;
  const ProfileScreen({super.key, this.firstRun = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _vorname =
      TextEditingController(text: profileController.profile.firstName);
  late final _nachname =
      TextEditingController(text: profileController.profile.lastName);
  late final _email =
      TextEditingController(text: profileController.profile.email);

  String? _vornameFehler;
  String? _nachnameFehler;
  late bool _appLock = profileController.profile.appLock;

  @override
  void dispose() {
    _vorname.dispose();
    _nachname.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Einschalten nur, wenn das Geraet ueberhaupt sperren kann. Sonst haette
  /// der Nutzer eine Sperre, die ihn aussperrt statt zu schuetzen.
  Future<void> _sperreUmschalten(bool wert) async {
    if (!wert) {
      setState(() => _appLock = false);
      return;
    }
    final moeglich = await sperrController.istMoeglich();
    if (!mounted) return;
    if (!moeglich) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Auf diesem Gerät ist weder Fingerabdruck noch Code '
            'eingerichtet. Richte das zuerst in den Systemeinstellungen ein.'),
      ));
      return;
    }
    setState(() => _appLock = true);
  }

  /// Loescht Verlauf und Angaben unwiderruflich.
  ///
  /// Ohne diesen Weg waere die Zusage im Datenschutztext unwahr -- und
  /// "App deinstallieren" ist keine Antwort auf "ich will nur die Rechnungen
  /// weghaben".
  Future<void> _allesLoeschen() async {
    final sicher = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alle Daten löschen?'),
        content: const Text(
          'Der Verlauf mit allen erfassten Rechnungen sowie dein Name und deine '
          'E-Mail-Adresse werden von diesem Gerät gelöscht. Das lässt sich nicht '
          'rückgängig machen — es gibt keine Kopie, auch keine in einer Cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
    if (sicher != true || !mounted) return;

    await requestsRepository.clearAll();
    await profileController.clear();
    if (!mounted) return;

    // Ohne Namen beginnt die App von vorn -- derselbe Zustand wie nach der
    // Installation.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ProfileScreen(firstRun: true)),
      (route) => false,
    );
  }

  Future<void> _speichern() async {
    final vorname = _vorname.text.trim();
    final nachname = _nachname.text.trim();

    setState(() {
      _vornameFehler = vorname.isEmpty ? 'Bitte ausfüllen' : null;
      _nachnameFehler = nachname.isEmpty ? 'Bitte ausfüllen' : null;
    });
    if (vorname.isEmpty || nachname.isEmpty) return;

    await profileController.save(UserProfile(
      firstName: vorname,
      lastName: nachname,
      email: _email.text.trim(),
      appLock: _appLock,
    ));
    if (!mounted) return;

    // Scheitert das Schreiben -- meist ein voller Speicher --, darf die App
    // nicht "Gespeichert." melden und weitergehen: Der Name steht dann beim
    // naechsten Start nicht unter der Rueckfrage.
    if (profileController.saveFailed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Konnte nicht gespeichert werden — vermutlich ist der Speicher '
            'deines Geräts voll. Schaff etwas Platz frei und versuch es nochmals.'),
        duration: Duration(seconds: 8),
      ));
      return;
    }

    if (widget.firstRun) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gespeichert.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inhalt = Scaffold(
      appBar: widget.firstRun
          ? AppBar(title: const Text('Willkommen bei Smile'), automaticallyImplyLeading: false)
          : smileAppBar(context, 'Meine Angaben', showHome: true),
      // Der Knopf haengt am unteren Rand, nicht am Ende der Liste: Auf einem
      // kleinen Telefon stuende er sonst unter dem Sichtfeld, und beim ersten
      // Start kaeme man ohne Scrollen nicht weiter.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                    Text(
                      widget.firstRun
                          ? 'Bevor es losgeht: Wie heisst du? Dein Name steht als Unterschrift '
                              'unter der Rückfrage an die Praxis — ein unsignierter Brief wirkt '
                              'unseriös und bleibt oft unbeantwortet.'
                          : 'Diese Angaben bleiben auf deinem Gerät und werden nur für den '
                              'Anfragetext verwendet.',
                      style: const TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _vorname,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Vorname',
                        errorText: _vornameFehler,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nachname,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Nachname',
                        errorText: _nachnameFehler,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail (freiwillig)',
                        helperText: 'Nur für eine Kopie an dich selbst.',
                      ),
                    ),
                    // Beim ersten Start nicht: Da geht es um den Namen,
                    // nicht um Einstellungen. Und es gibt noch nichts zu
                    // loeschen.
                    if (!widget.firstRun) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _appLock,
                        onChanged: _sperreUmschalten,
                        title: const Text('App sperren',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text(
                          'Fragt beim Start und nach jeder Pause nach Fingerabdruck, '
                          'Gesicht oder dem Code deines Geräts.',
                          style: TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
                        ),
                      ),
                    ],
                    if (!widget.firstRun) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _allesLoeschen,
                          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Alle Daten löschen'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.slate400),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Als Absender brauchst du die Adresse nicht: Smile verschickt nicht '
                              'selbst, sondern öffnet deine Mail-App. Der Absender kommt von dort, '
                              'und die gesendete Nachricht liegt anschliessend in deinem Ordner '
                              '"Gesendet". Alle Angaben bleiben auf diesem Gerät.',
                              style: TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _speichern,
                  child: Text(widget.firstRun ? "Los geht's" : 'Speichern'),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Beim ersten Start nicht zurueckkommen: Ohne Namen gibt es nichts zu tun.
    return widget.firstRun ? PopScope(canPop: false, child: inhalt) : inhalt;
  }
}
