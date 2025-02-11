import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';


class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> user = [];
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final response = await supabase
          .from('user')
          .select()
          .order('username', ascending: true);
      if (mounted) {
        setState(() {
          user = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar(
          'Terjadi kesalahan saat mengambil data user: $e', Colors.red);
    }
  }

  Future<void> _addUser() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    // Fungsi untuk menghentikan proses jika username sudah ada
    if (await _isUsernameExists(username)) {
      _showSnackBar('Username sudah digunakan!', Colors.red);
      return; // Hentikan proses jika username sudah ada
    }

    try {
      final response = await supabase.from('user').insert({
        'username': username,
        'password': password,
      }).select();

      if (response.isNotEmpty) {
        if (mounted) {
          setState(() {
            user.add(response.first);
          });
        }
      }
      _showSnackBar('User berhasil ditambahkan', Colors.green);
      await _fetchUser(); // Refresh data
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Gagal menambahkan user: $e', Colors.red);
    }
  }

  Future<void> _editUser(int id) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    if (await _isUsernameExists(username, excludeId: id)) {
      _showSnackBar('Username sudah digunakan oleh user lain!', Colors.red);
      return; // Hentikan proses jika username sudah ada
    }
    try {
      final response = await supabase
          .from('user')
          .update({
            'username': username,
            'password': password,
          })
          .eq('id', id)
          .select();

      if (response.isNotEmpty) {
        if (mounted) {
          setState(() {
            final index = user.indexWhere((item) => item['id'] == id);
            if (index != -1) {
              user[index] = response.first;
            }
          });
        }
      }
      _showSnackBar('User berhasil diperbarui', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Gagal mengedit user: $e', Colors.red);
    }
  }

  Future<void> _deleteUser(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus User'),
          content: const Text('Apakah Anda yakin ingin menghapus user ini?'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Batal', style: TextStyle(color: Colors.white),),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await supabase.from('user').delete().eq('id', id);
                        if (mounted) {
                          setState(() {
                            user.removeWhere((item) => item['id'] == id);
                          });
                        }
                        _showSnackBar('User berhasil dihapus', Colors.green);
                      } catch (e) {
                        _showSnackBar('Gagal menghapus user: $e', Colors.red);
                      }
                      Navigator.of(context).pop();
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Hapus', style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _isUsernameExists(String username, {int? excludeId}) async {
    final response = await supabase
        .from('user')
        .select()
        .eq('username', username)
        .maybeSingle(); // Ambil satu hasil saja jika ada

    if (response == null)
      return false; // Jika tidak ada data, berarti belum dipakai

    // Jika sedang mengedit, pastikan ID yang sama tidak terhitung sebagai duplikat
    if (excludeId != null && response['id'] == excludeId) return false;

    return true; // Jika ditemukan, berarti username sudah ada
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showUserDialog({Map<String, dynamic>? userData}) {
    _usernameController.text = userData?['username'] ?? '';
    _passwordController.text = userData?['password'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(userData == null ? 'Tambah User' : 'Edit User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(
                    controller: _usernameController, label: 'Username'),
                _buildInputField(
                    controller: _passwordController, label: 'Password'),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Batal', style: TextStyle(color: Colors.white),),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (userData == null) {
                          _addUser();
                        } else {
                          _editUser(userData['id']);
                        }
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Simpan', style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField(
      {required TextEditingController controller,
      required String label,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? '$label tidak boleh kosong' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : user.isEmpty
                    ? const Center(
                        child: Text('Tidak ada user!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 13,
                          mainAxisSpacing: 10,
                          childAspectRatio: 5,
                        ),
                        itemCount: user.length,
                        itemBuilder: (context, index) {
                          final item = user[index];
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(item['username'] ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold)),
                                      Text('Password: ${item['password']}',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _showUserDialog(userData: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteUser(
                                          item['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab1',
        onPressed: () => _showUserDialog(
        ),
        child: const Icon(Icons.add, color: Colors.white,),
        backgroundColor: Color(0xFF1A374D),
      ),
    );
  }
}
