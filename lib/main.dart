import 'package:flutter/material.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const NutriMedApp());
}

class NutriMedApp extends StatelessWidget {
  const NutriMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NutriMed',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: AppRouter.router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1412),
      colorScheme: const ColorScheme.dark(
        primary:   Color(0xFF3ECF7C),
        secondary: Color(0xFF38B4A0),
        surface:   Color(0xFF161E1A),
        error:     Color(0xFFE85D4A),
      ),
      fontFamily: 'DMSans', // agregar en pubspec assets
      cardColor: const Color(0xFF1A2420),
    );
  }
}