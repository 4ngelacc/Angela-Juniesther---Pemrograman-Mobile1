import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/claim_service.dart';
import '../widgets/glow_background.dart';
import '../widgets/plain_scaffold.dart';
import 'impact_page.dart';

/// Hasil Klaim: muncul setelah scan QR / kode manual berhasil.
class ClaimResultPage extends StatelessWidget {
  const ClaimResultPage({super.key, required this.user, required this.item});

  final AppUser user;
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final total = ClaimService.instance.pointsOf(user);

    return PlainScaffold(
      glows: GlowPresets.success,
      children: [
        // Medali
        Positioned(
          left: 150,
          top: 123,
          width: 107,
          child: Image.asset('assets/images/medal.png'),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 291,
          child: Center(
            child: Text('Klaim Berhasil!',
                style: inter(size: 28, weight: FontWeight.w500)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 330,
          child: Center(
            child: Text(
              '${item.outlet} ${formatFullDateTime(item.time)}',
              style: inter(size: 14, color: const Color(0xFF99968B)),
            ),
          ),
        ),
        // + 25 Poin
        Positioned(
          left: 141,
          top: 381,
          width: 33,
          child: Image.asset('assets/images/coin.png'),
        ),
        Positioned(
          left: 181,
          top: 385,
          child: Text('+ ${item.points} Poin', style: inter(size: 20)),
        ),
        // Kartu ringkasan
        Positioned(
          left: 34,
          top: 447,
          width: 352,
          height: 128,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x99FFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC4C4C4), width: 1),
            ),
            child: Stack(
              children: [
                _row(29, 'Plastik dicegah', '+${item.plastic} Kemasan'),
                _row(64, 'CO₂ dikurangi', '+${formatKg(item.co2Kg)} kg'),
                _row(100, 'Total poin kamu', '$total'),
                for (final y in const [46.0, 81.0])
                  Positioned(
                    left: 22,
                    right: 28,
                    top: y,
                    height: 1,
                    child: const ColoredBox(color: Color(0xFFDDE4DD)),
                  ),
              ],
            ),
          ),
        ),
        // Tombol
        Positioned(
          left: 54,
          top: 701,
          width: 304,
          height: 49,
          child: RectButton(
            label: 'Lihat Dashboard Dampak',
            fontSize: 16,
            onPressed: () {
              final nav = Navigator.of(context);
              nav.popUntil((r) => r.isFirst);
              nav.push(MaterialPageRoute(builder: (_) => ImpactPage(user: user)));
            },
          ),
        ),
        Positioned(
          left: 54,
          top: 777,
          width: 304,
          height: 48,
          child: RectButton(
            label: 'Selesai',
            yellow: false,
            fontSize: 16,
            weight: FontWeight.w600,
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ),
      ],
    );
  }

  Widget _row(double top, String label, String value) {
    return Positioned(
      left: 22,
      right: 28,
      top: top - 8.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: inter(size: 14, color: const Color(0xFF333331))),
          Text(value, style: inter(size: 14, color: const Color(0xFF333331))),
        ],
      ),
    );
  }
}
