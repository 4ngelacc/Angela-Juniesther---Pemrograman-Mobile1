import 'dart:async';
import 'dart:math' as math; // [BARU]

import 'package:flutter/foundation.dart' show kDebugMode; // [BARU]
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/claim_service.dart';
import '../services/merchant_service.dart';
import '../widgets/home_widgets.dart';
import '../widgets/plain_scaffold.dart';
import 'claim_result_page.dart';
import 'manual_code_page.dart';

/// Scan QR (halaman #1 dan #2).
///  - Pertama kali dipakai: tampil halaman izin kamera (Scan QR #2).
///  - Setelah diizinkan: kamera full screen (Scan QR #1).
///  - QR terdeteksi -> tekan tombol kuning -> Hasil Klaim
///    (hanya bila QR terdaftar di MerchantService).
///  - "Masukkan kode manual" -> halaman Kode Manual.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.user});

  final AppUser user;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

enum _Stage { permission, camera }

class _ScanPageState extends State<ScanPage> {
  /// Sudah pernah menampilkan izin kamera di sesi ini.
  /// (Ganti dengan shared_preferences bila ingin diingat setelah app ditutup.)
  static bool _permissionAsked = false;

  late _Stage _stage;
  MobileScannerController? _controller;
  bool _processing = false;

  /// Isi QR yang sedang tertampil di kamera (null = belum ada).
  String? _detectedRaw;
  Timer? _clearTimer;

