import 'package:flutter/material.dart';
import '../app/theme.dart';

class StatTile extends StatelessWidget {
  final String title;
  final String value;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
  });

  Color _bgForTitle() {
    switch (title.toLowerCase()) {
      case 'submitted':
        return const Color(0xFFFFF3C7);
      case 'in progress':
        return const Color(0xFFD9ECFF);
      case 'resolved':
        return const Color(0xFFDFF7E8);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _bgForTitle(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
