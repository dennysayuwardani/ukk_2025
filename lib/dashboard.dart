import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<Map<String, dynamic>> petugas = []; // Daftar user

  @override
  void initState() {
    super.initState();
    _fetchUserFromSupabase(); // Ambil data user saat halaman dimuat
  }

  // Fetch user dari Supabase
  Future<void> _fetchUserFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('user')
          .select('*')
          .order('username', ascending: true);

      if (mounted) {
        setState(() {
          petugas = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e', isError: true);
    }
  }

  // Tambah user baru ke Supabase
  Future<void> _addUser(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      _showMessage('Username dan Password tidak boleh kosong', isError: true);
      return;
    }

    try {
      final existingUser = await Supabase.instance.client
          .from('user')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        _showMessage('Username sudah digunakan', isError: true);
        return;
      }

      await Supabase.instance.client.from('user').insert({
        'username': username,
        'password': password, // Simpan password
      });

      _showMessage('User berhasil ditambahkan');
      await _fetchUserFromSupabase(); // Refresh data
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e', isError: true);
    }
  }

  // Update user di Supabase
  Future<void> _updateUser(int id, String username, String password) async {
    if (username.trim().isEmpty) {
      _showMessage('Username tidak boleh kosong', isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('user').update({
        'username': username,
        'password': password, // Update password jika diedit
      }).eq('id', id);

      _showMessage('User berhasil diperbarui');
      await _fetchUserFromSupabase(); // Refresh data
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e', isError: true);
    }
  }

  // Konfirmasi sebelum menghapus user
  Future<void> _confirmDeleteUser(int id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus user ini?'),
          actions: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Posisi kiri & kanan
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red, // Warna background merah
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10), // Padding agar proporsional
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white), // Warna teks putih
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteUser(id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Warna background hijau
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10), // Padding agar seimbang
                  ),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.white), // Warna teks putih
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Hapus petugas dari Supabase
  Future<void> _deleteUser(int id) async {
    try {
      await Supabase.instance.client.from('user').delete().eq('id', id);
      _showMessage('Akun berhasil dihapus');
      _fetchUserFromSupabase(); // Update tampilan
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e', isError: true);
    }
  }

  // Menampilkan pesan
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Menampilkan dialog tambah/edit petugas
  void _showUserDialog({int? id, String? username, String? password}) {
    final TextEditingController usernameController =
        TextEditingController(text: username ?? '');
    final TextEditingController passwordController =
        TextEditingController(text: password ?? '');
    bool isPasswordVisible =
        false; // Tambahkan variabel untuk kontrol visibilitas password

// Form key untuk validasi
    final _formDialogKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(id == null ? 'Tambah User' : 'Edit User'),
              content: Form(
                key: _formDialogKey, // Gunakan FormKey untuk validasi
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formDialogKey.currentState!.validate()) {
                          // Jika form valid, simpan data
                          if (id == null) {
                            await _addUser(usernameController.text,
                                passwordController.toString());
                          } else {
                            await _updateUser(id, usernameController.text,
                                passwordController.toString());
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: Text(id == null ? 'Tambah' : 'Simpan'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CRUD User',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: petugas.length,
          itemBuilder: (context, index) {
            final petugasItem = petugas[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(petugasItem['username']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showUserDialog(
                        id: petugasItem['id'],
                        username: petugasItem['username'],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteUser(petugasItem['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab3',
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
