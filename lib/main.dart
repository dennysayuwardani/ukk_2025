import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/login_page.dart';
import 'package:ukk_2025/pelanggan_page.dart';
import 'package:ukk_2025/penjualan_page.dart';
import 'package:ukk_2025/product_page.dart';
import 'package:ukk_2025/riwayat.dart';
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
    return prefs.getString('username') !=
        null; // Cek apakah ada user yang login
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kasir',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // Tambahkan Scaffold agar tidak kosong
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
    const PenjualanPage(),
    const RiwayatPage(),
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

    setState(() {});

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['User', 'Produk', 'Pelanggan', 'Penjualan', 'Riwayat'];
    
return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0), // Warna beige sebagai background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A374D), // Biru Navy untuk AppBar
        title: Text(
          titles[_currentIndex],
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.shifting, // Mode shifting agar teks hanya muncul saat dipilih
        selectedItemColor: const Color(0xFFFFD700), // Warna emas untuk item aktif
        unselectedItemColor: Colors.white,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.poppins(),

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: 'User',
            backgroundColor: Color(0xFF1A374D), // Biru Navy sebagai background
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.coffee),
            label: 'Produk',
            backgroundColor: Color(0xFF1A374D),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Pelanggan',
            backgroundColor: Color(0xFF1A374D),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Penjualan',
            backgroundColor: Color(0xFF1A374D),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Riwayat',
            backgroundColor: Color(0xFF1A374D),
          ),
        ],
      ),
    );  }
}
