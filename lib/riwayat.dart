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
  List<Map<String, dynamic>> filteredRiwayatPenjualan = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
    searchController.addListener(() {
        filterRiwayat(searchController.text);
  });
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
            filteredRiwayatPenjualan = riwayatPenjualan;
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

  void filterRiwayat(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRiwayatPenjualan = riwayatPenjualan;
      } else {
        filteredRiwayatPenjualan = riwayatPenjualan.where((transaksi) {
          final penjualan = transaksi['penjualan'];
          final namaPelanggan = penjualan['pelanggan'] != null
              ? penjualan['pelanggan']['nama_pelanggan'].toLowerCase()
              : 'pelanggan tidak diketahui';
          final tanggalPenjualan = penjualan['tanggal_penjualan'].toString();

          return namaPelanggan.contains(query.toLowerCase()) ||
              tanggalPenjualan.contains(query);
        }).toList();
      }
    });
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
      body: Column(children: [
        // TextField untuk Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: "Cari berdasarkan nama atau tanggal",
              labelStyle: GoogleFonts.poppins(fontSize: 14),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: filterRiwayat,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refreshRiwayat, // Menyegarkan data dengan geser ke bawah
            child: filteredRiwayatPenjualan.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredRiwayatPenjualan.length,
                    itemBuilder: (context, index) {
                      final transaksi = filteredRiwayatPenjualan[index];
                      final penjualan = transaksi['penjualan'];
                      final details = transaksi['details'];

                      // Menampilkan nama pelanggan di bagian atas transaksi
                      final namaPelanggan = penjualan['pelanggan'] != null
                          ? penjualan['pelanggan']['nama_pelanggan']
                          : 'Pelanggan Tidak Diketahui';

                      double pajak =
                          penjualan['total_harga'] * 0.10; // Pajak 10%
                      double biayaLayanan = 2000; // Biaya layanan tetap Rp 2000
                      double diskon = penjualan['pelanggan_id'] != null
                          ? penjualan['total_harga'] * 0.05
                          : 0; // Diskon hanya untuk member
                      double totalAkhir = penjualan['total_harga'] +
                          pajak +
                          biayaLayanan -
                          diskon;

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tanggal: ${penjualan['tanggal_penjualan']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Pelanggan: $namaPelanggan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Menampilkan Diskon, Pajak, dan Biaya Layanan
                              Divider(color: Colors.grey[400]),
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
                                              fontSize: 15,
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
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Subtotal: Rp ${penjualan['total_harga']}',
                                      style: GoogleFonts.poppins()),
                                  Text(
                                      'Diskon: Rp -${diskon.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins()),
                                  Text(
                                      'Pajak (10%): Rp ${pajak.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins()),
                                  Text(
                                      'Biaya Layanan: Rp ${biayaLayanan.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins()),
                                ],
                              ),

                              const SizedBox(height: 8),
                              Divider(color: Colors.black),
                              const SizedBox(height: 8),

                              // Total Akhir
                              Text(
                                'Total: Rp ${totalAkhir.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),

                              const SizedBox(height: 12),

                              const SizedBox(height: 16),

                              // Tombol Hapus Riwayat
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Konfirmasi sebelum menghapus
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text(
                                            'Hapus Riwayat Pembelian'),
                                        content: const Text(
                                            'Apakah Anda yakin ingin menghapus riwayat pembelian ini?'),
                                        actions: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red),
                                                child: const Text(
                                                  'Batal',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  deleteRiwayat(penjualan[
                                                      'penjualan_id']);
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green),
                                                child: const Text(
                                                  'Hapus',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
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
        )
      ]),
    );
  }
}