  // [BARU] Pesan error singkat di panel bawah (menggantikan snackbar).
  String? _notice;
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    _stage = _permissionAsked ? _Stage.camera : _Stage.permission;
    if (_stage == _Stage.camera) _createController();
  }

  void _createController() {
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _noticeTimer?.cancel(); // [BARU]
    _controller?.dispose();
    super.dispose();
  }

  void _allowCamera() {
    _permissionAsked = true;
    _controller?.dispose();
    setState(() {
      _createController();
      _stage = _Stage.camera;
    });
  }

  Future<void> _openSettings() async {
    var opened = false;
    try {
      opened = await openAppSettings();
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Buka pengaturan perangkat / browser untuk mengizinkan kamera',
            ),
          ),
        );
    }
  }

  /// Dipanggil bila kamera menolak izin -> kembali ke halaman izin.
  void _backToPermission() {
    if (_stage == _Stage.permission) return;
    _controller?.dispose();
    _controller = null;
    setState(() => _stage = _Stage.permission);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Izin kamera ditolak. Tekan "Buka Pengaturan" untuk mengizinkan.',
          ),
        ),
      );
  }

  // [BARU] Tampilkan pesan error singkat selama 2,5 detik.
  void _showNotice(String message) {
    _noticeTimer?.cancel();
    setState(() => _notice = message);
    _noticeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  /// Hanya mencatat QR yang terlihat, TIDAK langsung klaim.
  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .firstOrNull;
    if (raw == null) return;

    // Kalau 0,9 detik tidak terbaca lagi -> anggap QR sudah keluar dari kamera.
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_processing) setState(() => _detectedRaw = null);
    });

    if (_detectedRaw != raw) setState(() => _detectedRaw = raw);
  }

  /// Dipanggil saat tombol kuning ditekan.
  void _onCapture() {
    if (_processing) return;

    final raw = _detectedRaw;
    if (raw == null) {
      _showNotice('Belum ada QR Code terdeteksi');
      return;
    }

    final merchant = MerchantService.lookup(raw);
    if (merchant == null) {
      // Mode debug: tampilkan isi QR supaya mudah didaftarkan.
      final shown = raw.length > 40 ? '${raw.substring(0, 40)}...' : raw;
      _showNotice(
        kDebugMode
            ? 'QR Code tidak terdaftar\nIsi: $shown'
            : 'QR Code tidak terdaftar',
      );
      return;
    }

    setState(() => _processing = true);
    _controller?.stop();

    final item = ClaimService.instance.addClaim(
      widget.user,
      outlet: merchant.name,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ClaimResultPage(user: widget.user, item: item),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _stage == _Stage.permission
        ? _buildPermission(context)
        : _buildScanner(context);
  }

  // -------------------------------------------------------------------
  // Scan QR #2 : izin kamera (TIDAK BERUBAH)
  // -------------------------------------------------------------------
  Widget _buildPermission(BuildContext context) {
    return PlainScaffold(
      glows: ScanGlows.permission,
      children: [
        ...buildSimpleHeader(context: context, title: 'Scan QR'),
        Positioned(
          left: 161,
          top: 261,
          width: 86,
          height: 73,
          child: CustomPaint(painter: _CameraIconPainter()),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 361,
          child: Center(
            child: Text(
              'Izin Kamera Diperlukan',
              style: inter(size: 18, weight: FontWeight.w600),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 389,
          child: Text(
            'Tuurn butuh akses kamera untuk memindai QR\n'
            'Code Merchant. Kamera hanya dipakai saat\n'
            'fitur scan dibuka',
            textAlign: TextAlign.center,
            style: inter(size: 13, height: 16 / 13),
          ),
        ),
        Positioned(
          left: 54,
          top: 617,
          width: 304,
          height: 54,
          child: RectButton(label: 'Izinkan Kamera', onPressed: _allowCamera),
        ),
        Positioned(
          left: 54,
          top: 693,
          width: 304,
          height: 54,
          child: RectButton(
            label: 'Buka Pengaturan',
            yellow: false,
            onPressed: _openSettings,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Scan QR #1 : kamera full screen  [LAYOUT DIRAPIKAN]
  // -------------------------------------------------------------------
  Widget _buildScanner(BuildContext context) {
    final controller = _controller!;
    final detected = _detectedRaw != null;
    final padding = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Kamera selebar layar
            MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
              onDetect: _onDetect,
            ),

            // 2. Pesan error kamera / izin ditolak
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, _) {
                final error = state.error;
                if (error == null) return const SizedBox.shrink();
                if (error.errorCode ==
                    MobileScannerErrorCode.permissionDenied) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _backToPermission(),
                  );
                  return const SizedBox.shrink();
                }
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Kamera tidak tersedia',
                    textAlign: TextAlign.center,
                    style: inter(size: 14, color: Colors.white),
                  ),
                );
              },
            ),

            // 3. Gradasi gelap atas & bawah supaya teks mudah dibaca
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 140,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x80000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 360,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Konten: header / bingkai / panel bawah (disusun Column,
            //    jadi tidak akan saling menimpa)
            Padding(
              padding: EdgeInsets.only(
                top: padding.top,
                bottom: padding.bottom,
              ),
              child: Column(
                children: [
                  // Header
                  SizedBox(
                    height: 56,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: const EdgeInsets.all(12),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Scan QR Merchant',
                            style: inter(size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bingkai: otomatis mengecil sesuai sisa ruang
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final side = math.max(
                          120.0,
                          math.min(
                            250.0,
                            math.min(c.maxWidth - 80, c.maxHeight - 24),
                          ),
                        );
                        return Center(
                          child: IgnorePointer(
                            child: SizedBox(
                              width: side,
                              height: side,
                              child: CustomPaint(
                                painter: _CornersPainter(
                                  color: detected
                                      ? AppColors.yellow
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Panel bawah
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Area teks: tinggi tetap supaya tombol tidak bergeser
                        SizedBox(
                          height: 52,
                          child: Center(
                            child: _notice != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xE6D32F2F),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _notice!,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: inter(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        detected ? 'QR Code terdeteksi' : 'Arahkan kamera ke QR Code di kasir',
                                        textAlign: TextAlign.center,
                                        style: inter(
                                          size: 14,
                                          weight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tekan tombol kuning untuk klaim poin',
                                        textAlign: TextAlign.center,
                                        style: inter(
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ShutterButton(onPressed: _onCapture),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 240,
                          height: 48,
                          child: RectButton(
                            label: 'Masukkan kode manual',
                            yellow: false,
                            fontSize: 16,
                            weight: FontWeight.w600,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ManualCodePage(user: widget.user),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol lingkaran kuning (gaya tombol rekam kamera).
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 78,
        height: 78,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.yellow,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Empat sudut bingkai scan (warna bisa diganti).
class _CornersPainter extends CustomPainter {
  const _CornersPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 36.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt;
    final w = size.width;
    final h = size.height;
    const o = 2.0; // setengah tebal garis agar rapat ke tepi

    // kiri-atas
    canvas.drawLine(const Offset(0, o), const Offset(len, o), p);
    canvas.drawLine(const Offset(o, 0), const Offset(o, len), p);
    // kanan-atas
    canvas.drawLine(Offset(w - len, o), Offset(w, o), p);
    canvas.drawLine(Offset(w - o, 0), Offset(w - o, len), p);
    // kiri-bawah
    canvas.drawLine(Offset(0, h - o), Offset(len, h - o), p);
    canvas.drawLine(Offset(o, h - len), Offset(o, h), p);
    // kanan-bawah
    canvas.drawLine(Offset(w - len, h - o), Offset(w, h - o), p);
    canvas.drawLine(Offset(w - o, h - len), Offset(w - o, h), p);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Ikon kamera kuning pada halaman izin. (TIDAK BERUBAH)
class _CameraIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 86;
    final sy = size.height / 73;
    canvas.scale(sx, sy);

    final yellow = Paint()..color = AppColors.yellow;

    // Tonjolan atas
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(22, 0, 42, 16),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      yellow,
    );
    // Badan
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 10, 86, 63),
        const Radius.circular(8),
      ),
      yellow,
    );
    // Lensa
    const c = Offset(43, 42);
    canvas.drawCircle(c, 17, Paint()..color = const Color(0xFFFFEAA6));
    canvas.drawCircle(c, 9.5, yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
