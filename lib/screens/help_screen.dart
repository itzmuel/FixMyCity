import 'package:flutter/material.dart';
import '../widgets/help_row.dart';
import '../widgets/section_title.dart';
import '../app/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Safety')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.danger.withValues(alpha: 0.1 ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: AppColors.danger, size: 36),
                  const SizedBox(height: 10),
                  const Text(
                    'Emergency?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'If this is a life-threatening emergency or poses immediate danger, please call 911 immediately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('In production, this would open the phone dialer.'),
                          ),
                        );
                      },
                      child: const Text('Call 911'),
                    ),
                  ),
                ],
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
                  HelpRow(icon: Icons.warning_amber, text: 'Potholes and road damage'),
                  HelpRow(icon: Icons.lightbulb_outline, text: 'Broken streetlights'),
                  HelpRow(icon: Icons.brush, text: 'Graffiti and vandalism'),
                  HelpRow(icon: Icons.directions_walk, text: 'Damaged sidewalks'),
                  HelpRow(icon: Icons.delete_outline, text: 'Illegal dumping'),
                  HelpRow(icon: Icons.park, text: 'Overgrown vegetation'),
                  HelpRow(icon: Icons.water_drop_outlined, text: 'Drainage issues'),
                  HelpRow(icon: Icons.build_outlined, text: 'Damaged public property'),
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
                  HelpRow(icon: Icons.emergency, text: 'Emergencies (call 911)'),
                  HelpRow(icon: Icons.local_police_outlined, text: 'Criminal activity'),
                  HelpRow(icon: Icons.medical_services_outlined, text: 'Medical emergencies'),
                  HelpRow(icon: Icons.person_off_outlined, text: 'Personal disputes'),
                  HelpRow(icon: Icons.home_work_outlined, text: 'private property issues'),
                  HelpRow(icon: Icons.build_outlined, text: 'utility company issues'),
                ],
              ),
            ),
          ),
          
        ],
      ),
    );
  }
}
