import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ukk_2025/riwayat.dart';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({Key? key}) : super(key: key);

  @override
  _PenjualanPageState createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  int? selectedPelangganId;
  List<Map<String, dynamic>> pelangganList = [];
  List<Map<String, dynamic>> produkList = [];
  List<Map<String, dynamic>> produkTerpilih = [];
  double totalHarga = 0;

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
    _fetchProduk();

    // Auto refresh pelanggan jika kembali dari halaman tambah pelanggan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPelanggan();
    });
  }

  Future<void> _fetchPelanggan() async {
    final response = await supabase.from('pelanggan').select();
    if (mounted) {
      setState(() {
        pelangganList = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _fetchProduk() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('produk').select();
    if (mounted) {
      setState(() {
        produkList = response
            .map((p) => {
                  'produk_id': p['produk_id'],
                  'nama_produk': p['nama_produk'],
                  'harga': p['harga'],
                  'stok': p['stok'], // Stok produk diperbarui
                })
            .toList();
      });
    }
  }

  void _addProdukToCart(Map<String, dynamic> produk) {
    final existingProduk = produkTerpilih.firstWhere(
      (item) => item['produk_id'] == produk['produk_id'],
      orElse: () => {},
    );
    setState(() {
      if (existingProduk.isNotEmpty) {
        existingProduk['jumlah_produk']++;
        existingProduk['subtotal'] =
            existingProduk['jumlah_produk'] * produk['harga'];
      } else {
        produkTerpilih.add({
          ...produk,
          'jumlah_produk': 1,
          'subtotal': produk['harga'],
        });
      }
      totalHarga =
          produkTerpilih.fold(0, (sum, item) => sum + item['subtotal']);
    });
  }

  void _removeProdukFromCart(Map<String, dynamic> produk) {
    // Cari produk yang sudah ada di dalam cart
    final existingProduk = produkTerpilih.firstWhere(
      (item) => item['produk_id'] == produk['produk_id'],
      orElse: () => {},
    );

    // Cek jika produk ditemukan dan tidak kosong
    if (existingProduk.isNotEmpty) {
      setState(() {
        // Jika jumlah produk lebih dari 1, kurangi jumlahnya
        if (existingProduk['jumlah_produk'] > 1) {
          existingProduk['jumlah_produk']--;
          existingProduk['subtotal'] =
              existingProduk['jumlah_produk'] * produk['harga'];
        } else {
          // Jika jumlah produk 1, hapus dari cart
          produkTerpilih.remove(existingProduk);
        }
        // Update total harga setelah perubahan jumlah atau penghapusan
        totalHarga =
            produkTerpilih.fold(0, (sum, item) => sum + item['subtotal']);
      });
    }
  }

  void _goToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          pelangganId: selectedPelangganId,
          produkTerpilih: produkTerpilih,
          totalHarga: totalHarga,
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int?>(
              hint: Text(
                'Pilih Pelanggan',
                style: GoogleFonts.poppins(),
              ),
              value: selectedPelangganId,
              onChanged: (value) {
                setState(() {
                  selectedPelangganId = value;
                });
              },
              items: pelangganList.map((pelanggan) {
                return DropdownMenuItem<int?>(
                  value: pelanggan['pelanggan_id'],
                  child: Text(
                    pelanggan['nama_pelanggan'],
                    style: GoogleFonts.poppins(),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              hint: Text(
                'Pilih Produk',
                style: GoogleFonts.poppins(),
              ),
              onChanged: (value) {
                final produk =
                    produkList.firstWhere((p) => p['produk_id'] == value);

                if (produk['stok'] > 0) {
                  // Cek apakah stok masih tersedia
                  _addProdukToCart(produk);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stok ${produk['nama_produk']} habis!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              items: produkList.map((produk) {
                return DropdownMenuItem<int>(
                  value: produk['produk_id'],
                  enabled: produk['stok'] > 0, // Disable produk jika stoknya 0
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Pisahkan teks kiri & kanan
                    children: [
                      Text(
                        '${produk['nama_produk']} - Rp ${produk['harga']}',
                        style: GoogleFonts.poppins(
                          color: produk['stok'] > 0
                              ? Colors.black
                              : Colors.grey, // Warna abu jika stok habis
                        ),
                      ),
                      Text(
                        'Stok: ${produk['stok']}',
                        style: GoogleFonts.poppins(
                          color: produk['stok'] > 0
                              ? Colors.green
                              : Colors
                                  .red, // Hijau jika ada stok, merah jika habis
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: produkTerpilih.length,
                itemBuilder: (context, index) {
                  final produk = produkTerpilih[index];
                  return ListTile(
                    title: Text(
                      produk['nama_produk'],
                      style: GoogleFonts.poppins(),
                    ),
                    subtitle: Text(
                      'Subtotal: Rp ${produk['subtotal']}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () => _removeProdukFromCart(produk),
                        ),
                        Text(
                          '${produk['jumlah_produk']}',
                          style: GoogleFonts.poppins(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () => _addProdukToCart(produk),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text(
              'Total Harga: Rp $totalHarga',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: produkTerpilih.isEmpty ? null : _goToCheckout,
              child: Text(
                'Checkout',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final int? pelangganId; // Bisa null (jika Non-Member)
  final List<Map<String, dynamic>> produkTerpilih;
  final double totalHarga;

  const CheckoutPage({
    Key? key,
    required this.pelangganId,
    required this.produkTerpilih,
    required this.totalHarga,
  }) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Map<String, dynamic>? pelangganData; // Data pelanggan dari database
  bool isLoading = true; // Untuk loading data pelanggan

  @override
  void initState() {
    super.initState();
    _fetchPelangganData(); // Ambil data pelanggan saat halaman dibuka
  }

  Future<void> _fetchPelangganData() async {
    if (widget.pelangganId != null) {
      try {
        final supabase = Supabase.instance.client;
        final response = await supabase
            .from('pelanggan')
            .select()
            .eq('pelanggan_id', widget.pelangganId!)
            .single();

        setState(() {
          pelangganData = response;
          isLoading = false;
        });
      } catch (e) {
        print("Error mengambil data pelanggan: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _konfirmasiPembelian() async {
    try {
      final supabase = Supabase.instance.client;

      // Simpan data ke tabel penjualan
      final penjualanResponse = await supabase
          .from('penjualan')
          .insert({
            'tanggal_penjualan': DateTime.now().toIso8601String(),
            'total_harga': widget.totalHarga,
            'pelanggan_id': widget.pelangganId,
          })
          .select()
          .single();

      final penjualanId = penjualanResponse['penjualan_id'];

      // Simpan ke detail_penjualan
      for (var produk in widget.produkTerpilih) {
        await supabase.from('detail_penjualan').insert({
          'penjualan_id': penjualanId,
          'produk_id': produk['produk_id'],
          'jumlah_produk': produk['jumlah_produk'],
          'subtotal': produk['subtotal'],
        });

        // Update stok produk
        final int newStok = produk['stok'] - produk['jumlah_produk'];
        await supabase
            .from('produk')
            .update({'stok': newStok}).eq('produk_id', produk['produk_id']);
      }



      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Pembelian berhasil disimpan.'),
            backgroundColor: Colors.green),
      );
      // Pindah langsung ke halaman Riwayat setelah transaksi sukses
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RiwayatPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal menyimpan pembelian: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.blue,
        ),
        title: Text(
          'Struk Pembelian',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Pelanggan
                  Text(
                    widget.pelangganId != null
                        ? 'Pelanggan: ${pelangganData?['nama_pelanggan'] ?? "-"}'
                        : 'Pelanggan: Non-member',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  if (widget.pelangganId != null) ...[
                    Text(
                      'Alamat: ${pelangganData?['alamat'] ?? "-"}',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    Text(
                      'No. Telp: ${pelangganData?['nomor_telepon'] ?? "-"}',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Daftar Produk yang Dibeli
                  Text(
                    'Produk yang dibeli:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.produkTerpilih.length,
                      itemBuilder: (context, index) {
                        final produk = widget.produkTerpilih[index];
                        return ListTile(
                          title: Text(
                            produk['nama_produk'],
                            style: GoogleFonts.poppins(),
                          ),
                          subtitle: Text(
                            'Jumlah: ${produk['jumlah_produk']}, Subtotal: Rp ${produk['subtotal']}',
                            style: GoogleFonts.poppins(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Harga
                  Text(
                    'Total Harga: Rp ${widget.totalHarga}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Konfirmasi
                  ElevatedButton(
                    onPressed: _konfirmasiPembelian,
                    child: Text(
                      'Konfirmasi Pembelian',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
