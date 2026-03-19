import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:student_manager/firebase_options.dart';
import 'package:student_manager/config/supabase_config.dart';
import 'package:student_manager/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // App still runs with local fallback if Firebase is not configured yet.
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (_) {
    // App still runs without Supabase avatar uploads.
  }

  runApp(const StudentManagerApp());
}

class StudentManagerApp extends StatelessWidget {
  const StudentManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MH5_HAU',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)),
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      ),
      home: const HomeScreen(),
    );
  }
}
