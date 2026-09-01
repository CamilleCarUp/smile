import 'package:flutter/material.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController(text: 'testuser');
  final _pwCtrl = TextEditingController(text: '1234');
  bool _showError = false;

  void _handleLogin() {
    if (authController.tryLogin(_userCtrl.text.trim(), _pwCtrl.text)) {
      setState(() => _showError = false);
      goToWelcome(context);
    } else {
      setState(() => _showError = true);
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anmelden')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.person_outline, size: 40, color: AppColors.brand500),
                      const SizedBox(height: 8),
                      const Text('Anmelden', textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(labelText: 'Benutzername'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Passwort'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zugangsdaten würden per E-Mail zugestellt.')),
                          ),
                          child: const Text('Zugangsdaten vergessen?', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      if (_showError)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('Ungültige Zugangsdaten.',
                              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _handleLogin, child: const Text('Einloggen')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
