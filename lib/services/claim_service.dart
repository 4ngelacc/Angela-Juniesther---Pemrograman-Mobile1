import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Poin awal dari pendaftaran akun ("+ 25 Poin" di halaman sukses).
const int kWelcomePoints = 25;

/// Poin yang didapat tiap klaim berhasil (sementara).
const int kPointsPerClaim = 25;

/// Estimasi CO2 yang berkurang per 1 kemasan plastik yang dicegah (kg).
const double kCo2PerPiece = 0.05;

enum ActivityType { claim, voucher }

/// Satu baris aktivitas: klaim di outlet (scan QR berhasil) atau tukar voucher.
class ActivityItem {
  ActivityItem.claim({
    required this.outlet,
    required this.time,
    this.plastic = 1,
    this.points = kPointsPerClaim,
  })  : type = ActivityType.claim,
        title = 'Klaim di $outlet',
        co2Kg = plastic * kCo2PerPiece;

  ActivityItem.voucher({
    required this.title,
    required this.time,
    this.points = 0,
  })  : type = ActivityType.voucher,
        outlet = '',
        plastic = 0,
        co2Kg = 0;

  final ActivityType type;
  final String title;
  final String outlet;
  final DateTime time;
  final int plastic;
  final double co2Kg;

  /// Perubahan poin (klaim = positif, tukar voucher = negatif).
  final int points;
}

/// Bagian satu outlet untuk diagram lingkaran.
class OutletShare {
  const OutletShare(this.name, this.count, this.percent);

  final String name;
  final int count;
  final int percent;
}

/// Ringkasan dampak satu bulan.
class MonthImpact {
  const MonthImpact({
    required this.plastic,
    required this.co2Kg,
    required this.weekly,
    required this.outlets,
  });

  final int plastic;
  final double co2Kg;

  /// Jumlah kemasan dicegah per minggu (4 atau 5 item).
  final List<int> weekly;

  /// Maksimal 3 item: 2 outlet terbanyak + "Lainnya".
  final List<OutletShare> outlets;
}

/// Penyimpanan klaim & aktivitas sementara di memori (per akun).
/// Nanti ganti isi `addClaim` dengan data dari API / database.
class ClaimService extends ChangeNotifier {
  ClaimService._();

  static final ClaimService instance = ClaimService._();

  final Map<String, List<ActivityItem>> _byUser = {};

  List<ActivityItem> _list(AppUser u) =>
      _byUser.putIfAbsent(u.email.toLowerCase(), () => []);

  /// Aktivitas terbaru di paling atas.
  List<ActivityItem> activitiesOf(AppUser u) {
    final items = [..._list(u)]..sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  /// `false` = pengguna baru (belum pernah scan QR berhasil).
  bool hasClaims(AppUser u) =>
      _list(u).any((a) => a.type == ActivityType.claim);

  int pointsOf(AppUser u) =>
      kWelcomePoints + _list(u).fold<int>(0, (sum, a) => sum + a.points);

  /// Panggil ini saat scan QR / kode manual berhasil.
  /// Mengembalikan aktivitas yang baru dibuat (dipakai halaman Hasil Klaim).
  ActivityItem addClaim(
    AppUser u, {
    required String outlet,
    DateTime? time,
    int plastic = 1,
  }) {
    final item = ActivityItem.claim(
      outlet: outlet,
      time: time ?? DateTime.now(),
      plastic: plastic,
    );
    _list(u).add(item);
    notifyListeners();
    return item;
  }

  void addVoucher(AppUser u, {required String title, int cost = 0, DateTime? time}) {
    _list(u).add(ActivityItem.voucher(
      title: title,
      time: time ?? DateTime.now(),
      points: -cost,
    ));
    notifyListeners();
  }

  /// Hitung dampak untuk satu bulan.
  MonthImpact impactOf(AppUser u, int year, int month) {
    final claims = _list(u).where((a) =>
        a.type == ActivityType.claim &&
        a.time.year == year &&
        a.time.month == month);

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final weekCount = daysInMonth > 28 ? 5 : 4;
    final weekly = List<int>.filled(weekCount, 0);
    final perOutlet = <String, int>{};
    var plastic = 0;
    var co2 = 0.0;

    for (final c in claims) {
      plastic += c.plastic;
      co2 += c.co2Kg;
      final w = ((c.time.day - 1) ~/ 7).clamp(0, weekCount - 1);
      weekly[w] += c.plastic;
      perOutlet[c.outlet] = (perOutlet[c.outlet] ?? 0) + c.plastic;
    }

    return MonthImpact(
      plastic: plastic,
      co2Kg: co2,
      weekly: weekly,
      outlets: _shares(perOutlet, plastic),
    );
  }

  List<OutletShare> _shares(Map<String, int> perOutlet, int total) {
    if (total == 0) return const [];
    final sorted = perOutlet.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });

