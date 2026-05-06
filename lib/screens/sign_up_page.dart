import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vista/providers.dart';
import 'package:vista/utility/colors_app.dart';

const _eulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  bool _isPasswordVisible = false;
  bool _loading = false;
  bool _accepted = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _openEula() async {
    final uri = Uri.parse(_eulaUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci email e password.')),
      );
      return;
    }
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Per continuare devi accettare i Termini d\u2019uso.'),
        ),
      );
      return;
    }

    final scheme = Theme.of(context).colorScheme;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider).signUp(email, password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => _CheckEmailPage(email: email),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: TextStyle(color: scheme.onError)),
          backgroundColor: scheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Crea il tuo account', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Bastano una email e una password per iniziare.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'esempio@mail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _EulaConsent(
                accepted: _accepted,
                onChanged: (v) => setState(() => _accepted = v),
                onOpenEula: _openEula,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: (_loading || !_accepted) ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: ColorsApp.onPrimary,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text('Registrati'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EulaConsent extends StatelessWidget {
  const _EulaConsent({
    required this.accepted,
    required this.onChanged,
    required this.onOpenEula,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenEula;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onChanged(!accepted),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: accepted,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                      text: 'Accettando crei un account e acconsenti ai ',
                    ),
                    const TextSpan(
                      text: 'Termini d\u2019uso (EULA)',
                      style: TextStyle(
                        color: ColorsApp.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.left,
              ),
            ),
            IconButton(
              onPressed: onOpenEula,
              tooltip: 'Apri Termini d\u2019uso',
              icon: const Icon(Icons.open_in_new, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckEmailPage extends StatelessWidget {
  const _CheckEmailPage({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: ColorsApp.primarySoft,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 44,
                  color: ColorsApp.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Controlla la tua email',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  style: textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                      text:
                          'Ti abbiamo inviato un link di conferma a ',
                    ),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ColorsApp.onSurface,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '. Apri la mail per attivare l\u2019account, poi torna qui per accedere.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil(
                    (r) => r.isFirst,
                  ),
                  child: const Text('Torna al login'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
