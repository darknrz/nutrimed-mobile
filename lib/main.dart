import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      colorScheme: const ColorScheme.light(
        primary:   Color(0xFFFE2C55), // rojo TikTok
        secondary: Color(0xFF25F4EE), // cyan TikTok
        surface:   Color(0xFFFFFFFF),
        onSurface: Color(0xFF161823),
        error:     Color(0xFFFF6B35),
      ),
      fontFamily: 'DMSans',
      cardColor: const Color(0xFFFFFFFF),

      // AppBar limpio estilo TikTok
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF161823),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF161823),
        ),
      ),

      // Cards con sombra sutil
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEBEBEB), width: 0.5),
        ),
      ),

      // BottomNav estilo TikTok
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF161823),
        unselectedItemColor: Color(0xFF888888),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFE2C55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFE2C55), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF888888)),
      ),
    );
  }
}