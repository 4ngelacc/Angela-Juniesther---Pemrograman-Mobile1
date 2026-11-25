import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/claim_service.dart';
import 'design_frame.dart';
import 'glow_background.dart';
import '../pages/scan_page.dart';

enum NavTab { home, merchant, scan, reward, profile }

/// Tinggi area navigasi bawah pada desain (termasuk lingkaran Scan yang menonjol).
const double _kNavHeight = 109;

/// Kerangka halaman utama (Beranda, Dampak, dst):
/// background glow + konten berukuran desain 412px yang diskalakan mengikuti
/// lebar layar + navigasi bawah.
///
/// [children] memakai koordinat desain (Positioned dengan left/top dari
/// screenshot 412 x 917).
class TuurnScaffold extends StatelessWidget {
  const TuurnScaffold({
    super.key,
    required this.user,
    required this.current,
    required this.children,
    this.designHeight = 917,
  });

  final AppUser user;
  final NavTab current;
  final List<Widget> children;
  final double designHeight;

  void _onTab(BuildContext context, NavTab tab) {
    final messenger = ScaffoldMessenger.of(context);
    switch (tab) {
      case NavTab.home:
        if (current != NavTab.home) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
        break;
      case NavTab.scan:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScanPage(user: user)),
        );
        break;
      default:
        final name = {
          NavTab.merchant: 'Merchant',
          NavTab.reward: 'Reward',
          NavTab.profile: 'Profile',
        }[tab]!;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Halaman $name belum tersedia')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Status bar pada desain tingginya sekitar 24px; kalau perangkat punya
    // status bar lebih tinggi, konten digeser sedikit.
    final extraTop = math.max(MediaQuery.paddingOf(context).top - 24, 0.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GlowBackground(
        glows: GlowPresets.login,
        child: Stack(
          children: [
            Positioned.fill(
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: SizedBox(
                  width: kDesignWidth,
                  height: _kNavHeight,
                  child: _BottomNav(
                    current: current,
                    onTap: (t) => _onTab(context, t),
                    onScanLongPress: () {
                      // SEMENTARA: isi data contoh untuk melihat grafik.
                      ClaimService.instance.loadDemo(user);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            content: Text('Data contoh dimuat')));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.onTap,
    required this.onScanLongPress,
  });

  final NavTab current;
  final ValueChanged<NavTab> onTap;
  final VoidCallback onScanLongPress;

  static const _inactive = Color(0xFFCCCCCC);

  Widget _item(NavTab tab, String label, String asset, double cx, double iconW) {
    final active = tab == current;
    final color = active ? AppColors.brandGreen : _inactive;
    return Positioned(
      left: cx - 40,
      top: 46,
      width: 80,
      height: 63,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(tab),
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 25,
              child: Image.asset(asset,
                  width: iconW, height: 25, color: color, fit: BoxFit.contain),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: inter(size: 12, color: color, height: 14 / 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bar putih
        const Positioned(
          left: 0,
          right: 0,
          top: 40,
          bottom: 0,
          child: ColoredBox(color: Colors.white),
        ),
        // Cincin putih di belakang tombol Scan
        Positioned(
          left: 206 - 37.5,
          top: 0.5,
          child: Container(
            width: 75,
            height: 75,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        _item(NavTab.home, 'Home', 'assets/images/nav_home.png', 46, 25),
        _item(NavTab.merchant, 'Merchant', 'assets/images/nav_merchant.png', 127, 28),
        _item(NavTab.reward, 'Reward', 'assets/images/nav_reward.png', 285, 25),
        _item(NavTab.profile, 'Profile', 'assets/images/nav_profile.png', 356, 25),
        // Tombol Scan
        Positioned(
          left: 176,
          top: 8,
          child: GestureDetector(
            onTap: () => onTap(NavTab.scan),
            onLongPress: onScanLongPress,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFA8DE8A),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Image.asset('assets/images/ic_qr.png',
                  width: 28, height: 28, color: AppColors.dark),
            ),
          ),
        ),
        Positioned(
          left: 206 - 40,
          top: 83,
          width: 80,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(NavTab.scan),
            child: Text('Scan',
                textAlign: TextAlign.center,
                style: inter(size: 12, color: _inactive, height: 14 / 12)),
          ),
        ),
      ],
    );
  }
}
