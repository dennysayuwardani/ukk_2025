import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({Key? key}) : super(key: key);

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> riwayatPenjualan = [];

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  // Langkah 1: Mengambil data riwayat dari tabel 'penjualan' dan detail transaksi
  Future<void> fetchRiwayat() async {
    try {
      final response = await supabase
          .from('penjualan')
          .select(
              'penjualan_id, tanggal_penjualan, total_harga, pelanggan_id, pelanggan(nama_pelanggan)')
          .order('tanggal_penjualan', ascending: false);

      if (response.isNotEmpty) {
        final futures = response.map((penjualan) async {
          final detailResponse = await supabase
              .from('detail_penjualan')
              .select('produk_id, jumlah_produk, subtotal, produk(nama_produk)')
              .eq('penjualan_id', penjualan['penjualan_id']);

          if (detailResponse.isNotEmpty) {
            return {
              'penjualan': penjualan,
              'details': detailResponse,
            };
          }
          return null;
        }).toList();

        final results = await Future.wait(futures);

        if (mounted) {
          setState(() {
            riwayatPenjualan = results
                .where((result) => result != null)
                .cast<Map<String, dynamic>>()
                .toList();
          });
        }
      }
    } catch (e) {
      // Tambahkan pengecekan mounted sebelum menggunakan context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Terjadi kesalahan: $e'),
        ));
      }
    }
  }

  // Langkah 2: Menyegarkan data riwayat
  Future<void> refreshRiwayat() async {
    await fetchRiwayat();
  }

  // Langkah 3: Menghapus riwayat transaksi
  Future<void> deleteRiwayat(int penjualanId) async {
    try {
      await supabase
          .from('detail_penjualan')
          .delete()
          .eq('penjualan_id', penjualanId);
      await supabase.from('penjualan').delete().eq('penjualan_id', penjualanId);

      refreshRiwayat();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Riwayat transaksi berhasil dihapus'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: refreshRiwayat, // Menyegarkan data dengan geser ke bawah
        child: riwayatPenjualan.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: riwayatPenjualan.length,
                itemBuilder: (context, index) {
                  final transaksi = riwayatPenjualan[index];
                  final penjualan = transaksi['penjualan'];
                  final details = transaksi['details'];

                  // Menampilkan nama pelanggan di bagian atas transaksi
                  final namaPelanggan = penjualan['pelanggan'] != null
                      ? penjualan['pelanggan']['nama_pelanggan']
                      : 'Pelanggan Tidak Diketahui';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Transaksi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal: ${penjualan['tanggal_penjualan']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Pelanggan: $namaPelanggan', // Menampilkan Nama Pelanggan
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Total: Rp ${penjualan['total_harga'].toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Detail Produk
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: details.length,
                            itemBuilder: (context, detailIndex) {
                              final detail = details[detailIndex];
                              final namaProduk = detail['produk'] != null
                                  ? detail['produk']['nama_produk']
                                  : 'Produk tidak ditemukan';

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Produk: $namaProduk',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Jumlah: ${detail['jumlah_produk']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Subtotal: Rp ${detail['subtotal'].toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Tombol Hapus Riwayat
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Konfirmasi sebelum menghapus
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title:
                                        const Text('Hapus Riwayat Pembelian'),
                                    content: const Text(
                                        'Apakah Anda yakin ingin menghapus riwayat pembelian ini?'),
                                    actions: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(
                                                context), // Tutup dialog
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              deleteRiwayat(penjualan[
                                                  'penjualan_id']); // Hapus transaksi
                                              Navigator.pop(
                                                  context); // Tutup dialog
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.delete),
                            label: Text(
                              'Hapus Riwayat',
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              iconColor: Colors.red,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}