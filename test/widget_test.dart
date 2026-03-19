import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fixmycity_app/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://npjldteeehkkoegbzlgb.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wamxkdGVlZWhra29lZ2J6bGdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NTUwNDUsImV4cCI6MjA4NzEzMTA0NX0.0cuoj5bFndoz9wf9LCe80snRs2JrV8DcgkamfPCQGC0',
    );
  });

  testWidgets('Unauthenticated user is routed to sign in', (WidgetTester tester) async {
    await tester.pumpWidget(const FixMyCityApp());
    await tester.pumpAndSettle();

    expect(find.text('FixMyCity Login'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
