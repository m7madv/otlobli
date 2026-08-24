import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../state/app_scope.dart';

class MessageBanner extends StatelessWidget {
  const MessageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final error = controller.errorMessage;
    final notice = controller.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    final colors = context.colors;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    final background = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: foreground,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              error ?? notice!,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'إغلاق الرسالة',
            onPressed: controller.clearMessages,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
