import 'package:chatting_application/screens/splash_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  try {
    // Set system UI mode and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://lzupgfgcenwtrwnlobgw.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6dXBnZmdjZW53dHJ3bmxvYmd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5MDQ1ODgsImV4cCI6MjA1NTQ4MDU4OH0.Jbt_5hJRdGVYDlrdF5uPORUks4D8tWwTWfBUq58RVNI',
    );
    print('Supabase initialized successfully');

    // Initialize Firebase
    await _initializeFirebase();
    print('Firebase initialized successfully');

    // Run the app
    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    print('Error during initialization: $e');
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
     
      title: 'We Chat',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      );
    
    
  }
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}