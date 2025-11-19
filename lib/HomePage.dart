import 'package:flutter/material.dart';
import 'package:vista/log_in_page.dart';
import 'package:vista/utility/ColorsApp.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsApp().primary,
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(onPressed: (){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }, icon: Icon(Icons.logout, color: ColorsApp().primaryTextColor,))
      ],
      ),
      
      body: Placeholder(),
    );
  }
}
