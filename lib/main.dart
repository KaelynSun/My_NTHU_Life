import 'package:flutter/material.dart';
import 'package:my_nthu_life/data/studentData.dart';
import 'package:my_nthu_life/screens/auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_nthu_life/theme/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'ai_service.dart';

// 1. Core State Management Provider imports added here
import 'package:provider/provider.dart';
import 'package:my_nthu_life/pet_files/pet_provider.dart'; // Verified provider path

// Core Firebase packages imported here
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

var kColorScheme = MaterialTheme.lightScheme();
var kDarkColorScheme = MaterialTheme.darkHighContrastScheme();

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
final totalCreditsNotifier = ValueNotifier<int>(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    print("🔑 [.env SECURE] Local environment file loaded successfully!");
  } catch (e) {
    print("⚠️ [.env WARNING] Could not find or read .env file: $e");
  }

  AIService().initialize();
  
  try {
    print("📡 [Firebase Test] Attempting connection initialization...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final currentApp = Firebase.app();
    print("---------------------------------------------------------");
    print("🎉 [Firebase SUCCESS] Connection Established Successfully!");
    print("📦 Connected Project ID: ${currentApp.options.projectId}");
    print("---------------------------------------------------------");
  } catch (e) {
    print("❌ [Firebase ERROR] Failed to connect to backend: $e");
  }

  await loadUsers();

  // 2. Wrap MyApp with MultiProvider so PetProvider is at the root level of the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PetProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: kDarkColorScheme,
            cardTheme: const CardThemeData().copyWith(
              color: kDarkColorScheme.secondaryContainer,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkColorScheme.primaryContainer,
                foregroundColor: kDarkColorScheme.onPrimaryContainer,
              ),
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          ),
          theme: ThemeData().copyWith(
            colorScheme: kColorScheme,
            appBarTheme: const AppBarTheme().copyWith(
              backgroundColor: kColorScheme.onPrimaryContainer,
              foregroundColor: kColorScheme.primaryContainer,
            ),
            cardTheme: const CardThemeData().copyWith(
              color: kColorScheme.secondaryContainer,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kColorScheme.primaryContainer,
              ),
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData().textTheme),
          ),
          themeMode: mode, 
          home: const Auth(), 
        );
      },
    );
  }
}