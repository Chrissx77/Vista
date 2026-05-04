import 'package:flutter/material.dart';
import 'package:vista/controllers/auth_controller.dart';
import 'package:vista/utility/colors_app.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isPasswordVisible = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
      appBar: AppBar(
        backgroundColor: ColorsApp.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'MODULO REGISTRAZIONE',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
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
                  onPressed: () async {
                    try {
                      await AuthController().signUp(
                        emailController.text.trim(),
                        passwordController.text.trim(),
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Registrazione avvenuta con successo.',
                            style: TextStyle(color: ColorsApp.onSuccess),
                          ),
                          backgroundColor: ColorsApp.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
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
