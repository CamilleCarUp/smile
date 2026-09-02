import 'package:flutter/material.dart';

/// Gemeinsame AppBar der App.
/// [showHome] zeigt einen Home-Button (zurueck zum Startbildschirm).
///
/// Einen Logout gibt es bewusst nicht: Die App kennt keine Konten und
/// bewahrt nichts auf, es gibt also keine Sitzung zu beenden.
PreferredSizeWidget smileAppBar(
  BuildContext context,
  String title, {
  bool showHome = false,
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
    ],
  );
}
