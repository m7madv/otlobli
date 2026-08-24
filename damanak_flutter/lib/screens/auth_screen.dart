import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _createAccount = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    if (_createAccount) {
      await controller.signUp(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
      );
    } else {
      await controller.signIn(email: _email.text, password: _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 780;
                  final form = _AuthForm(
                    formKey: _formKey,
                    createAccount: _createAccount,
                    hidePassword: _hidePassword,
                    name: _name,
                    email: _email,
                    password: _password,
                    busy: controller.busy,
                    onToggleMode: () {
                      controller.clearMessages();
                      setState(() => _createAccount = !_createAccount);
                    },
                    onTogglePassword: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    onSubmit: _submit,
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandMark(),
                        const SizedBox(height: 28),
                        form,
                        const SizedBox(height: 22),
                        const _TrustStrip(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: _AuthStory()),
                      const SizedBox(width: 34),
                      Expanded(child: form),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.createAccount,
    required this.hidePassword,
    required this.name,
    required this.email,
    required this.password,
    required this.busy,
    required this.onToggleMode,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool createAccount;
  final bool hidePassword;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final VoidCallback onToggleMode;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 380 ? 18 : 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              createAccount ? 'أنشئ حساب صاحب المتجر' : 'مرحباً بعودتك',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              createAccount
                  ? 'ابدأ تجربة 14 يوماً، ثم أضف موظفيك بحسابات مستقلة.'
                  : 'ادخل إلى المتجر والصلاحيات المرتبطة بحسابك.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            const MessageBanner(),
            if (createAccount) ...[
              TextFormField(
                controller: name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'أدخل اسماً واضحاً'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                final emailValue = value?.trim() ?? '';
                if (!emailValue.contains('@') || !emailValue.contains('.')) {
                  return 'أدخل بريداً إلكترونياً صحيحاً';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: password,
              obscureText: hidePassword,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              autofillHints: [
                createAccount
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                helperText: createAccount ? '8 أحرف على الأقل' : null,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: hidePassword
                      ? 'إظهار كلمة المرور'
                      : 'إخفاء كلمة المرور',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value?.length ?? 0) < 8
                  ? 'كلمة المرور يجب ألا تقل عن 8 أحرف'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onSubmit,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        createAccount
                            ? Icons.arrow_back_rounded
                            : Icons.login_rounded,
                      ),
                label: Text(
                  busy
                      ? 'جارٍ التحقق…'
                      : createAccount
                      ? 'إنشاء الحساب والمتابعة'
                      : 'تسجيل الدخول',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: busy ? null : onToggleMode,
                child: Text(
                  createAccount
                      ? 'لديك حساب؟ سجّل الدخول'
                      : 'متجر جديد؟ أنشئ حساباً',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthStory extends StatelessWidget {
  const _AuthStory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMark(onDark: true),
          Spacer(),
          Text(
            'كل ضمان يبدأ\nمن مسحة واحدة.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'كتالوج منتجات، باركود داخل التطبيق، فريق بصلاحيات، وسجل لا يضيع بين أجهزة الموظفين.',
            style: TextStyle(color: Color(0xFFBDD0CD), height: 1.65),
          ),
          SizedBox(height: 28),
          _TrustStrip(onDark: true),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = onDark
        ? Colors.white.withValues(alpha: 0.82)
        : colors.onSurface;
    final iconColor = onDark ? AppColors.accentDark : colors.primary;
    return Wrap(
      spacing: 14,
      runSpacing: 9,
      children: [
        _TrustItem(
          icon: Icons.badge_outlined,
          text: 'حساب لكل موظف',
          color: color,
          iconColor: iconColor,
        ),
        _TrustItem(
          icon: Icons.shield_outlined,
          text: 'صلاحيات آمنة',
          color: color,
          iconColor: iconColor,
        ),
        _TrustItem(
          icon: Icons.sync_rounded,
          text: 'مزامنة فورية',
          color: color,
          iconColor: iconColor,
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.text,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
