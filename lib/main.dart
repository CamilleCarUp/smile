import 'package:flutter/material.dart';
import 'data/plz_verzeichnis.dart';
import 'screens/profile_screen.dart';
import 'screens/sperr_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/profile_controller.dart';
import 'state/requests_repository.dart';
import 'state/sperr_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verlauf und Profil liegen verschluesselt auf dem Geraet und werden vor
  // dem ersten Bild geladen -- sonst blitzt kurz eine leere Liste auf.
  // Scheitert das Laden, startet die App trotzdem: lieber ohne Verlauf als
  // gar nicht.
  try {
    // Postleitzahl -> Kanton, fuer die zustaendige Ombudsstelle.
    await PlzVerzeichnis.laden();
    await profileController.load();
    await requestsRepository.load();
  } catch (_) {}

  // Ist die Sperre eingeschaltet, beginnt die App gesperrt -- noch bevor der
  // erste Bildschirm aufgebaut wird.
  sperrController.beimStart(aktiv: profileController.profile.appLock);

  runApp(const SmileApp());
}

class SmileApp extends StatefulWidget {
  const SmileApp({super.key});

  @override
  State<SmileApp> createState() => _SmileAppState();
}

class _SmileAppState extends State<SmileApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Beim Verlassen wieder zusperren. Wer sein Telefon aus der Hand gibt,
    // hat die App vorher meist nicht geschlossen.
    //
    // Nur bei paused/hidden, nicht bei inactive: Das kurze inactive beim
    // Herunterziehen der Benachrichtigungsleiste oder beim Systemdialog waere
    // sonst schon ein Grund zum Sperren.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      sperrController.inDenHintergrund(aktiv: profileController.profile.appLock);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Bewusst nur hell. Kein Versehen und keine offene Baustelle:
      // Zahnmedizin hat ein helles Bild, die Farben stammen aus dem
      // A/B-Test der Thesis, und ein halber Dunkelmodus -- Material-Widgets
      // dunkel, eigener Text weiterhin dunkelgrau auf dunkelgrau -- waere
      // schlechter als keiner. Wer ihn nachruesten will, muss die Palette
      // aus AppColors ins Theme verschieben; es sind 132 Stellen.
      themeMode: ThemeMode.light,
      // Die Sperre liegt ueber der ganzen App, nicht als eigene Route:
      // Sonst bliebe ein bereits geoeffneter Bildschirm oberhalb der Sperre
      // stehen und damit sichtbar.
      builder: (context, child) => AnimatedBuilder(
        animation: sperrController,
        builder: (context, _) => Stack(
          children: [
            if (child != null) child,
            if (sperrController.istGesperrt) const SperrScreen(),
          ],
        ),
      ),
      // Beim allerersten Start zuerst nach dem Namen fragen. Er steht als
      // Unterschrift unter der Rueckfrage -- ein unsignierter Brief an eine
      // Praxis faellt erst auf, wenn er schon raus ist.
      home: profileController.profile.isComplete
          ? const WelcomeScreen()
          : const ProfileScreen(firstRun: true),
    );
  }
}
