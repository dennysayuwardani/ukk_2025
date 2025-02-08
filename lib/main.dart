import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/login_page.dart';
import 'package:ukk_2025/pelanggan_page.dart';
import 'package:ukk_2025/product_page.dart';
import 'package:ukk_2025/user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';


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

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') != null; // Cek apakah ada user yang login
  }

@override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kasir',
      debugShowCheckedModeBanner: false,
      home: Scaffold( // Tambahkan Scaffold agar tidak kosong
        body: FutureBuilder<bool>(
          future: _checkLoginStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData && snapshot.data == true) {
              return const MainPage(); // Jika sudah login, masuk ke halaman utama
            } else {
              return const LoginPage(); // Jika belum login, tampilkan halaman login
            }
          },
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const UserPage(),
    const ProdukPage(),
    const PelangganPage(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {}); // Tambahkan ini untuk memperbarui UI setelah logout

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['CRUD User', 'CRUD Produk', 'CRUD Pelanggan'];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined),label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.add_reaction_outlined), label: 'Pelanggan'),
        ],
      ),
    );
  }
}
