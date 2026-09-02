import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../state/profile_controller.dart';
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

  @override
  void dispose() {
    _vorname.dispose();
    _nachname.dispose();
    _email.dispose();
    super.dispose();
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
    ));
    if (!mounted) return;

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
