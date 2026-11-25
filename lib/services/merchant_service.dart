/// "Database barcode" merchant (sementara di kode).
/// Hanya QR / kode yang terdaftar di sini yang bisa diklaim.
/// Nanti ganti dengan data dari API / database.
class Merchant {
  const Merchant(this.code, this.name);

  /// Isi QR Code kasir (juga kode yang tertera di bawah QR).
  final String code;
  final String name;
}

class MerchantService {
  MerchantService._();

  /// TAMBAH barcode baru di sini.
  /// Isi QR Code harus SAMA PERSIS dengan kode di bawah.
  static const List<Merchant> merchants = [
    Merchant('KS-2047-AB', 'Kopi Kenangan'),
    Merchant('FR-1031-CD', 'Fore'),
    Merchant('JJ-5520-EF', 'Janji Jiwa'),
  ];

  /// Cari merchant dari isi QR / kode manual.
  /// Tidak peka huruf besar-kecil, tapi isinya harus sama persis.
  /// Mengembalikan null bila barcode tidak terdaftar.
  static Merchant? lookup(String raw) {
    final text = raw.trim().toUpperCase();
    if (text.isEmpty) return null;
    for (final m in merchants) {
      if (text == m.code.toUpperCase()) return m;
    }
    return null;
  }
}
