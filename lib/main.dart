import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://npjldteeehkkoegbzlgb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wamxkdGVlZWhra29lZ2J6bGdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NTUwNDUsImV4cCI6MjA4NzEzMTA0NX0.0cuoj5bFndoz9wf9LCe80snRs2JrV8DcgkamfPCQGC0',
  );

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
      routerConfig: router,
    );
  }
}