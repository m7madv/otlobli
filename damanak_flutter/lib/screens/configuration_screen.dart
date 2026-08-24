import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'نسخة المطوّر',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'النظام الكامل جاهز للربط.',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'يلزم مشروع Supabase مستقل ومفاتيح البناء لتفعيل الحسابات والمزامنة. يمكنك فتح العرض الآن لتجربة كل مسارات المتجر.',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: controller.busy
                                ? null
                                : controller.startDemo,
                            icon: controller.busy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: const Text('فتح العرض التشغيلي'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ConfigStep(
                    number: '1',
                    title: 'قاعدة مستقلة',
                    text:
                        'أنشئ مشروع Supabase جديداً خاصاً بضمانك؛ لا تستخدم قاعدة أي تطبيق آخر.',
                  ),
                  const _ConfigStep(
                    number: '2',
                    title: 'طبّق ملف قاعدة البيانات',
                    text:
                        'نفّذ migration الموجود داخل مجلد damanak_flutter/supabase.',
                  ),
                  const _ConfigStep(
                    number: '3',
                    title: 'ابنِ بالمفاتيح',
                    text:
                        'مرّر DAMANAK_SUPABASE_URL وDAMANAK_SUPABASE_PUBLISHABLE_KEY عند البناء.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigStep extends StatelessWidget {
  const _ConfigStep({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
