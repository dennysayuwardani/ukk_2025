import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({Key? key}) : super(key: key);

  @override
  State<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaPelangganController =
      TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _nomorTeleponController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  List<Map<String, dynamic>> pelanggan = [];
  List<Map<String, dynamic>> filteredPelanggan = [];

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
    _searchController
        .addListener(_filterPelanggan); // Tambahkan listener untuk pencarian
  }

  Future<void> _fetchPelanggan() async {
    try {
      final response = await supabase
          .from('pelanggan')
          .select()
          .order('nama_pelanggan', ascending: true);
      if (mounted) {
        setState(() {
          pelanggan = List<Map<String, dynamic>>.from(response);
          filteredPelanggan =
              List.from(pelanggan); // Mulai dengan menampilkan semua pelanggan
          isLoading =
              false; // Setelah data berhasil diambil, loading dihentikan
        });
      }
    } catch (e) {
      _showSnackBar(
          'Terjadi kesalahan saat mengambil data pelanggan: $e', Colors.red);
    }
  }

  void _filterPelanggan() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredPelanggan = pelanggan
          .where((pelanggan) => pelanggan['nama_pelanggan']
              .toLowerCase()
              .contains(query)) // Filter produk berdasarkan nama
          .toList();
    });
  }

  Future<bool> _isDuplicateName(String namaPelanggan, {int? excludeId}) async {
    final query =
        supabase.from('pelanggan').select().eq('nama_pelanggan', namaPelanggan);
    if (excludeId != null) {
      query.neq('pelanggan_id', excludeId);
    }
    final existing = await query;
    return existing.isNotEmpty;
  }

  Future<void> _addPelanggan() async {
    final String namaPelanggan = _namaPelangganController.text;
    final String alamat = _alamatController.text;
    final String nomorTelepon = _nomorTeleponController.text;

    if (await _isDuplicateName(namaPelanggan)) {
      _showSnackBar('Nama pelanggan sudah terdaftar!', Colors.red);
      return;
    }
    try {
      final response = await supabase.from('pelanggan').insert({
        'nama_pelanggan': namaPelanggan,
        'alamat': alamat,
        'nomor_telepon': nomorTelepon,
      }).select();

      // Beri waktu agar data tersimpan di database sebelum diperbarui di halaman penjualan
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _fetchPelanggan(); // Memuat ulang daftar pelanggan
        });
      });

      Navigator.pop(context); // Tutup dialog/tampilan input pelanggan

      if (response.isNotEmpty && mounted) {
        if (mounted) {
          setState(() {
            pelanggan.add(response.first);
            //Fungsi untuk mengurutkan nama pelanggan sesuai abjat tanpa refresh manual
            pelanggan.sort((a, b) => a['nama_pelanggan']
                .toLowerCase()
                .compareTo(b['nama_pelanggan'].toLowerCase()));
          });
        }
      }
      _showSnackBar('Pelanggan berhasil ditambahkan', Colors.green);
      _fetchPelanggan(); // Memanggil ulang data produk
    } catch (e) {
      _showSnackBar('Gagal menambahkan pelanggan: $e', Colors.red);
    }
  }

  Future<void> _editPelanggan(int id) async {
    final String namaPelanggan = _namaPelangganController.text;
    final String alamat = _alamatController.text;
    final String nomorTelepon = _nomorTeleponController.text;

    if (await _isDuplicateName(namaPelanggan, excludeId: id)) {
      _showSnackBar(
          'Nama pelanggan sudah digunakan pelanggan lain!', Colors.red);
      return;
    }
    try {
      final response = await supabase
          .from('pelanggan')
          .update({
            'nama_pelanggan': namaPelanggan,
            'alamat': alamat,
            'nomor_telepon': nomorTelepon,
          })
          .eq('pelanggan_id', id)
          .select();

      if (response.isNotEmpty) {
        if (mounted) {
          setState(() {
            final index =
                pelanggan.indexWhere((item) => item['pelanggan_id'] == id);
            if (index != -1) {
              pelanggan[index] = response.first;
            }
          });
        }
      }
      _showSnackBar('Pelanggan berhasil diperbarui', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Gagal mengedit pelanggan: $e', Colors.red);
    }
  }

  Future<void> _deletePelanggan(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Penghapusan'),
          content:
              const Text('Apakah Anda yakin ingin menghapus pelanggan ini?'),
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
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await supabase
                            .from('pelanggan')
                            .delete()
                            .eq('pelanggan_id', id);
                        if (mounted) {
                          setState(() {
                            pelanggan.removeWhere(
                                (item) => item['pelanggan_id'] == id);
                          });
                        }
                        _showSnackBar(
                            'Pelanggan berhasil dihapus', Colors.green);
                      } catch (e) {
                        _showSnackBar(
                            'Gagal menghapus pelanggan: $e', Colors.red);
                      }
                      Navigator.of(context).pop();
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showPelangganDialog({Map<String, dynamic>? pelangganData}) {
    _namaPelangganController.text = pelangganData?['nama_pelanggan'] ?? '';
    _alamatController.text = pelangganData?['alamat'] ?? '';
    _nomorTeleponController.text = pelangganData?['nomor_telepon'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              pelangganData == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaPelangganController,
                  decoration:
                      const InputDecoration(labelText: 'Nama Pelanggan'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),
                TextFormField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Alamat tidak boleh kosong'
                      : null,
                ),
                TextFormField(
                  controller: _nomorTeleponController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Nomor Telepon tidak boleh kosong';
                    if (!RegExp(r'^[0-9]+').hasMatch(value))
                      return 'Nomor Telepon harus berupa angka';
                    return null;
                  },
                ),
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
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (pelangganData == null) {
                          _addPelanggan();
                        } else {
                          _editPelanggan(pelangganData['pelanggan_id']);
                        }
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Pelanggan...',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : pelanggan.isEmpty
                    ? const Center(
                        child: Text('Tidak ada pelanggan!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 10,
                          childAspectRatio: 4,
                        ),
                        itemCount: filteredPelanggan.length,
                        itemBuilder: (context, index) {
                          final item = filteredPelanggan[index];
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
                                      Text(item['nama_pelanggan'] ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold)),
                                      Text('Alamat: ${item['alamat']}',
                                          style: GoogleFonts.poppins()),
                                      Text(
                                          'Nomor Telepon: ${item['nomor_telepon']}',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _showPelangganDialog(
                                          pelangganData: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deletePelanggan(
                                          item['pelanggan_id']),
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
        heroTag: 'fab3',
        onPressed: () => _showPelangganDialog(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
