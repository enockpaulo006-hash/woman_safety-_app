import 'package:flutter/material.dart';

import '../../../core/settings/app_settings_scope.dart';
import '../../../core/theme/app_palette.dart';
import '../../auth/data/models/auth_session.dart';
import '../../auth/data/services/auth_api_service.dart';
import '../../auth/data/services/google_auth_service.dart';
import 'auth_shared_widgets.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    required this.onAuthenticated,
    super.key,
  });

  final Future<void> Function(AuthSession) onAuthenticated;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = AuthApiService();
  final _googleAuth = GoogleAuthService();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _activeAction;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = AppSettingsScope.readStringsOf(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _activeAction = 'email';
    });

    try {
      final session = await _api.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _activeAction = null;
      });
      widget.onAuthenticated(session);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _activeAction = null;
      });

      final message = AuthApiService.isConnectivityError(error)
          ? strings.text('authConnectionFailed')
          : error.toString();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _continueWithGoogle() async {
    final strings = AppSettingsScope.readStringsOf(context);
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _activeAction = 'google';
    });

    try {
      final result = await _googleAuth.authenticate();
      final session = await _api.signInWithGoogle(idToken: result.idToken);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _activeAction = null;
      });
      widget.onAuthenticated(session);
    } on GoogleAuthCancelledException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _activeAction = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.text('googleSignInCanceled'))),
      );
    } on GoogleAuthNotConfiguredException {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _activeAction = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.text('googleSignInNotConfigured'))),
      );
    } on GoogleAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _activeAction = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message.trim().isEmpty
                ? strings.text('googleSignInFailed')
                : error.message,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _activeAction = null;
      });

      final message = AuthApiService.isConnectivityError(error)
          ? strings.text('authConnectionFailed')
          : error.toString();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strings = AppSettingsScope.stringsOf(context);
    final visuals = context.appVisuals;

    return Scaffold(
      backgroundColor: visuals.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  strings.text('signInTitle'),
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  strings.text('signInSubtitle'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFCE7F0),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _SignInField(
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
                      _SignInField(
                        controller: _passwordController,
                        label: strings.text('password'),
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
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
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _activeAction == 'email'
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(strings.text('signIn')),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AuthDivider(label: strings.text('orContinueWith')),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _continueWithGoogle,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: _activeAction == 'google'
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const GoogleBadge(),
                          label: Text(strings.text('continueWithGoogle')),
                        ),
                      ),
                    ],
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

class _SignInField extends StatelessWidget {
  const _SignInField({
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
