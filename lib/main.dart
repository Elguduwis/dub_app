import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MaterialApp(
        title: 'Dub App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: HomeScreen(),
        routes: {
          '/settings': (context) => SettingsScreen(),
        },
      ),
    );
  }
}
