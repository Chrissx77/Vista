import 'package:flutter/material.dart';
import 'package:vista/auth/auth_client.dart';
import 'package:vista/auth/auth_gate.dart';
import 'package:vista/base_client.dart';
import 'package:vista/log_in_page.dart';
import 'package:vista/utility/ColorsApp.dart';

import 'models/Pointview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Pointview> pointViews = [];

  @override
  void initState() {
    loadPointView();
    super.initState();
  }

  void loadPointView() async {
    pointViews = await BaseClient().getPointview();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorsApp.primary,
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () async {
              Pointview pointView = Pointview();

              pointView.name = "Belladonna";
              pointView.region = "Sicilia";
              pointView.city = "Catania";

              await BaseClient().sendPointview(pointView);

            //   Creare una tabella users in schema.publ su supabase che inserisce
            //   gli utenti che registri su schema.auth. In modo da collegare questa
            //   nuova tabella a quella dei PointView e capire quale usare ha
            //   inserito i PointView

            },
            icon: Icon(Icons.add, color: ColorsApp.primaryTextColor),
          ),
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
            },
            icon: Icon(Icons.logout, color: ColorsApp.primaryTextColor),
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: pointViews.length,
        itemBuilder: (context, index) {
          var poitView = pointViews[index];

          return Text(poitView.name ?? "");
        },
      ),
    );
  }
}
