import 'package:flutter/material.dart';
import '../app/theme.dart';

class StepDots extends StatelessWidget {
  final int current; // 1..total
  final int total;

  const StepDots({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final idx = i + 1;
        final active = idx <= current;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$idx',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              if (idx != total)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
