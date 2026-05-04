import 'package:flutter/material.dart';
import 'package:vista/controllers/auth_controller.dart';
import 'package:vista/screens/sign_up_page.dart';
import 'package:vista/utility/colors_app.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci email e password')),
      );
      return;
    }

    try {
      await AuthController().signIn(email, password);
    } catch (e) {
      if (mounted) {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: TextStyle(color: scheme.onError),
            ),
            backgroundColor: scheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'images/iconaApp.png',
                  width: 250,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: ColorsApp.iconPlaceholder,
                    );
                  },
                ),

                Text(
                  'Un nuovo punto di Vista.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall,
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'esempio@mail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: scheme.outline,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: login,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: const Center(
                      child: Text('ACCEDI'),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  'Non hai ancora un account?',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: const Center(
                      child: Text('REGISTRATI'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
