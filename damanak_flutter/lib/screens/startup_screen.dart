import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/brand_mark.dart';

class StartupScreen extends StatelessWidget {
  const StartupScreen({this.errorMessage, this.onRetry, super.key});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null;
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(onDark: true),
                const SizedBox(height: 28),
                if (hasError) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.ivory,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ivory,
                      foregroundColor: AppColors.accentPressed,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ] else
                  Semantics(
                    label: 'جاري تجهيز ضمانك',
                    child: const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.ivory,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
