import 'package:flutter/material.dart';

import '../../../core/settings/app_settings_scope.dart';
import '../../../core/theme/app_palette.dart';
import '../../reporting/presentation/report_home_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final strings = AppSettingsScope.readStringsOf(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.text('registrationReady', {
            'name': _fullNameController.text.trim(),
          }),
        ),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ReportHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return Scaffold(
      backgroundColor: visuals.primary,
      body: SafeArea(
        child: Column(
          children: [
            const _RegistrationHero(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.text('registrationTitle'),
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        /*Text(
                          'Registration happens once. After this, the app takes the user straight into reporting.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFFBE2EC),
                            height: 1.45,
                          ),
                        ),*/
                        const SizedBox(height: 24),
                        _RegistrationField(
                          controller: _fullNameController,
                          label: strings.text('fullName'),
                          icon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return strings.text('fullNameRequired');
                            }
                            if (value.trim().length < 3) {
                              return strings.text('fullNameShort');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          controller: _emailController,
                          label: strings.text('email'),
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return strings.text('emailRequired');
                            }
                            final emailPattern = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );
                            if (!emailPattern.hasMatch(email)) {
                              return strings.text('emailInvalid');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          controller: _passwordController,
                          label: strings.text('password'),
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return strings.text('passwordRequired');
                            }
                            if (password.length < 6) {
                              return strings.text('passwordShort');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _RegistrationField(
                          controller: _confirmPasswordController,
                          label: strings.text('confirmPassword'),
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          validator: (value) {
                            final confirmPassword = value ?? '';
                            if (confirmPassword.isEmpty) {
                              return strings.text('confirmPasswordRequired');
                            }
                            if (confirmPassword != _passwordController.text) {
                              return strings.text('passwordMismatch');
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submit,
                            child: Text(strings.text('signUp')),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                         /* child: Text(
                          'No login screen. This is a first registration flow only.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFFDE5EE),
                              fontWeight: FontWeight.w600,
                            ),
                          ),*/
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationHero extends StatelessWidget {
  const _RegistrationHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(38),
        bottomRight: Radius.circular(38),
      ),
      child: Container(
        height: 220,
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              top: 42,
              left: 20,
              child: Transform.rotate(
                angle: -0.24,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppPalette.softShell,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 54,
              left: 28,
              child: _SmallProfileArtwork(),
            ),
            const Positioned(
              top: 14,
              right: 38,
              child: _PhoneArtwork(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 20,
                decoration: const BoxDecoration(
                  color: AppPalette.primaryRose,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallProfileArtwork extends StatelessWidget {
  const _SmallProfileArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 100,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 10,
            child: _LeafBranch(),
          ),
          Positioned(
            right: 18,
            top: 18,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF23263C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppPalette.accentCoral,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 34,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF23263C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeafBranch extends StatelessWidget {
  const _LeafBranch();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 78,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 8,
            child: Container(
              width: 2,
              height: 58,
              color: AppPalette.mutedRose,
            ),
          ),
          const Positioned(left: 0, top: 10, child: _Leaf()),
          const Positioned(left: 14, top: 0, child: _Leaf(mirrored: true)),
          const Positioned(left: 6, top: 28, child: _Leaf()),
          const Positioned(left: 18, top: 40, child: _Leaf(mirrored: true)),
        ],
      ),
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf({this.mirrored = false});

  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final leaf = Container(
      width: 14,
      height: 22,
      decoration: BoxDecoration(
        color: AppPalette.blush,
        borderRadius: BorderRadius.circular(999),
      ),
    );

    return Transform.rotate(
      angle: mirrored ? 0.8 : -0.8,
      child: leaf,
    );
  }
}

class _PhoneArtwork extends StatelessWidget {
  const _PhoneArtwork();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 176,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1F4),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF44405B), width: 2),
            ),
          ),
          Positioned(
            top: 6,
            left: 34,
            right: 34,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF44405B),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 34,
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    color: AppPalette.blush.withValues(alpha: 0.88),
                    size: 34,
                  ),
                  Icon(
                    Icons.person_rounded,
                    color: const Color(0xFFE4E4E4),
                    size: 48,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: SizedBox(
              width: 64,
              height: 108,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 18,
                    top: 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2B41),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 26,
                    child: Container(
                      width: 34,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppPalette.blush,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 48,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2B41),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 38,
                    child: Transform.rotate(
                      angle: -0.44,
                      child: Container(
                        width: 10,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppPalette.blush,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 26,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2B41),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D2B41),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ),
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

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
