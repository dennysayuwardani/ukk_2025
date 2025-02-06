import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/login_page.dart';

Future<void> main() async {
await Supabase.initialize(
  url: 'https://bnhdsiglgsdupjhuaokd.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuaGRzaWdsZ3NkdXBqaHVhb2tkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTQwNjgsImV4cCI6MjA1NDI5MDA2OH0.StaWjf1jxSCYGg1Nn-7bANwKwAg9VDsMIBm3NzjP7gQ',
);
runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        home: LoginPage(),

        debugShowCheckedModeBanner: false,
        );
  }
}


