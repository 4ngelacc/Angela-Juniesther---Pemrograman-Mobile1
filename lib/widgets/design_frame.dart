import 'package:flutter/material.dart';

/// Lebar acuan desain (layar HP 412px).
const double kDesignWidth = 412;

/// Menskalakan seluruh isi halaman secara proporsional mengikuti lebar layar
/// HP, sehingga tampilan sama persis dengan desain di ukuran Android apa pun.
/// Isi otomatis bisa di-scroll bila layar kurang tinggi / keyboard muncul.
class DesignFrame extends StatelessWidget {
  const DesignFrame({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.centerVertically = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool centerVertically;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / kDesignWidth;
        final minHeight = centerVertically ? constraints.maxHeight / scale : 0.0;
        return SingleChildScrollView(
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: kDesignWidth,
              child: Container(
                constraints: BoxConstraints(minHeight: minHeight),
                alignment: centerVertically ? Alignment.center : Alignment.topCenter,
                padding: padding,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
