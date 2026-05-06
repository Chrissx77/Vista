import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vista/providers.dart';
import 'package:vista/utility/colors_app.dart';

/// Schermata di reimpostazione password: usata dopo che l'utente ha cliccato
/// il link nella mail di reset. A quel punto Supabase emette l'evento
/// `passwordRecovery` e siamo loggati con un token speciale: serve solo
/// scegliere la nuova password.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Almeno 8 caratteri.';
    return null;
  }

  String? _validateConfirm(String? v) {
    if ((v ?? '') != _password.text) return 'Le password non coincidono.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider).updatePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password aggiornata.')),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: TextStyle(color: scheme.onError)),
          backgroundColor: scheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova password'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(
                'Scegli una nuova password',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Verrà usata da subito per accedere a Vista.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                validator: _validatePassword,
                decoration: InputDecoration(
                  labelText: 'Nuova password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: !_showPassword,
                validator: _validateConfirm,
                decoration: const InputDecoration(
                  labelText: 'Conferma password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: ColorsApp.onPrimary,
                          ),
                        )
                      : const Text('Aggiorna password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
