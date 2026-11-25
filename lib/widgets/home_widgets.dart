import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Warna teks sekunder dari desain.
const Color kSubtle = Color(0xFF7F7F7F);

/// Dekorasi kartu putih berbayangan.
BoxDecoration whiteCard({double radius = 12}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: kFieldShadow,
    );

/// Pill putih kecil berisi nilai, mis. "2 pcs" / "0.1 kg".
class ValuePill extends StatelessWidget {
  const ValuePill({super.key, required this.text, this.width = 78});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 27,
      alignment: Alignment.center,
      decoration: whiteCard(radius: 14),
      child: Text(text, style: inter(size: 14, weight: FontWeight.w600)),
    );
  }
}

/// Judul bagian (mis. "Dampak Bulan Ini").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.size = 18});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: inter(size: size, weight: FontWeight.w600));
}

/// Header Beranda: sapaan, lonceng, kartu poin, dan karakter.
/// Koordinat mengikuti desain 412 x 917.
List<Widget> buildHomeHeader({
  required String firstName,
  required int points,
  VoidCallback? onBell,
}) {
  return [
    Positioned(
      left: 24,
      top: 60,
      child: Text(
        'Halo, $firstName!',
        style: inter(size: 24, weight: FontWeight.w600),
      ),
    ),
    Positioned(
      left: 24,
      top: 93,
      child: Text('Selamat datang', style: inter(size: 14, color: kSubtle)),
    ),
    Positioned(
      left: 358,
      top: 55,
      width: 36,
      height: 36,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onBell,
        child: Center(
          child: Image.asset('assets/images/ic_bell.png',
              width: 19, color: AppColors.dark),
        ),
      ),
    ),
    // Kartu poin
    Positioned(
      left: 24,
      top: 128,
      width: 290,
      height: 98,
      child: Container(
        decoration: whiteCard(),
        child: Stack(
          children: [
            Positioned(
              left: 14,
              top: 17,
              child: Text('Points kamu', style: inter(size: 14, color: const Color(0xFF555553))),
            ),
            Positioned(
              left: 14,
              top: 34,
              child: Text('$points', style: inter(size: 40, weight: FontWeight.w500, height: 1.2)),
            ),
          ],
        ),
      ),
    ),
    // Karakter (di atas kartu)
    Positioned(
      left: 248,
      top: 84,
      width: 148,
      height: 166,
      child: Image.asset('assets/images/avatar.png', fit: BoxFit.fill),
    ),
  ];
}
