import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_theme.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aplikasi mobile Android: portrait + status bar transparan.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TuurnApp());
}

class TuurnApp extends StatelessWidget {
  const TuurnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuurn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
        scaffoldBackgroundColor: Colors.white,
      ),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Kalau layar sudah selebar HP, tampilkan apa adanya.
        if (mq.size.width <= 500) return child!;

        // Di layar lebar (browser desktop): latar hitam,
        // aplikasi dipasang di tengah dengan lebar HP (412px).
        const phoneWidth = 412.0;
        return ColoredBox(
          color: Colors.black,
          child: Center(
            child: SizedBox(
              width: phoneWidth,
              height: mq.size.height,
              child: ClipRect(
                child: MediaQuery(
                  // Supaya SafeArea & layout di dalam mengira layarnya selebar HP
                  data: mq.copyWith(size: Size(phoneWidth, mq.size.height)),
                  child: child!,
                ),
              ),
            ),
          ),
        );
      },
      home: const LoginPage(),
    );
  }
}
