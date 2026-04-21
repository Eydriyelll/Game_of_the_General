// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/game_provider.dart';
import 'screens/lobby_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GameOfGeneralsApp());
}

class GameOfGeneralsApp extends StatelessWidget {
  const GameOfGeneralsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'Games of the General',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const LobbyScreen(),
      ),
    );
  }
}
