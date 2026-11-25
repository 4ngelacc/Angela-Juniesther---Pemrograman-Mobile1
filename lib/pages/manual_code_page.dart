import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/claim_service.dart';
import '../services/merchant_service.dart';
import '../widgets/plain_scaffold.dart';
import 'claim_result_page.dart';

/// Kode Manual: isi kode merchant yang tertera di bawah QR Code kasir,
/// lalu "Klaim Poin" -> langsung ke Hasil Klaim.
class ManualCodePage extends StatefulWidget {
  const ManualCodePage({super.key, required this.user});

  final AppUser user;

  @override
  State<ManualCodePage> createState() => _ManualCodePageState();
}

class _ManualCodePageState extends State<ManualCodePage> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _claim() {
    FocusScope.of(context).unfocus();
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Kode merchant wajib diisi');
      return;
    }
    final merchant = MerchantService.lookup(code);
    if (merchant == null) {
      setState(() => _error = 'Kode merchant tidak ditemukan');
      return;
    }
    final item =
        ClaimService.instance.addClaim(widget.user, outlet: merchant.name);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ClaimResultPage(user: widget.user, item: item),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    return PlainScaffold(
      glows: ScanGlows.manual,
      children: [
        ...buildSimpleHeader(context: context, title: 'Kode Manual'),
        Positioned(
          left: 33,
          top: 121,
          child: Text(
            'QR tidak bisa dipindai? Masukkan kode yang\n'
            'tertera dibawah QR Code kasir.',
            style: inter(size: 14, height: 17 / 14),
          ),
        ),
        Positioned(
          left: 33,
          top: 202,
          child: Text('Kode Merchant',
              style: inter(size: 16, weight: FontWeight.w700)),
        ),
        Positioned(
          left: 33,
          top: 227,
          width: 346,
          height: 40,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError ? AppColors.error : const Color(0xFFB7CBB8),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _claim(),
              style: inter(size: 14),
              cursorColor: AppColors.dark,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'KS-2047-AB',
                hintStyle: inter(size: 14, color: const Color(0xFFA7B2A8)),
              ),
            ),
          ),
        ),
        if (hasError)
          Positioned(
            left: 36,
            top: 272,
            child: Text(_error!, style: inter(size: 12, color: AppColors.error)),
          ),
        Positioned(
          left: 54,
          top: 396,
          width: 304,
          height: 55,
          child: RectButton(
            label: 'Klaim Poin',
            fontSize: 18,
            onPressed: _claim,
          ),
        ),
      ],
    );
  }
}
