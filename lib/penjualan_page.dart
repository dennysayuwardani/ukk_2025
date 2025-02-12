import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html;

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
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _fetchPelanggan();
    //      _resetPenjualan();
    //   });
  }

  void _resetPenjualan() {
    setState(() {
      selectedPelangganId = null;
      produkTerpilih.clear();
      totalHarga = 0;
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
    showCheckoutDialog(
      context,
      pelangganId: selectedPelangganId,
      produkTerpilih: produkTerpilih,
      totalHarga: totalHarga,
      onTransactionComplete: () {
        _resetPenjualan();
        // Pindahkan logika penyimpanan ke sini
        _saveTransaction(selectedPelangganId, produkTerpilih, totalHarga);
      },
    );
  }

  Future<void> _saveTransaction(int? pelangganId,
      List<Map<String, dynamic>> produkTerpilih, double totalHarga) async {
    final supabase = Supabase.instance.client;
    Map<String, dynamic>? pelangganData;

    try {
      // Ambil data pelanggan jika ada
      if (pelangganId != null) {
        final response = await supabase
            .from('pelanggan')
            .select()
            .eq('pelanggan_id', pelangganId)
            .single();
        pelangganData = response;
      }

      // Simpan transaksi penjualan
      final penjualanResponse = await supabase
          .from('penjualan')
          .insert({
            'tanggal_penjualan': DateTime.now().toIso8601String(),
            'total_harga': totalHarga,
            'pelanggan_id': pelangganId,
          })
          .select()
          .single();

      final penjualanId = penjualanResponse['penjualan_id'];

      // Simpan detail penjualan
      for (var produk in produkTerpilih) {
        await supabase.from('detail_penjualan').insert({
          'penjualan_id': penjualanId,
          'produk_id': produk['produk_id'],
          'jumlah_produk': produk['jumlah_produk'],
          'subtotal': produk['subtotal'],
        });

        final int newStok = produk['stok'] - produk['jumlah_produk'];
        await supabase
            .from('produk')
            .update({'stok': newStok}).eq('produk_id', produk['produk_id']);
      }

      // Tampilkan snackbar sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembelian berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );

      // Tampilkan dialog checkout setelah transaksi berhasil
      showCheckoutDialog(
        context,
        pelangganId: pelangganId,
        produkTerpilih: produkTerpilih,
        totalHarga: totalHarga,
        onTransactionComplete: () {
          // Reset penjualan atau lakukan tindakan lain jika diperlukan
          _resetPenjualan();
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pembelian: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePDF(
      int? pelangganId, Map<String, dynamic>? pelangganData) async {
    final pdf = pw.Document();

    // Hitung subtotal dari produk yang dibeli
    double subtotal =
        produkTerpilih.fold(0, (sum, item) => sum + item['subtotal']);

    // Diskon 5% untuk pelanggan member
    double diskon = pelangganId != null ? subtotal * 0.05 : 0;

    // Subtotal setelah diskon
    double subtotalSetelahDiskon = subtotal - diskon;

    // Pajak 10% setelah diskon
    double pajak = totalHarga * 0.10;

    // Biaya layanan tetap Rp 2.000
    double biayaLayanan = 2000;

    // Total akhir setelah diskon, pajak, dan biaya layanan
    double totalAkhir = subtotalSetelahDiskon + pajak + biayaLayanan;

// Ambil tanggal dan waktu transaksi
  DateTime now = DateTime.now();
  String tanggalTransaksi = "${now.toLocal().toString().split(' ')[0]} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";


    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Struk Pembelian',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              pw.Text('Tanggal: $tanggalTransaksi',
                  style: pw.TextStyle(fontSize: 16)),
              pw.Text(pelangganId != null
                  ? 'Pelanggan: ${pelangganData?['nama_pelanggan'] ?? "-"}'
                  : 'Pelanggan: Non-member'),
              if (pelangganId != null) ...[
                pw.Text('Alamat: ${pelangganData?['alamat'] ?? "-"}'),
                pw.Text('No. Telp: ${pelangganData?['nomor_telepon'] ?? "-"}'),
              ],
              pw.SizedBox(height: 10),
              pw.Text('Produk yang dibeli:', style: pw.TextStyle(fontSize: 18)),
              pw.Divider(),
              ...produkTerpilih.map((produk) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          '${produk['nama_produk']} x${produk['jumlah_produk']}'),
                      pw.Text('Rp ${produk['subtotal']}'),
                    ],
                  )),
              pw.Divider(),
              pw.Text('Subtotal: Rp ${subtotal.toStringAsFixed(0)}'),
              pw.Text('Diskon: Rp -${diskon.toStringAsFixed(0)}'),
              pw.Text('Pajak (10%): Rp ${pajak.toStringAsFixed(0)}'),
              pw.Text('Biaya Layanan: Rp ${biayaLayanan.toStringAsFixed(0)}'),
              pw.Divider(),
              pw.Text('Total Harga: Rp ${totalAkhir.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final namaFile = pelangganId != null
        ? 'Struk_${pelangganData?['nama_pelanggan'] ?? 'Pelanggan'}.pdf'
        : 'Struk_Non_Member.pdf';

    if (kIsWeb) {
      // Jika berjalan di web, simpan PDF dengan savePdfWeb
      savePdfWeb(pdfBytes, namaFile);
    } else {
      try {
        // Simpan PDF ke perangkat
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$namaFile';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Struk Pembelian');
      } catch (e) {
        print('Error saat menyimpan atau berbagi PDF: $e');
      }
    }
  }

  void savePdfWeb(Uint8List pdfBytes, String fileName) {
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
    ));
  }

  void showCheckoutDialog(
    BuildContext context, {
    required int? pelangganId,
    required List<Map<String, dynamic>> produkTerpilih,
    required double totalHarga,
    required VoidCallback onTransactionComplete,
  }) async {
    final supabase = Supabase.instance.client;
    Map<String, dynamic>? pelangganData;
    bool isLoading = true;

    if (pelangganId != null) {
      try {
        final response = await supabase
            .from('pelanggan')
            .select()
            .eq('pelanggan_id', pelangganId)
            .single();
        pelangganData = response;
      } catch (e) {
        print("Error mengambil data pelanggan: $e");
      }
    }

    isLoading = false;

    // Pajak 10% setelah diskon
    double pajak = totalHarga * 0.10;
    // Biaya layanan Rp 2.000
    double biayaLayanan = 2000;
    // Diskon untuk pelanggan member (contoh: 5%)
    double diskon = pelangganId != null ? totalHarga * 0.05 : 0;
    // Total akhir
    double totalAkhir = totalHarga + pajak + biayaLayanan - diskon;

    showDialog(
      context: context,
      builder: (context) {
        DateTime now = DateTime.now();
    String tanggalTransaksi = "${now.toLocal().toString().split(' ')[0]} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Struk Pembelian',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                            
                      Text(
                        'Tanggal: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      Text(
                        pelangganId != null
                            ? 'Pelanggan: ${pelangganData?['nama_pelanggan'] ?? "-"}'
                            : 'Pelanggan: Non-member',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      if (pelangganId != null) ...[
                        Text('Alamat: ${pelangganData?['alamat'] ?? "-"}',
                            style: GoogleFonts.poppins(fontSize: 14)),
                        Text(
                            'No. Telp: ${pelangganData?['nomor_telepon'] ?? "-"}',
                            style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Produk yang dibeli:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        children: produkTerpilih.map((produk) {
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
                        }).toList(),
                      ),
                      const Divider(),
                      Text('Subtotal: Rp $totalHarga',
                          style: GoogleFonts.poppins()),
                      Text('Diskon: Rp -$diskon', style: GoogleFonts.poppins()),
                      Text('Pajak (10%): Rp $pajak',
                          style: GoogleFonts.poppins()),
                      Text('Biaya Layanan: Rp $biayaLayanan',
                          style: GoogleFonts.poppins()),
                      const SizedBox(height: 10),
                      Text(
                        'Total Harga: Rp $totalAkhir',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Tutup', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () async {
                await _generatePDF(pelangganId, pelangganData);
              },
              child: Text("Ekspor PDF"),
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
              onPressed: produkTerpilih.isEmpty
                  ? null
                  : () {
                      _saveTransaction(
                          selectedPelangganId, produkTerpilih, totalHarga);
                    },
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
