import 'package:flutter/material.dart';

import '../state/sperr_controller.dart';
import '../theme/app_theme.dart';

/// Was vor der App steht, solange sie gesperrt ist.
///
/// Kein Weg vorbei: Es gibt hier nichts ausser dem Entsperren. Wer die
/// Abfrage abbricht, sieht sie wieder -- nicht den Verlauf.
///
/// Liegt als Ueberlagerung ueber der ganzen App (siehe main.dart), nicht als
/// eigene Route. Sonst waere ein bereits geoeffneter Bildschirm oberhalb der
/// Sperre stehengeblieben -- und damit sichtbar.
class SperrScreen extends StatefulWidget {
  const SperrScreen({super.key});

  @override
  State<SperrScreen> createState() => _SperrScreenState();
}

class _SperrScreenState extends State<SperrScreen> {
  bool _abgelehnt = false;

  @override
  void initState() {
    super.initState();
    // Gleich fragen, statt den Nutzer erst auf einen Knopf tippen zu lassen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fragen());
  }

  Future<void> _fragen() async {
    final erkannt = await sperrController.entsperren();
    if (!mounted) return;
    setState(() => _abgelehnt = !erkannt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand500,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 56, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Smile ist gesperrt',
                  style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _abgelehnt
                      ? 'Nicht erkannt. Versuch es nochmals — oder nimm den Code deines Geräts.'
                      : 'Entsperre mit Fingerabdruck, Gesicht oder dem Code deines Geräts.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, height: 1.45),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: sperrController,
                  builder: (context, _) => ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint_rounded, size: 20),
                    label: Text(_abgelehnt ? 'Nochmals versuchen' : 'Entsperren'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brand600,
                    ),
                    onPressed: sperrController.fragtGerade ? null : _fragen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
