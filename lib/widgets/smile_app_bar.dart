import 'package:flutter/material.dart';
import '../screens/entry_screen.dart';
import '../screens/welcome_screen.dart';

/// Gemeinsame AppBar für alle Screens nach dem Login.
/// [showHome] zeigt einen Home-Button (zurück zum Dashboard),
/// [showLogout] einen Logout-Button (zurück zum Entry-Screen).
PreferredSizeWidget smileAppBar(
  BuildContext context,
  String title, {
  bool showHome = false,
  bool showLogout = false,
}) {
  return AppBar(
    title: Text(title),
    actions: [
      if (showHome)
        IconButton(
          tooltip: 'Start',
          icon: const Icon(Icons.home_rounded),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      if (showLogout)
        IconButton(
          tooltip: 'Abmelden',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const EntryScreen()),
              (route) => false,
            );
          },
        ),
    ],
  );
}

void goToWelcome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    (route) => false,
  );
}
