import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'design_frame.dart';
import 'glow_background.dart';

const Color _yellowGlow = Color(0xFFFDEEAE);
const Color _greenGlow = Color(0xFFE0FDE2);

/// Background untuk halaman scan / klaim (sesuai desain).
class ScanGlows {
  ScanGlows._();

  /// Scan QR #1: putih polos.
  static final List<GlowSpec> none = [];

  /// Scan QR #2 (izin kamera): glow kuning di tengah.
  static final List<GlowSpec> permission = [
    GlowSpec(
      center: (s) => Offset(s.width / 2, 330),
      rx: 260,
      ry: 270,
      color: _yellowGlow,
      profile: const [
        [0, 1], [.1, .92], [.25, .7], [.45, .4], [.65, .17], [.85, .05], [1, 0],
      ],
    ),
  ];

  /// Kode manual: hijau kiri-atas, kuning kanan-bawah.
  static final List<GlowSpec> manual = [
    GlowSpec(
      center: (s) => const Offset(50, 110),
      rx: 300,
      ry: 330,
      color: _greenGlow,
      profile: const [
        [0, 1], [.1, .97], [.25, .88], [.4, .68], [.55, .45], [.7, .27], [.85, .1], [1, 0],
      ],
    ),
    GlowSpec(
      center: (s) => Offset(s.width - 50, s.height - 20),
      rx: 300,
      ry: 300,
      color: _yellowGlow,
      profile: const [
        [0, 1], [.09, .97], [.27, .76], [.45, .43], [.64, .19], [.82, .05], [1, 0],
      ],
    ),
  ];
}

/// Kerangka halaman tanpa navigasi bawah (Scan, Kode Manual, Hasil Klaim).
/// [children] memakai koordinat desain 412 x 917 (Positioned).
class PlainScaffold extends StatelessWidget {
  const PlainScaffold({
    super.key,
    required this.glows,
    required this.children,
    this.designHeight = 917,
  });

  final List<GlowSpec> glows;
  final List<Widget> children;
  final double designHeight;

  @override
  Widget build(BuildContext context) {
    final extraTop = math.max(MediaQuery.paddingOf(context).top - 24, 0.0);
    return Scaffold(
      backgroundColor: Colors.white,
      body: GlowBackground(
        glows: glows,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: extraTop),
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: kDesignWidth,
              height: designHeight,
              child: Stack(clipBehavior: Clip.none, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol persegi membulat (kuning / putih) seperti di desain scan & klaim.
class RectButton extends StatelessWidget {
  const RectButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.yellow = true,
    this.fontSize = 17,
    this.weight = FontWeight.w700,
  });

  final String label;
  final VoidCallback onPressed;
  final bool yellow;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(12));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: yellow
            ? kButtonShadow
            : const [
                BoxShadow(
                    color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2)),
              ],
      ),
      child: Material(
        color: yellow ? AppColors.yellow : const Color(0xE6FFFFFF),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Center(
            child: Text(label, style: inter(size: fontSize, weight: weight)),
          ),
        ),
      ),
    );
  }
}

/// Header sederhana: ikon di kiri (panah / silang) + judul di tengah.
List<Widget> buildSimpleHeader({
  required BuildContext context,
  required String title,
  IconData icon = Icons.arrow_back,
  Color? color,
}) {
  return [
    Positioned(
      left: 20,
      top: 53,
      width: 44,
      height: 36,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Center(child: Icon(icon, size: 26, color: AppColors.dark)),
      ),
    ),
    Positioned(
      left: 0,
      right: 0,
      top: 59,
      child: Center(
        child: Text(title, style: inter(size: 18, color: color ?? AppColors.dark)),
      ),
    ),
  ];
}
