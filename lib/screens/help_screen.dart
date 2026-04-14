import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/help_row.dart';
import '../widgets/section_title.dart';
import '../app/theme.dart';
import '../services/auth_service.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _sourceMunicipal =
      'https://www.kitchener.ca/en/living-in-kitchener/report-a-problem.aspx';
  static const String _sourceOntario =
      'https://www.ontario.ca/page/municipalities';

  Future<void> _openSource(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open source link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Safety'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.muted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Non-Government Disclaimer',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'FixMyCity does not represent a government entity. Information and response timelines may change. Always verify details with official government sources.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openSource(context, _sourceMunicipal),
                        icon: const Icon(Icons.link),
                        label: const Text('Municipal Source'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openSource(context, _sourceOntario),
                        icon: const Icon(Icons.link),
                        label: const Text('Ontario Source'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Emergency Card (white card + soft-red panel inside)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10), // ~10% tint
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.235),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.157),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: AppColors.danger,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'If this is a life-threatening emergency or poses immediate danger, please call 911 immediately.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: '911');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('Call 911'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          const SectionTitle(
            icon: Icons.report_problem,
            title: 'What to Report',
            iconColor: Colors.green,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: const [
                  HelpRow(
                    icon: Icons.warning_amber,
                    text: 'Potholes and road damage',
                  ),
                  HelpRow(
                    icon: Icons.lightbulb_outline,
                    text: 'Broken streetlights',
                  ),
                  HelpRow(icon: Icons.brush, text: 'Graffiti and vandalism'),
                  HelpRow(
                    icon: Icons.directions_walk,
                    text: 'Damaged sidewalks',
                  ),
                  HelpRow(icon: Icons.delete_outline, text: 'Illegal dumping'),
                  HelpRow(icon: Icons.park, text: 'Overgrown vegetation'),
                  HelpRow(
                    icon: Icons.water_drop_outlined,
                    text: 'Drainage issues',
                  ),
                  HelpRow(
                    icon: Icons.build_outlined,
                    text: 'Damaged public property',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const SectionTitle(
            icon: Icons.cancel,
            title: 'What NOT to Report',
            iconColor: Colors.red,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: const [
                  HelpRow(
                    icon: Icons.emergency,
                    text: 'Emergencies (call 911)',
                  ),
                  HelpRow(
                    icon: Icons.local_police_outlined,
                    text: 'Criminal activity',
                  ),
                  HelpRow(
                    icon: Icons.medical_services_outlined,
                    text: 'Medical emergencies',
                  ),
                  HelpRow(
                    icon: Icons.person_off_outlined,
                    text: 'Personal disputes',
                  ),
                  HelpRow(
                    icon: Icons.home_work_outlined,
                    text: 'Private property issues',
                  ),
                  HelpRow(
                    icon: Icons.build_outlined,
                    text: 'Utility company issues',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
