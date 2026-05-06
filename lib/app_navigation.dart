import 'package:flutter/material.dart';

/// Navigator del [MaterialApp] per push globali (es. recovery password quando non c’è lo stack login).
final GlobalKey<NavigatorState> vistaRootNavigatorKey =
    GlobalKey<NavigatorState>();
