import 'package:flutter/material.dart';
import 'package:vista/HomePage.dart';
import 'package:vista/utility/ColorsApp.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: ColorsApp().backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Text(
                'VISTA',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: ColorsApp().primaryTextColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Il tuo mondo di ',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: ColorsApp().secondaryTextColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                style: TextStyle(color: ColorsApp().primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: ColorsApp().secondaryTextColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ColorsApp().textFieldBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                style: TextStyle(color: ColorsApp().primaryTextColor),
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: ColorsApp().secondaryTextColor),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ColorsApp().textFieldBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: ColorsApp().secondaryTextColor,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsApp().buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePage(title: "Vista"),
                    ),
                  );
                },
                child: Text(
                  'Accedi',
                  style: TextStyle(
                    color: ColorsApp().buttonTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // const SizedBox(height: 20),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     TextButton(
              //       onPressed: () {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(builder: (context) => const HomePage(title: "Vista")),
              //         );
              //       },
              //       child:  Text(
              //         "Don't have to account? Sign Up",
              //         style: TextStyle(color: ColorsApp().secondaryTextColor),
              //       ),
              //     ),
              //   ],
              // ),
              // TextButton(
              //   onPressed: () {
              //     // TODO: Naviga alla pagina di recupero password
              //   },
              //   child: Text(
              //     'Forgot Password?',
              //     style: TextStyle(color: ColorsApp().secondaryTextColor),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