    final top = sorted.take(2).toList();
    final restCount = sorted.skip(2).fold<int>(0, (s, e) => s + e.value);

    final entries = <MapEntry<String, int>>[
      ...top,
      if (restCount > 0) MapEntry('Lainnya', restCount),
    ];

    final result = <OutletShare>[];
    var used = 0;
    for (var i = 0; i < entries.length; i++) {
      final isLast = i == entries.length - 1;
      final pct = isLast ? 100 - used : (entries[i].value * 100 / total).round();
      used += pct;
      result.add(OutletShare(entries[i].key, entries[i].value, pct));
    }
    return result;
  }

  // ---------------------------------------------------------------------
  // SEMENTARA: simulasi sebelum fitur scan QR sungguhan dibuat.
  // ---------------------------------------------------------------------
  static const _demoOutlets = ['Kopi Kenangan', 'Fore', 'Janji Jiwa'];
  int _simCounter = 0;

  /// Dipanggil saat tombol Scan ditekan: anggap saja scan QR berhasil.
  void simulateScan(AppUser u) {
    addClaim(u, outlet: _demoOutlets[_simCounter % _demoOutlets.length]);
    _simCounter++;
  }

  /// Isi data contoh (tekan lama tombol Scan) supaya grafik terlihat.
  void loadDemo(AppUser u) {
    final now = DateTime.now();
    final list = _list(u);
    list.clear();

    const outlets = [
      'Kopi Kenangan', 'Fore', 'Kopi Kenangan', 'Janji Jiwa',
      'Kopi Kenangan', 'Fore', 'Kopi Kenangan', 'Fore', 'Kopi Kenangan',
    ];
    const days = [2, 3, 6, 9, 10, 13, 17, 20, 23];
    var i = 0;
    for (final d in days) {
      final t = DateTime(now.year, now.month, d, 9, 12);
      if (t.isAfter(now)) continue;
      list.add(ActivityItem.claim(outlet: outlets[i % outlets.length], time: t));
      i++;
    }
    list.add(ActivityItem.claim(
      outlet: 'Kopi Kenangan',
      time: DateTime(now.year, now.month, now.day, 9, 12),
    ));
    list.add(ActivityItem.voucher(
      title: 'Tukar voucher Diskon 20%',
      time: now.subtract(const Duration(days: 1)),
    ));
    // Bulan lalu
    final prev = DateTime(now.year, now.month - 1, 8, 10, 0);
    list.add(ActivityItem.claim(outlet: 'Fore', time: prev));
    list.add(ActivityItem.claim(
        outlet: 'Kopi Kenangan', time: prev.add(const Duration(days: 9))));
    notifyListeners();
  }
}

// ---------------------------------------------------------------------
// Format teks
// ---------------------------------------------------------------------

const List<String> kMonthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const List<String> _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatMonthYear(int year, int month) => '${kMonthNames[month - 1]} $year';

/// "Hari ini, 09:12" atau "7 Nov".
String formatActivityTime(DateTime t) {
  final now = DateTime.now();
  if (t.year == now.year && t.month == now.month && t.day == now.day) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return 'Hari ini, $hh:$mm';
  }
  return '${t.day} ${_monthShort[t.month - 1]}';
}

/// "9 Nov 2026, 9:12" (dipakai di halaman Hasil Klaim).
String formatFullDateTime(DateTime t) {
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${_monthShort[t.month - 1]} ${t.year}, ${t.hour}:$mm';
}

/// 0.1 -> "0.1", 0.15 -> "0.15", 0 -> "0".
String formatKg(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}
