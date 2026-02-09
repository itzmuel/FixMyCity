import 'package:flutter/material.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() {
  runApp(const FixMyCityApp());
}

class FixMyCityApp extends StatelessWidget {
  const FixMyCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FixMyCity',
      theme: buildTheme(),
      routerConfig: router, // ✅ ONLY routerConfig
    );
  }
}
