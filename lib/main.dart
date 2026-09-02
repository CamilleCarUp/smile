import 'package:flutter/material.dart';
import 'data/plz_verzeichnis.dart';
import 'screens/profile_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/profile_controller.dart';
import 'state/requests_repository.dart';
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

  runApp(const SmileApp());
}

class SmileApp extends StatelessWidget {
  const SmileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Beim allerersten Start zuerst nach dem Namen fragen. Er steht als
      // Unterschrift unter der Rueckfrage -- ein unsignierter Brief an eine
      // Praxis faellt erst auf, wenn er schon raus ist.
      home: profileController.profile.isComplete
          ? const WelcomeScreen()
          : const ProfileScreen(firstRun: true),
    );
  }
}
