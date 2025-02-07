import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/login_page.dart';
import 'package:ukk_2025/user_page.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://bnhdsiglgsdupjhuaokd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuaGRzaWdsZ3NkdXBqaHVhb2tkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg3MTQwNjgsImV4cCI6MjA1NDI5MDA2OH0.StaWjf1jxSCYGg1Nn-7bANwKwAg9VDsMIBm3NzjP7gQ',
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
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<String?>(
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainPage();
        }
        return const LoginPage();
      }, future: null,),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  //List halaman yang ssui dengan index
  final List<Widget> _pages = [
    const UserPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[
          _selectedIndex], //kode utk menamplkan halaman sesuai dengan index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white30,
        items: [BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined))],
      ),
    );
  }
}
