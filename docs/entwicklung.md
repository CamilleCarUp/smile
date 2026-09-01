# Entwicklungsumgebung

Diese Seite hält fest, was zum Aufsetzen nötig war — inklusive der Punkte, an
denen es beim ersten Mal geklemmt hat.

## Voraussetzungen

| Werkzeug | Version / Hinweis |
|---|---|
| Flutter SDK | 3.47.2 (entpackt nach `C:\src\flutter`) |
| Android Studio | für SDK-Verwaltung, nicht als Editor nötig |
| Android SDK Platform | 34 und 36 |
| Android SDK Command-line Tools | nötig für `flutter doctor --android-licenses` |
| NDK | 28.2.13676358 (exakt diese Version, via SDK Manager → „Show Package Details") |
| Windows Developer Mode | muss **an** sein |

## Stolpersteine (alle schon aufgetreten)

**`flutter` wird nicht erkannt**
`C:\src\flutter\bin` muss in die Umgebungsvariable **`Path`** eingetragen
werden — nicht als neue Variable namens „Flutter" anlegen.

**„Building with plugins requires symlink support"**
Windows Developer Mode aktivieren: `start ms-settings:developers` → Toggle an.

**„Android sdkmanager not found"**
Android Studio → SDK Manager → Tab *SDK Tools* → „Android SDK Command-line
Tools (latest)" anhaken.

**„Android license status unknown" bleibt trotz akzeptierter Lizenzen**
Bekannter offener Flutter-Bug ([flutter/flutter#191487](https://github.com/flutter/flutter/issues/191487))
aus dem Übergang von `sdkmanager` zur neuen Android-CLI. Kosmetisch, blockiert
nichts.

**NDK-Version nicht gefunden**
SDK Manager → *SDK Tools* → „Show Package Details" → NDK (Side by side) → exakt
die von Flutter geforderte Version installieren.

**`checkDebugAarMetadata` schlägt fehl (compileSdk)**
`flutter_plugin_android_lifecycle` verlangt compileSdk ≥ 36, einzelne Plugins
(`file_picker`) kompilieren noch gegen 34. Gelöst über eine zentrale Anhebung
für alle Android-Subprojekte in `android/build.gradle.kts`. Der Block ist dort
kommentiert und kann raus, sobald die Plugins nachgezogen haben.

**Kamera-Button tut scheinbar nichts**
Fehlende `CAMERA`-Berechtigung im `AndroidManifest.xml`. `image_picker`
scheitert dann still. Nach Manifest-Änderungen ist ein **vollständiger
Neustart** der App nötig — Hot Reload reicht nicht.

## Test auf echtem Gerät ohne Kabel

Falls der USB-Anschluss nicht mitspielt: **Wireless Debugging**.

1. Am Telefon: *Settings → Developer options → Wireless debugging* einschalten
2. *Pair device with pairing code* antippen
3. Am PC: `adb pair <IP>:<Port>` mit dem angezeigten Code
4. `flutter devices` — das Gerät taucht per mDNS automatisch auf,
   ein zusätzliches `adb connect` ist **nicht** nötig
5. `flutter run -d <Geräte-ID>`

## Tests ausführen

```bash
flutter test
```

Läuft ohne Gerät, dauert Sekunden. Vor jedem Commit sinnvoll.

Bei Widget-Tests ist das Standard-Testfenster **800 × 600** Pixel — deutlich
kleiner als ein modernes Handy. Layout-Überläufe fallen dadurch im Test auf,
bevor sie ein Nutzer mit kleinem Display sieht. Genau so wurde der
Scroll-Fehler im Upload-Screen gefunden.

## Bekannte Warnungen (unkritisch)

- **KGP-Warnung zu `pdfx`**: Das Plugin nutzt noch das alte Kotlin-Gradle-Plugin.
  Künftige Flutter-Versionen werden das nicht mehr bauen — beobachten, ob
  `pdfx` nachzieht.
- **Gradle „restricted method in java.lang.System"**: Warnung der JVM,
  unbedenklich.

## Arbeitsteilung mit Claude

Claude bearbeitet die Quelldateien direkt im Ordner `C:\Users\camil\source`
über die Geräte-Verbindung. Flutter-, Gradle- und adb-Befehle laufen auf
diesem Rechner — Claudes eigene Umgebung hat kein Android SDK und keinen
Zugriff auf pub.dev.
