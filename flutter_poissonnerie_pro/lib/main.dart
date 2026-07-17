import 'package:flutter/material';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PoissonnerieApp(),
    ),
  );
}

class PoissonnerieApp extends StatelessWidget {
  const PoissonnerieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poissonnerie Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          primary: const Color(0xFFFF6B6B),
          secondary: const Color(0xFF2E3A4B),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          headlineMedium: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          titleLarge: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          bodyLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFF334155)),
          bodyMedium: TextStyle(fontFamily: 'Inter', color: Color(0xFF475569)),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
