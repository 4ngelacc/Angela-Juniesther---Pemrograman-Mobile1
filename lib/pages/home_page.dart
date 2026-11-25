import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/claim_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/home_widgets.dart';
import 'impact_page.dart';

/// Beranda.
///  - Belum ada klaim (belum pernah scan QR berhasil) -> tampilan pengguna baru.
///  - Sudah ada klaim -> Dampak Bulan Ini, banner, Aktivitas Terakhir.
/// Nama pada "Halo, ..." diambil dari nama saat register.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});

  final AppUser user;

  void _openImpact(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ImpactPage(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ClaimService.instance,
      builder: (context, _) {
        final service = ClaimService.instance;
        final hasData = service.hasClaims(user);

        return TuurnScaffold(
          user: user,
          current: NavTab.home,
          children: [
            ...buildHomeHeader(
              firstName: user.firstName,
              points: service.pointsOf(user),
            ),
            if (hasData)
              ..._dataContent(context, service)
            else
              ..._newUserContent(),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // 1. Beranda (pengguna baru)
  // -------------------------------------------------------------------
  List<Widget> _newUserContent() {
    const steps = [
      'Cari Merchant Partner',
      'Membawa tumblr/wadah sendiri',
      'Scan QR di kasir',
    ];
    return [
      Positioned(
        left: 33,
        top: 302,
        child: Text('Mulai klaim pertamamu',
            style: inter(size: 16, weight: FontWeight.w600)),
      ),
      for (var i = 0; i < steps.length; i++)
        Positioned(
          left: 33,
          top: 346 + i * 85.0,
          width: 336,
          height: 52,
          child: _StepPill(number: i + 1, label: steps[i]),
        ),
    ];
  }

  // -------------------------------------------------------------------
  // 2. Beranda (sudah ada data)
  // -------------------------------------------------------------------
  List<Widget> _dataContent(BuildContext context, ClaimService service) {
    final now = DateTime.now();
    final impact = service.impactOf(user, now.year, now.month);
    final activities = service.activitiesOf(user).take(3).toList();

    return [
      const Positioned(
        left: 24,
        top: 287,
        child: SectionTitle('Dampak Bulan Ini'),
      ),
      Positioned(
        left: 300,
        top: 288,
        width: 92,
        height: 22,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openImpact(context),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('lihat detail >',
                style: inter(size: 12, color: const Color(0xFF858481))),
          ),
        ),
      ),
      // Area plastik dicegah + CO2 berkurang (bisa diklik -> halaman dampak)
      Positioned(
        left: 0,
        top: 312,
        width: 412,
        height: 92,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openImpact(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 25,
                top: 10,
                height: 70,
                child: Image.asset('assets/images/cup.png'),
              ),
              Positioned(
                left: 79,
                top: 24,
                child: Text('Plastik dicegah', style: inter(size: 14)),
              ),
              Positioned(
                left: 79,
                top: 46,
                child: ValuePill(text: '${impact.plastic} pcs', width: 77),
              ),
              Positioned(
                left: 208,
                top: 13,
                height: 70,
                child: Image.asset('assets/images/plant.png'),
              ),
              Positioned(
                left: 288,
                top: 24,
                child: Text('CO₂ Berkurang', style: inter(size: 14)),
              ),
              Positioned(
                left: 292,
                top: 46,
                child: ValuePill(text: '${formatKg(impact.co2Kg)} kg', width: 77),
              ),
            ],
          ),
        ),
      ),
      // Banner
      const Positioned(
        left: 24,
        top: 438,
        width: 364,
        height: 120,
        child: _BannerCarousel(),
      ),
      // Aktivitas terakhir
      const Positioned(
        left: 24,
        top: 592,
        child: SectionTitle('Aktivitas Terakhir'),
      ),
      for (var i = 0; i < activities.length; i++) ...[
        Positioned(
          left: 38,
          top: 630 + i * 61.0,
          width: 34,
          child: Image.asset(
            activities[i].type == ActivityType.claim
                ? 'assets/images/ic_store.png'
                : 'assets/images/ic_voucher.png',
            color: AppColors.brandGreen,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: 87,
          top: 629 + i * 61.0,
          right: 24,
          child: Text(activities[i].title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: inter(size: 14, weight: FontWeight.w600)),
        ),
        Positioned(
          left: 87,
          top: 650 + i * 61.0,
          child: Text(formatActivityTime(activities[i].time),
              style: inter(size: 12, color: const Color(0xFF6C706B))),
        ),
        if (i < activities.length - 1)
          Positioned(
            left: 24,
            top: 677 + i * 61.0,
            width: 364,
            height: 1,
            child: const ColoredBox(color: Color(0xFFD9D9D9)),
          ),
      ],
    ];
  }
}

/// Satu langkah "Mulai klaim pertamamu": lingkaran hijau bernomor + pill putih.
class _StepPill extends StatelessWidget {
  const _StepPill({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: whiteCard(radius: 26),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: Text('$number', style: inter(size: 28, weight: FontWeight.w500)),
          ),
          const SizedBox(width: 24),
          Expanded(child: Text(label, style: inter(size: 14))),
        ],
      ),
    );
  }
}

/// Banner geser dengan titik indikator.
/// Ganti isi [_banners] dengan gambar banner lain bila perlu.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  static const _banners = [
    'assets/images/banner.png',
    'assets/images/banner.png',
    'assets/images/banner.png',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 98,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: PageView.builder(
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: kFieldShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(_banners[i], fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? AppColors.brandGreen
                      : const Color(0xFFD9D9D9),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
