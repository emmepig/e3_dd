import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// I TUOI FILE ESTERNI
import 'pages/settings_page.dart';
import 'pages/maps_page.dart';

import 'services/auth_provider.dart';
import 'services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialRoute = await AppSettings.getInitialRoute();
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => authProvider,
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: {
        '/maps': (context) => const MappaPage(),
        //'/clienti': (context) => const ClientiPage(),
        //'/ordini': (context) => const OrdiniPage(),
        '/impostazioni': (context) => const SettingsPage(),
      },
    );
  }
}
