import 'package:flutter/material.dart';
import '../state/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  void _register() {
    if (_emailCtrl.text.trim().isEmpty || _pwCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte E-Mail und Passwort angeben.')),
      );
      return;
    }
    authController.register(_emailCtrl.text.trim(), _pwCtrl.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Konto erstellt! Du kannst dich jetzt anmelden.')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrieren')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Konto erstellen',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextField(controller: _firstCtrl, decoration: const InputDecoration(labelText: 'Vorname')),
              const SizedBox(height: 12),
              TextField(controller: _lastCtrl, decoration: const InputDecoration(labelText: 'Nachname')),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-Mail (Benutzername)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Passwort'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _register, child: const Text('Registrieren')),
            ],
          ),
        ),
      ),
    );
  }
}
