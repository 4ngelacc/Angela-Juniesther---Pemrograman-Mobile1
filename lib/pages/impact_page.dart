import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/claim_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/home_widgets.dart';

/// Warna diagram lingkaran: hijau, kuning, abu muda ("Lainnya").
const List<Color> kOutletColors = [
  AppColors.brandGreen, // outlet 1
  AppColors.yellow, // outlet 2
  Color(0xFFD9D9D9), // Lainnya (abu muda)
];

/// 3. Dampak Lingkungan (Dampak bulan ini).
/// Panah di samping bulan untuk pindah ke bulan sebelum / sesudahnya.
class ImpactPage extends StatefulWidget {
  const ImpactPage({super.key, required this.user});

  final AppUser user;

  @override
  State<ImpactPage> createState() => _ImpactPageState();
}

class _ImpactPageState extends State<ImpactPage> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _shiftMonth(int delta) {
    setState(() {
      final d = DateTime(_year, _month + delta);
      _year = d.year;
      _month = d.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ClaimService.instance,
      builder: (context, _) {
        final impact =
            ClaimService.instance.impactOf(widget.user, _year, _month);
        final now = DateTime.now();
        final isCurrentMonth = _year == now.year && _month == now.month;
        // Minggu ke-berapa hari ini (untuk highlight batang bulan berjalan).
        final currentWeek =
            isCurrentMonth ? ((now.day - 1) ~/ 7) : -1;

        return TuurnScaffold(
          user: widget.user,
          current: NavTab.home,
          children: [
            // Header
            Positioned(
              left: 24,
              top: 50,
              width: 44,
              height: 44,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: const Center(
                  child: Icon(Icons.arrow_back, size: 26, color: AppColors.dark),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 0,
              top: 59,
              child: Center(
                child: Text('Dampak Lingkungan',
                    style: inter(size: 18, weight: FontWeight.w500)),
              ),
            ),

            // Pemilih bulan
            Positioned(
              left: 15,
              top: 124,
              width: 380,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.yellow, width: 1.5),
                  boxShadow: kFieldShadow,
                ),
                child: Row(
                  children: [
                    _MonthArrow(
                      icon: Icons.chevron_left,
                      onTap: () => _shiftMonth(-1),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          formatMonthYear(_year, _month),
                          style: inter(size: 18, weight: FontWeight.w500),
                        ),
                      ),
                    ),
                    _MonthArrow(
                      icon: Icons.chevron_right,
                      onTap: () => _shiftMonth(1),
                    ),
                  ],
                ),
              ),
            ),

            // Kartu plastik dicegah
            Positioned(
              left: 15,
              top: 185,
              width: 185,
              height: 91,
              child: Container(
                decoration: whiteCard(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 9,
                      top: 10,
                      height: 70,
                      child: Image.asset('assets/images/cup.png'),
                    ),
                    Positioned(
                      left: 67,
                      top: 20,
                      child: Text('Plastik dicegah', style: inter(size: 14)),
                    ),
                    Positioned(
                      left: 67,
                      top: 44,
                      child: ValuePill(text: '${impact.plastic} pcs', width: 78),
                    ),
                  ],
                ),
              ),
            ),
            // Kartu CO2 berkurang
            Positioned(
              left: 210,
              top: 185,
              width: 186,
              height: 91,
              child: Container(
                decoration: whiteCard(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 8,
                      top: 10,
                      height: 70,
                      child: Image.asset('assets/images/plant.png'),
                    ),
                    Positioned(
                      left: 81,
                      top: 20,
                      child: Text('CO₂ Berkurang', style: inter(size: 14)),
                    ),
                    Positioned(
                      left: 83,
                      top: 44,
                      child: ValuePill(
                          text: '${formatKg(impact.co2Kg)} kg', width: 78),
                    ),
                  ],
                ),
              ),
            ),

            // Grafik batang per minggu
            const Positioned(
              left: 15,
              top: 332,
              child: SectionTitle('Kemasan dicegah per minggu'),
            ),
            Positioned(
              left: 15,
              top: 362,
              width: 380,
              height: 150,
              child: Container(
                decoration: whiteCard(),
                child: CustomPaint(
                  painter: _WeeklyBarPainter(
                    values: impact.weekly,
                    currentWeek: currentWeek,
                  ),
                ),
              ),
            ),

            // Kontribusi per outlet
            const Positioned(
              left: 16,
              top: 562,
              child: SectionTitle('Kontribusi per outlet'),
            ),
            Positioned(
              left: 15,
              top: 592,
              width: 380,
              height: 98,
              child: Container(
                decoration: whiteCard(),
                child: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 9,
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: _DonutPainter(impact.outlets),
                      ),
                    ),
                    Positioned(
                      left: 118,
                      top: 0,
                      right: 8,
                      bottom: 0,
                      child: Center(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: impact.outlets.isEmpty
                              ? Text('Belum ada data',
                                  style: inter(size: 14, color: kSubtle))
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0;
                                        i < impact.outlets.length;
                                        i++)
                                      _LegendRow(
                                        // "Lainnya" selalu abu muda
                                        color: impact.outlets[i].name ==
                                                'Lainnya'
                                            ? kOutletColors[2]
                                            : kOutletColors[i],
                                        text:
                                            '${impact.outlets[i].name} ${impact.outlets[i].percent}%',
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 38,
        child: Icon(icon, size: 26, color: AppColors.dark),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 19,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(text, style: inter(size: 14)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Grafik batang
// ---------------------------------------------------------------------
class _WeeklyBarPainter extends CustomPainter {
  _WeeklyBarPainter({required this.values, required this.currentWeek});

  final List<int> values;
  final int currentWeek;

  void _text(Canvas canvas, String s, Offset center, double size, Color color,
      {FontWeight weight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: inter(size: size, color: color, weight: weight, height: 1.1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 18.0;
    const top = 26.0;
    const bottomLabel = 28.0;
    final baseY = size.height - bottomLabel;
    final plotH = baseY - top;

    final maxVal = values.isEmpty ? 0 : values.reduce(math.max);
    final yMax = maxVal <= 4 ? 4 : ((maxVal + 1) ~/ 2) * 2;

    // Garis bantu
    final grid = Paint()
      ..color = const Color(0xFFEDEDED)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = baseY - plotH * i / 2;
      canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), grid);
    }

    final n = values.length;
    if (n == 0) return;
    final slot = (size.width - padX * 2) / n;
    final barW = math.min(34.0, slot * 0.5);

    for (var i = 0; i < n; i++) {
      final cx = padX + slot * i + slot / 2;
      final v = values[i];
      final h = v == 0 ? 3.0 : plotH * v / yMax;
      final color = v == 0
          ? const Color(0xFFE3E3E3)
          : (i == currentWeek ? AppColors.yellow : AppColors.brandGreen);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, baseY - h, barW, h),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = color);

      if (v > 0) {
        _text(canvas, '$v', Offset(cx, baseY - h - 9), 12, AppColors.dark,
            weight: FontWeight.w600);
      }
      _text(canvas, 'Minggu ${i + 1}', Offset(cx, baseY + 15), 11,
          const Color(0xFF7F7F7F));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter old) =>
      old.currentWeek != currentWeek || !_same(old.values, values);

  bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------
// Diagram lingkaran
// ---------------------------------------------------------------------
class _DonutPainter extends CustomPainter {
  _DonutPainter(this.shares);

  final List<OutletShare> shares;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 15.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    if (shares.isEmpty) {
      canvas.drawArc(rect, 0, math.pi * 2, false,
          base..color = const Color(0xFFEDEDED));
      return;
    }

    var start = -math.pi / 2; // mulai dari atas, searah jarum jam
    for (var i = 0; i < shares.length; i++) {
      final sweep = math.pi * 2 * shares[i].percent / 100;
      final color =
          shares[i].name == 'Lainnya' ? kOutletColors[2] : kOutletColors[i];
      canvas.drawArc(rect, start, sweep, false, base..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.shares != shares;
}
