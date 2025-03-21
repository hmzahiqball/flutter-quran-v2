import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/surah_screen.dart';
import 'screens/jadwal_screen.dart';
import 'provider/settings_provider.dart';
import 'services/notification_service.dart';

// void main() {
//   runApp(const QuranApp());
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadTheme();
  
  runApp(
    ChangeNotifierProvider.value( // Menggunakan instance yang sudah dibuat
      value: settingsProvider,
      child: const QuranApp(),
    ),
  );
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(), // Slide seperti iOS
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), // iOS default slide
          },
        ),
        fontFamily: GoogleFonts.outfit().fontFamily,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF564f47),
          onPrimary: Color(0xFF564f47),
          secondary: Color(0xFF8b7458),
          onSecondary: Color(0xFF8b7458),
          surface: Color(0xFFffecdc),
          onSurface: Color(0xFFffecdc),
          error: Color(0xFF6C4E31),
          onError: Color(0xFF6C4E31),
          background: Color(0xFFF9F9F9),
        ),
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(), // Slide seperti iOS
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), // iOS default slide
          },
        ),
        fontFamily: GoogleFonts.outfit().fontFamily,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFFc2b59b),
          onPrimary: Color(0xFF2a241f),
          secondary: Color(0xFFb29571),
          onSecondary: Color(0xFF1f1a16),
          surface: Color(0xFF2a241f),
          onSurface: Color(0xFFe8dcc9),
          error: Color(0xFFd19b69),
          onError: Color(0xFF3e2b20),
          background: Color(0xFF1f1a16),
          onBackground: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      themeMode: settingsProvider.themeMode,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/surah': (context) => const SurahPage(),
        '/jadwal': (context) => const JadwalPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const splashScreen();
  }
}
