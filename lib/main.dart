import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const defaultSupabaseUrl = 'https://npjldteeehkkoegbzlgb.supabase.co';
  const defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wamxkdGVlZWhra29lZ2J6bGdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NTUwNDUsImV4cCI6MjA4NzEzMTA0NX0.0cuoj5bFndoz9wf9LCe80snRs2JrV8DcgkamfPCQGC0';

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: defaultSupabaseUrl);
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: defaultSupabaseAnonKey,
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing Supabase config. Run with --dart-define=SUPABASE_URL=... '
      'and --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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