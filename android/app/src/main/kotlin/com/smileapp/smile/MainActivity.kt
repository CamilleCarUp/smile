package com.smileapp.smile

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity statt FlutterActivity: local_auth zeigt den
// Systemdialog als Fragment an und stuerzt sonst beim ersten Entsperren ab.
class MainActivity : FlutterFragmentActivity()
