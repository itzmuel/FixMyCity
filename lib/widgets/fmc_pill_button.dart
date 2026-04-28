import 'package:flutter/material.dart';
import '../app/theme.dart';

class FmcPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool primary;

  const FmcPillButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: child,
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: child,
    );
  }
}
