// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/providers/search_provider.dart';
import 'presentation/providers/streaming_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/pages/home_page.dart';

import 'dart:async';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => StreamingProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => HomeProvider()..init('en-US')),
        ],
        child: const LeMovieApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('GLOBAL ERROR: $error');
    debugPrint('STACK TRACE: $stack');
  });
}

class LeMovieApp extends StatelessWidget {
  const LeMovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LE MOVIE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // Proper Black
        primaryColor: const Color(0xFF00D1FF), // Matte Cyan
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: const TextStyle(letterSpacing: -1.2, fontWeight: FontWeight.w800),
          titleLarge: const TextStyle(letterSpacing: -0.5, fontWeight: FontWeight.w600),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D1FF),
          secondary: Color(0xFF00D1FF), 
          surface: Color(0xFF0D0D0D), // Matte surface
          background: Colors.black,
        ),
        useMaterial3: true,
        dividerColor: Colors.white10,
      ),
      home: const HomePage(),
    );
  }
}
